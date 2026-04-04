# HomeIQ — Infrastructure & Deployment Guide

> **Cloud**: AWS (primary)  
> **Container Runtime**: Docker → ECS Fargate → EKS (at scale)  
> **CI/CD**: GitHub Actions  
> **IaC**: Terraform  

---

## 1. Environment Strategy

| Environment | Purpose | URL | Database |
|------------|---------|-----|----------|
| **Development** | Local development | `http://localhost:3000` | Local PostgreSQL (Docker) |
| **Staging** | QA & integration testing | `https://api-staging.homeiq.com` | RDS (t3.medium) |
| **Production** | Live users | `https://api.homeiq.com` | RDS (r6g.xlarge+) |

---

## 2. Phase 1 — Startup (0 – 100K Users)

### AWS Architecture Diagram
```
                    ┌─────────────┐
                    │  CloudFront  │
                    │    (CDN)     │
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │     ALB      │
                    │ (App Load    │
                    │  Balancer)   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────┴─────┐ ┌───┴───┐ ┌─────┴─────┐
        │ ECS Task 1│ │Task 2 │ │ Task 3    │
        │ (Fargate) │ │       │ │ (Worker)  │
        │ API       │ │ API   │ │ BullMQ    │
        └─────┬─────┘ └───┬───┘ └─────┬─────┘
              │            │            │
              └────────────┼────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────┴─────┐ ┌───┴───┐ ┌─────┴─────┐
        │ RDS       │ │ Redis │ │ S3        │
        │ PostgreSQL│ │ Elast.│ │ (Files)   │
        │ (t3.large)│ │ Cache │ │           │
        └───────────┘ └───────┘ └───────────┘
```

### Terraform — Main Infrastructure
```hcl
# main.tf — Phase 1 Infrastructure

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "homeiq-terraform-state"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "homeiq-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true   # Phase 1 cost optimization
  enable_dns_hostnames   = true
}

# RDS PostgreSQL
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier     = "homeiq-${var.environment}"
  engine         = "postgres"
  engine_version = "16.4"
  family         = "postgres16"

  instance_class    = var.environment == "production" ? "db.t3.large" : "db.t3.medium"
  allocated_storage = 100
  max_allocated_storage = 500  # Auto-scaling

  db_name  = "homeiq"
  username = "homeiq_admin"
  port     = 5432

  multi_az               = var.environment == "production"
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.security_groups.rds_sg_id]

  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"

  performance_insights_enabled = true
  monitoring_interval          = 60

  parameters = [
    { name = "shared_preload_libraries", value = "pg_stat_statements" },
    { name = "log_min_duration_statement", value = "1000" }
  ]
}

# ElastiCache Redis
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "homeiq-${var.environment}"
  description          = "HomeIQ Redis cluster"

  engine               = "redis"
  engine_version       = "7.0"
  node_type            = var.environment == "production" ? "cache.t3.medium" : "cache.t3.small"
  num_cache_clusters   = var.environment == "production" ? 2 : 1

  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [module.security_groups.redis_sg_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  snapshot_retention_limit = 3
  snapshot_window          = "05:00-06:00"
}

# S3 — File Storage
resource "aws_s3_bucket" "uploads" {
  bucket = "homeiq-uploads-${var.environment}"
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["https://app.homeiq.com", "https://homeiq.com"]
    max_age_seconds = 3600
  }
}

# CloudFront CDN
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.uploads.bucket_regional_domain_name
    origin_id   = "s3-uploads"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.uploads.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"
  aliases             = ["cdn.homeiq.com"]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-uploads"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  viewer_certificate {
    acm_certificate_arn = var.cdn_certificate_arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }
}
```

### ECS Fargate — API Service
```hcl
# ecs.tf

resource "aws_ecs_cluster" "main" {
  name = "homeiq-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "homeiq-api-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024    # 1 vCPU
  memory                   = 2048    # 2 GB

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        { containerPort = 3000, hostPort = 3000, protocol = "tcp" }
      ]

      environment = [
        { name = "NODE_ENV",    value = var.environment },
        { name = "PORT",        value = "3000" },
        { name = "LOG_LEVEL",   value = var.environment == "production" ? "info" : "debug" }
      ]

      secrets = [
        { name = "DATABASE_URL",       valueFrom = "${aws_secretsmanager_secret.db_url.arn}" },
        { name = "REDIS_URL",          valueFrom = "${aws_secretsmanager_secret.redis_url.arn}" },
        { name = "JWT_SECRET",         valueFrom = "${aws_secretsmanager_secret.jwt_secret.arn}" },
        { name = "STRIPE_SECRET_KEY",  valueFrom = "${aws_secretsmanager_secret.stripe_key.arn}" },
        { name = "OPENAI_API_KEY",     valueFrom = "${aws_secretsmanager_secret.openai_key.arn}" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/homeiq-api-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "homeiq-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.environment == "production" ? 3 : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.security_groups.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}

# Auto Scaling
resource "aws_appautoscaling_target" "api" {
  max_capacity       = var.environment == "production" ? 20 : 2
  min_capacity       = var.environment == "production" ? 3 : 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
```

### ECS — Worker Service (BullMQ)
```hcl
resource "aws_ecs_task_definition" "worker" {
  family                   = "homeiq-worker-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024

  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      command   = ["node", "dist/worker.js"]

      environment = [
        { name = "NODE_ENV",      value = var.environment },
        { name = "WORKER_MODE",   value = "true" },
        { name = "CONCURRENCY",   value = "5" }
      ]

      secrets = [
        { name = "DATABASE_URL",      valueFrom = "${aws_secretsmanager_secret.db_url.arn}" },
        { name = "REDIS_URL",         valueFrom = "${aws_secretsmanager_secret.redis_url.arn}" },
        { name = "OPENAI_API_KEY",    valueFrom = "${aws_secretsmanager_secret.openai_key.arn}" },
        { name = "SES_FROM_EMAIL",    valueFrom = "${aws_secretsmanager_secret.ses_email.arn}" },
        { name = "FCM_SERVICE_ACCOUNT", valueFrom = "${aws_secretsmanager_secret.fcm_key.arn}" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/homeiq-worker-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "worker"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "worker" {
  name            = "homeiq-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.environment == "production" ? 2 : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.security_groups.worker_sg_id]
    assign_public_ip = false
  }
}
```

---

## 3. Docker Configuration

### Dockerfile (API + Worker)
```dockerfile
# ─── Build Stage ───
FROM node:20-alpine AS builder

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY tsconfig.json ./
COPY prisma ./prisma/
RUN npx prisma generate
COPY src ./src/
RUN npm run build

# ─── Production Stage ───
FROM node:20-alpine AS production

RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY package.json ./

ENV NODE_ENV=production
USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

### Docker Compose (Local Development)
```yaml
# docker-compose.yml

version: "3.9"
services:

  # ─── PostgreSQL ───
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: homeiq_dev
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: homeiq
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./ARCHITECTURE/01_DATABASE_SCHEMA.sql:/docker-entrypoint-initdb.d/schema.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U homeiq_dev"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ─── Redis ───
  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ─── API Server ───
  api:
    build:
      context: .
      dockerfile: Dockerfile
      target: builder          # Use builder stage for hot reload
    command: npm run dev
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: development
      PORT: 3000
      DATABASE_URL: postgresql://homeiq_dev:dev_password@postgres:5432/homeiq
      REDIS_URL: redis://redis:6379
      JWT_SECRET: dev-jwt-secret-change-in-prod
      JWT_REFRESH_SECRET: dev-refresh-secret
      STRIPE_SECRET_KEY: ${STRIPE_SECRET_KEY}
      STRIPE_WEBHOOK_SECRET: ${STRIPE_WEBHOOK_SECRET}
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
      AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
      S3_BUCKET: homeiq-uploads-dev
      SES_FROM_EMAIL: noreply@homeiq.com
    volumes:
      - ./src:/app/src
      - ./prisma:/app/prisma
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  # ─── Background Worker ───
  worker:
    build:
      context: .
      dockerfile: Dockerfile
      target: builder
    command: npm run dev:worker
    environment:
      NODE_ENV: development
      WORKER_MODE: "true"
      CONCURRENCY: "3"
      DATABASE_URL: postgresql://homeiq_dev:dev_password@postgres:5432/homeiq
      REDIS_URL: redis://redis:6379
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      SES_FROM_EMAIL: noreply@homeiq.com
    volumes:
      - ./src:/app/src
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  # ─── Redis Commander (Dev UI) ───
  redis-commander:
    image: rediscommander/redis-commander:latest
    environment:
      REDIS_HOSTS: local:redis:6379
    ports:
      - "8081:8081"
    depends_on:
      - redis
    profiles:
      - tools

  # ─── pgAdmin (Dev UI) ───
  pgadmin:
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: dev@homeiq.com
      PGADMIN_DEFAULT_PASSWORD: dev_password
    ports:
      - "8082:80"
    depends_on:
      - postgres
    profiles:
      - tools

volumes:
  pgdata:
  redisdata:
```

---

## 4. CI/CD Pipeline (GitHub Actions)

### Main Pipeline
```yaml
# .github/workflows/deploy.yml

name: Build & Deploy

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: homeiq-api

jobs:

  # ─── Lint & Type Check ───
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  # ─── Unit Tests ───
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: homeiq_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/homeiq_test
      - run: npm run test:coverage
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/homeiq_test
          REDIS_URL: redis://localhost:6379
          JWT_SECRET: test-secret
      - uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  # ─── Integration Tests ───
  integration:
    runs-on: ubuntu-latest
    needs: [lint, test]
    if: github.event_name == 'push'
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: homeiq_test
        ports:
          - 5432:5432
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/homeiq_test
      - run: npm run test:integration
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/homeiq_test
          REDIS_URL: redis://localhost:6379

  # ─── Build & Push Docker Image ───
  build:
    runs-on: ubuntu-latest
    needs: [integration]
    permissions:
      id-token: write
      contents: read
    outputs:
      image_tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - uses: aws-actions/amazon-ecr-login@v2
        id: login-ecr

      - name: Build & push
        id: meta
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "tags=$REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

  # ─── Deploy to Staging ───
  deploy-staging:
    runs-on: ubuntu-latest
    needs: [build]
    if: github.ref == 'refs/heads/staging'
    environment: staging
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Deploy to ECS (staging)
        run: |
          aws ecs update-service \
            --cluster homeiq-staging \
            --service homeiq-api \
            --force-new-deployment \
            --task-definition homeiq-api-staging

  # ─── Deploy to Production ───
  deploy-production:
    runs-on: ubuntu-latest
    needs: [build]
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Run migrations
        run: |
          aws ecs run-task \
            --cluster homeiq-production \
            --task-definition homeiq-migrate-production \
            --launch-type FARGATE \
            --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNETS],securityGroups=[$SG_ID]}"

      - name: Deploy to ECS (production)
        run: |
          aws ecs update-service \
            --cluster homeiq-production \
            --service homeiq-api \
            --force-new-deployment

      - name: Deploy worker
        run: |
          aws ecs update-service \
            --cluster homeiq-production \
            --service homeiq-worker \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster homeiq-production \
            --services homeiq-api homeiq-worker
```

### Database Migration Pipeline
```yaml
# .github/workflows/migrate.yml

name: Database Migration

on:
  workflow_dispatch:
    inputs:
      environment:
        required: true
        type: choice
        options: [staging, production]

jobs:
  migrate:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci

      - name: Run Prisma migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}

      - name: Verify migration
        run: npx prisma migrate status
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

---

## 5. Monitoring & Observability

### CloudWatch Alarms
```hcl
# monitoring.tf

# API Error Rate > 5%
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "homeiq-api-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 5

  metric_query {
    id          = "error_rate"
    expression  = "(errors / total) * 100"
    label       = "Error Rate %"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions  = { TargetGroup = aws_lb_target_group.api.arn_suffix }
    }
  }

  metric_query {
    id = "total"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions  = { TargetGroup = aws_lb_target_group.api.arn_suffix }
    }
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# API Latency p99 > 2s
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "homeiq-api-latency-p99"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "p99"
  threshold           = 2.0
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Database CPU > 80%
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "homeiq-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions          = { DBInstanceIdentifier = module.rds.db_instance_identifier }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Database Connections > 80%
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "homeiq-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 350                    # 80% of max for t3.large
  dimensions          = { DBInstanceIdentifier = module.rds.db_instance_identifier }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Redis Memory > 80%
resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "homeiq-redis-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Queue depth (BullMQ waiting jobs)
resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name          = "homeiq-queue-backlog"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "QueueWaitingJobs"
  namespace           = "HomeIQ/Worker"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# SNS Alert Topic
resource "aws_sns_topic" "alerts" {
  name = "homeiq-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "oncall@homeiq.com"
}

resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}
```

### Application-Level Logging
```typescript
// src/config/logger.ts

import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  serializers: {
    req: (req) => ({
      method: req.method,
      url: req.url,
      headers: {
        'x-request-id': req.headers['x-request-id'],
        'x-platform': req.headers['x-platform'],
      },
    }),
    res: (res) => ({
      statusCode: res.statusCode,
    }),
    err: pino.stdSerializers.err,
  },
  redact: {
    paths: ['req.headers.authorization', '*.password', '*.token', '*.secret'],
    censor: '[REDACTED]',
  },
});
```

### Health Check Endpoint
```typescript
// src/routes/health.ts

export async function healthRoutes(app: FastifyInstance) {
  // Simple liveness probe
  app.get('/health', async () => ({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  }));

  // Deep readiness probe (checks all dependencies)
  app.get('/health/ready', async () => {
    const checks = await Promise.allSettled([
      app.prisma.$queryRaw`SELECT 1`,                    // PostgreSQL
      app.redis.ping(),                                    // Redis
    ]);

    const results = {
      postgres: checks[0].status === 'fulfilled' ? 'ok' : 'fail',
      redis:    checks[1].status === 'fulfilled' ? 'ok' : 'fail',
    };

    const allOk = Object.values(results).every((v) => v === 'ok');

    return {
      status: allOk ? 'ok' : 'degraded',
      checks: results,
      timestamp: new Date().toISOString(),
    };
  });
}
```

---

## 6. Security Configuration

### Security Groups
```hcl
# security.tf

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id = module.vpc.vpc_id

  # ALB: Allow 80, 443 from anywhere
  alb_ingress_rules = [
    { from_port = 80,  to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
  ]

  # ECS: Allow 3000 from ALB only
  ecs_ingress_rules = [
    { from_port = 3000, to_port = 3000, protocol = "tcp", source_security_group_id = "alb_sg" },
  ]

  # RDS: Allow 5432 from ECS + Worker only
  rds_ingress_rules = [
    { from_port = 5432, to_port = 5432, protocol = "tcp", source_security_group_id = "ecs_sg" },
    { from_port = 5432, to_port = 5432, protocol = "tcp", source_security_group_id = "worker_sg" },
  ]

  # Redis: Allow 6379 from ECS + Worker only
  redis_ingress_rules = [
    { from_port = 6379, to_port = 6379, protocol = "tcp", source_security_group_id = "ecs_sg" },
    { from_port = 6379, to_port = 6379, protocol = "tcp", source_security_group_id = "worker_sg" },
  ]
}
```

### WAF Rules
```hcl
# waf.tf

resource "aws_wafv2_web_acl" "api" {
  name        = "homeiq-api-waf"
  scope       = "REGIONAL"

  default_action { allow {} }

  # Rate limiting
  rule {
    name     = "rate-limit"
    priority = 1
    action   { block {} }
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
    }
  }

  # AWS Managed Rules — Common
  rule {
    name     = "aws-common"
    priority = 2
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommon"
    }
  }

  # AWS Managed Rules — SQL injection
  rule {
    name     = "aws-sqli"
    priority = 3
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSSQLi"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "homeiq-api-waf"
  }
}
```

### Secrets Management
```hcl
# secrets.tf

locals {
  secrets = [
    "database-url",
    "redis-url",
    "jwt-secret",
    "jwt-refresh-secret",
    "stripe-secret-key",
    "stripe-webhook-secret",
    "openai-api-key",
    "ses-from-email",
    "fcm-service-account",
    "apple-client-secret",
    "google-client-id",
  ]
}

resource "aws_secretsmanager_secret" "app" {
  for_each = toset(local.secrets)

  name                    = "homeiq/${var.environment}/${each.key}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0
}
```

---

## 7. Phase 2 Upgrades (100K – 5M Users)

### Key Changes
1. **RDS**: Upgrade to `r6g.xlarge` with read replicas
2. **Redis**: Cluster mode enabled, `r6g.large`
3. **NAT Gateway**: Multi-AZ (one per AZ)
4. **ECS**: Scale to 10-50 tasks
5. **Database**: Connection pooling via PgBouncer

### Read Replica Configuration
```hcl
resource "aws_db_instance" "read_replica" {
  count               = 2
  identifier          = "homeiq-read-${count.index + 1}"
  replicate_source_db = module.rds.db_instance_identifier
  instance_class      = "db.r6g.large"

  vpc_security_group_ids = [module.security_groups.rds_sg_id]
  publicly_accessible    = false

  performance_insights_enabled = true
}
```

### PgBouncer Sidecar
```hcl
# Add PgBouncer as a sidecar container in the ECS task definition
{
  name      = "pgbouncer"
  image     = "edoburu/pgbouncer:latest"
  essential = true
  portMappings = [
    { containerPort = 6432, hostPort = 6432, protocol = "tcp" }
  ]
  environment = [
    { name = "DATABASE_URL",   value = "postgresql://..." },
    { name = "POOL_MODE",      value = "transaction" },
    { name = "DEFAULT_POOL_SIZE", value = "50" },
    { name = "MAX_CLIENT_CONN",   value = "200" }
  ]
}
```

---

## 8. Phase 3 Upgrades (5M – 50M Users)

### Migrate to EKS (Kubernetes)
```yaml
# k8s/api-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: homeiq-api
  namespace: homeiq
spec:
  replicas: 10
  selector:
    matchLabels:
      app: homeiq-api
  template:
    metadata:
      labels:
        app: homeiq-api
    spec:
      containers:
        - name: api
          image: ECR_REGISTRY/homeiq-api:TAG
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1000m"
              memory: "1Gi"
          envFrom:
            - secretRef:
                name: homeiq-secrets
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: homeiq-api
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: homeiq-api
  namespace: homeiq
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: homeiq-api
  minReplicas: 10
  maxReplicas: 100
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

---

## 9. Phase 4 (50M – 200M+ Users)

### Database Sharding with Citus
```sql
-- Convert PostgreSQL to Citus distributed database
-- Shard key: household_id (all queries are household-scoped)

SELECT create_distributed_table('assets', 'household_id');
SELECT create_distributed_table('maintenance_reminders', 'household_id');
SELECT create_distributed_table('maintenance_records', 'household_id');
SELECT create_distributed_table('asset_health_scores', 'household_id');
SELECT create_distributed_table('service_bookings', 'household_id');
SELECT create_distributed_table('claims', 'household_id');
SELECT create_distributed_table('notifications', 'household_id');
SELECT create_distributed_table('critical_alerts', 'household_id');

-- Reference tables (small, replicated on all nodes)
SELECT create_reference_table('asset_categories');
SELECT create_reference_table('asset_subcategories');
SELECT create_reference_table('service_categories');
SELECT create_reference_table('protection_plan_templates');
SELECT create_reference_table('maintenance_templates');
```

### Multi-Region Setup
```
                US-East (Primary)                US-West (Secondary)
                ┌─────────────────┐             ┌─────────────────┐
                │  Route 53       │             │                 │
                │  (Latency)      │             │                 │
                └────────┬────────┘             │                 │
                         │                      │                 │
                ┌────────┴────────┐     ┌───────┴─────────┐      │
                │ CloudFront Edge │     │ CloudFront Edge  │      │
                └────────┬────────┘     └───────┬──────────┘     │
                         │                      │                 │
                ┌────────┴────────┐     ┌───────┴──────────┐     │
                │   EKS Cluster   │     │   EKS Cluster    │     │
                │   (50+ pods)    │     │   (50+ pods)     │     │
                └────────┬────────┘     └───────┬──────────┘     │
                         │                      │                 │
                ┌────────┴────────┐     ┌───────┴──────────┐     │
                │ Citus Coordinator│    │ Citus Coordinator │     │
                │    (Primary)    │────▶│    (Read Replica) │     │
                │ + 8 Worker Nodes│     │ + 8 Worker Nodes  │     │
                └─────────────────┘     └──────────────────┘     │
                                                                  │
                                        └─────────────────────────┘
```

---

## 10. Environment Variables (Complete)

```bash
# ─── Server ───
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
LOG_LEVEL=info

# ─── Database ───
DATABASE_URL=postgresql://user:pass@host:5432/homeiq?schema=public
DATABASE_POOL_MIN=5
DATABASE_POOL_MAX=50
DATABASE_READ_REPLICA_URL=postgresql://user:pass@read-host:5432/homeiq

# ─── Redis ───
REDIS_URL=rediss://user:pass@host:6379
REDIS_KEY_PREFIX=hiq:

# ─── Auth ───
JWT_SECRET=<64-char-random-string>
JWT_REFRESH_SECRET=<64-char-random-string>
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=30d

# ─── OAuth ───
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
APPLE_CLIENT_ID=com.homeiq.app
APPLE_TEAM_ID=xxx
APPLE_KEY_ID=xxx
APPLE_PRIVATE_KEY=<base64-encoded>

# ─── Stripe ───
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxx

# ─── OpenAI ───
OPENAI_API_KEY=sk-xxx
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=2000
OPENAI_DALLE_MODEL=dall-e-3

# ─── AWS ───
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
S3_BUCKET=homeiq-uploads-production
S3_CDN_URL=https://cdn.homeiq.com
SES_FROM_EMAIL=noreply@homeiq.com

# ─── Firebase (Push Notifications) ───
FCM_PROJECT_ID=homeiq-prod
FCM_SERVICE_ACCOUNT=<base64-encoded-json>

# ─── App Config ───
APP_URL=https://app.homeiq.com
API_URL=https://api.homeiq.com
CORS_ORIGINS=https://app.homeiq.com,https://homeiq.com

# ─── Rate Limits ───
RATE_LIMIT_GENERAL=200
RATE_LIMIT_AUTH=5
RATE_LIMIT_AI=10
RATE_LIMIT_UPLOAD=20
```
