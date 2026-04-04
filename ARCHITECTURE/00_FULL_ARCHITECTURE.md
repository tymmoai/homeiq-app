# HomeIQ (SquareTrade) — Full System Architecture

> **Version**: 1.0  
> **Date**: February 23, 2026 
> **Stack**: Flutter (Mobile) · React (Web) · Node.js (Backend) · PostgreSQL (Database)

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture Phases — From Launch to 200M](#2-architecture-phases)
3. [Backend Project Structure](#3-backend-project-structure)
4. [Database Schema (PostgreSQL)](#4-database-schema)
5. [Complete API Contract](#5-complete-api-contract)
6. [Authentication & Authorization](#6-authentication--authorization)
7. [Service-by-Service Backend Design](#7-service-by-service-backend-design)
8. [Infrastructure & Deployment](#8-infrastructure--deployment)
9. [Caching Strategy](#9-caching-strategy)
10. [Security Architecture](#10-security-architecture)
11. [Monitoring & Observability](#11-monitoring--observability)
12. [Cost Projections](#12-cost-projections)
13. [Build Order & Sprint Plan](#13-build-order--sprint-plan)

---

## 1. System Overview

### What This App Does

HomeIQ is a **home asset lifecycle management & protection plan platform**. Homeowners register their appliances/electronics, and the app provides:

- **Asset tracking** with AI-powered identification (brand, model, serial via photo)
- **Warranty & protection plan management** (3 tiers: Essential/Premium/Ultimate)
- **AI troubleshooting** (diagnose issues → DIY guides → parts ordering → technician booking)
- **9 home service categories** (assembly, mounting, moving, cleaning, outdoor, repairs, painting, security, lifestyle)
- **Shopping & trade-in** (buy replacement products with trade-in credit)
- **Claims processing** (repair/replacement/maintenance claims with full lifecycle)
- **Multi-home & family sharing** (multiple homes, invite family members with roles)
- **Maintenance engine** (automated reminders, health scoring, risk assessment)

### High-Level System Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                     │
│                                                                     │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐        │
│   │  Flutter App  │    │  React Web   │    │  Admin Panel  │        │
│   │  (iOS/Android)│    │  (Browser)   │    │  (Internal)   │        │
│   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘        │
│          │                   │                    │                 │
└──────────┼───────────────────┼────────────────────┼─────────────────┘
           │                   │                    │
           ▼                   ▼                    ▼
┌────────────────────────────────────────────────────────────────────┐
│                      CDN (CloudFront)                               │
│         Static assets, images, documents, web bundles              │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│                    API GATEWAY (Kong / AWS)                          │
│   ┌─────────────┐ ┌──────────────┐ ┌──────────────┐              │
│   │ Rate Limiter    │ │  JWT Verify  │ │ Request Log  │              │
│   └─────────────┘ └──────────────┘ └──────────────┘              │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
┌────────────┐    ┌────────────┐    ┌────────────┐
│   Auth     │    │   Core     │    │  Booking   │
│  Service   │    │  Service   │    │  Service   │
│            │    │            │    │            │
│ • signup   │    │ • users    │    │ • book     │
│ • signin   │    │ • homes    │    │ • cancel   │
│ • OTP      │    │ • assets   │    │ • schedule │
│ • social   │    │ • warranty │    │ • history  │
│ • refresh  │    │ • maint.   │    │ • status   │
└─────┬──────┘    └─────┬──────┘    └─────┬──────┘
      │                 │                 │
      ▼                 ▼                 ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Auth DB  │     │ Core DB  │     │Booking DB│
│(Postgres)│     │(Postgres)│     │(Postgres)│
└──────────┘     └──────────┘     └──────────┘

┌────────────┐    ┌────────────┐    ┌────────────┐
│  Payment   │    │Notification│    │    AI      │
│  Service   │    │  Service   │    │  Service   │
│            │    │            │    │            │
│ • Stripe   │    │ • push     │    │ • GPT-4o  │
│ • cards    │    │ • email    │    │ • DALL-E   │
│ • install. │    │ • SMS      │    │ • diagnose │

│ • refund   │    │ • in-app   │    │ • DIY gen  │
└─────┬──────┘    └─────┬──────┘    └─────┬──────┘
      │                 │                 │
      ▼                 ▼                 ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│Payment DB│     │  Redis   │     │ AI Cache │
│(Postgres)│     │ + FCM    │     │ (Redis)  │
└──────────┘     │ + SES    │     └──────────┘
                 └──────────┘

┌────────────┐    ┌────────────┐    ┌────────────┐
│  Order     │    │  Claims    │    │  Product   │
│  Service   │    │  Service   │    │  Catalog   │
└─────┬──────┘    └─────┬──────┘    └─────┬──────┘
      │                 │                 │
      ▼                 ▼                 ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Order DB │     │ Claims DB│     │Catalog DB│
│(Postgres)│     │(Postgres)│     │(Postgres)│
└──────────┘     └──────────┘     └──────────┘

         ┌──────────────────────────────┐
         │      SHARED INFRASTRUCTURE   │
         │                              │
         │  ┌────────┐  ┌───────────┐  │
         │  │ Redis  │  │    S3     │  │
         │  │ Cluster│  │ (Files)   │  │
         │  └────────┘  └───────────┘  │
         │  ┌────────┐  ┌───────────┐  │
         │  │ BullMQ │  │ElasticSrch│  │
         │  │ (Jobs) │  │ (Search)  │  │
         │  └────────┘  └───────────┘  │
         └──────────────────────────────┘
```

### Technology Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| **Mobile App** | Flutter (Dart) | ✅ Already built |
| **Web App** | React | ✅ Already built |
| **API Framework** | **Fastify** (Node.js + TypeScript) | 2× faster than Express, built-in validation, TypeScript-first |
| **ORM** | **Prisma** | Type-safe queries, auto-migrations, great DX |
| **Database** | **PostgreSQL 16** | ACID, JSONB, full-text search, partitioning, Citus for sharding |
| **Cache** | **Redis 7 (Cluster)** | Sessions, rate limits, hot data, job queues |
| **Job Queue** | **BullMQ** (Redis-backed) | Background: emails, push, AI calls, health scoring |
| **File Storage** | **AWS S3** | Documents, receipts, photos, AI wireframes |
| **CDN** | **AWS CloudFront** | Static assets, images globally |
| **Auth** | **JWT** (access 15min + refresh 30d) | Stateless, scalable |
| **Social Auth** | **Passport.js** (Google, Apple) | Battle-tested OAuth |
| **Payments** | **Stripe** | Cards, subscriptions, installments |
| **Push** | **Firebase Cloud Messaging** | Cross-platform push |
| **Email** | **AWS SES** | Transactional emails |
| **SMS** | **Twilio** | OTP codes |
| **AI** | **OpenAI API** (proxied via backend) | GPT-4o-mini + DALL-E 3 |
| **Search** | **ElasticSearch** (or Meilisearch) | Product/asset search |
| **Monitoring** | **Datadog** or **Grafana + Prometheus** | Metrics, logs, traces |
| **Error Tracking** | **Sentry** | Flutter + Node.js |
| **CI/CD** | **GitHub Actions** | Build, test, deploy |
| **Infrastructure** | **AWS** (ECS → EKS) | Industry standard |
| **Containers** | **Docker** | Consistent environments |

---

## 2. Architecture Phases

### Phase 1 — Launch : Modular Monolith

```
Flutter/React ──→ Fastify API (1 server) ──→ PostgreSQL (1 instance)
                         ↕                         ↕
                      Redis                       S3
```

- **One Fastify server** with modular folder structure (modules for auth, assets, bookings, etc.)
- **One PostgreSQL instance** (db.r6g.large — 2 vCPU, 16GB RAM)
- **Redis** (cache.t4g.micro) for sessions, rate limits, OTP codes
- **S3** for file uploads
- **Deploy**: AWS ECS Fargate (2 tasks) behind ALB
- **Why monolith**: Fast to build, easy to debug, one deployment, one repo

### Phase 2 — Growth : Horizontal Scaling

```
Clients ──→ ALB ──→ 3-5 Fastify instances ──→ PgBouncer ──→ Postgres Primary
                                                                    │
                                                             ┌──────┤
                                                             ▼      ▼
                                                         Replica  Replica
                         ↕
                   Redis Cluster (3 nodes)
                         ↕
                   BullMQ Workers (2-3 instances)
```

- **Auto-scaling** Fastify instances (3–10) behind ALB
- **PostgreSQL read replicas** (2–3) for heavy read queries
- **PgBouncer** connection pooling (6,000+ concurrent connections)
- **Redis Cluster** (3 nodes) for distributed cache
- **BullMQ workers** as separate processes for background jobs
- **ElasticSearch** for product search and asset search
- **CDN** for all images and static assets

### Phase 3 — Scale : Extract Microservices


- **Split monolith** into independent services:
  - `auth-service` — login, OTP, social, tokens
  - `user-service` — profiles, households, family
  - `asset-service` — assets, warranties, health, maintenance
  - `booking-service` — all 9 service categories
  - `order-service` — shopping, checkout, trade-ins
  - `claim-service` — claims lifecycle
  - `payment-service` — Stripe, installments
  - `notification-service` — push, email, SMS, in-app
  - `ai-service` — OpenAI proxy, troubleshooting
  - `product-service` — catalog, search
- **Each service owns its database** (database-per-service)
- **Message broker** (RabbitMQ or AWS SQS) for async inter-service events
- **API Gateway** (Kong) for routing, rate limiting, auth verification
- **Kubernetes (EKS)** for orchestration

### Phase 4 — Massive Scale : Distributed



- **Database sharding** via Citus (PostgreSQL extension) — shard by `household_id`
- **Multi-region** — US-East (primary) + US-West (secondary) + US-Central
- **CQRS** for high-read endpoints (home dashboard, asset list, notification list)
- **Event sourcing** for claims and orders (full audit trail)
- **Global CDN** with edge caching
- **WebSockets** (Socket.io) for real-time updates (booking status, delivery tracking)
- **Data warehouse** (Redshift/BigQuery) for analytics
- **ML pipeline** for predictive health scoring and upgrade recommendations

---

## 3. Backend Project Structure

```
homeiq-backend/
├── .github/
│   └── workflows/
│       ├── ci.yml                  # Lint + test on PR
│       ├── deploy-staging.yml      # Deploy to staging
│       └── deploy-production.yml   # Deploy to production
├── docker/
│   ├── Dockerfile                  # Node.js production image
│   ├── Dockerfile.dev             # Development with hot reload
│   └── docker-compose.yml         # Local dev: API + Postgres + Redis
├── prisma/
│   ├── schema.prisma              # Full database schema
│   ├── migrations/                # Auto-generated migrations
│   └── seed.ts                    # Seed data (categories, plans, etc.)
├── src/
│   ├── app.ts                     # Fastify app setup, plugin registration
│   ├── server.ts                  # Entry point, start server
│   ├── config/
│   │   ├── index.ts               # Environment config loader
│   │   ├── database.ts            # Prisma client singleton
│   │   ├── redis.ts               # Redis client
│   │   ├── stripe.ts              # Stripe client
│   │   ├── s3.ts                  # AWS S3 client
│   │   ├── openai.ts              # OpenAI client
│   │   ├── firebase.ts            # FCM client
│   │   └── email.ts               # SES / SendGrid client
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.routes.ts     # POST /auth/signup, /signin, /otp/*, /google, /apple, /refresh, /logout
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.schema.ts     # Zod validation schemas
│   │   │   ├── strategies/
│   │   │   │   ├── google.strategy.ts
│   │   │   │   └── apple.strategy.ts
│   │   │   └── auth.tests.ts
│   │   ├── users/
│   │   │   ├── users.routes.ts    # GET/PUT /users/me, DELETE /users/me
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── users.schema.ts
│   │   │   └── users.tests.ts
│   │   ├── households/
│   │   │   ├── households.routes.ts  # CRUD /households, /households/:id/invite, /households/:id/members
│   │   │   ├── households.controller.ts
│   │   │   ├── households.service.ts
│   │   │   ├── invites.service.ts
│   │   │   ├── households.schema.ts
│   │   │   └── households.tests.ts
│   │   ├── assets/
│   │   │   ├── assets.routes.ts   # CRUD /households/:hid/assets, /assets/:id
│   │   │   ├── assets.controller.ts
│   │   │   ├── assets.service.ts
│   │   │   ├── warranties.service.ts
│   │   │   ├── documents.service.ts
│   │   │   ├── health-score.service.ts    # Health scoring engine
│   │   │   ├── assets.schema.ts
│   │   │   └── assets.tests.ts
│   │   ├── maintenance/
│   │   │   ├── maintenance.routes.ts
│   │   │   ├── maintenance.controller.ts
│   │   │   ├── maintenance.service.ts
│   │   │   ├── reminders.service.ts       # Auto-schedule reminders
│   │   │   ├── health-engine.service.ts   # Compute health + risk scores
│   │   │   ├── maintenance.schema.ts
│   │   │   └── maintenance.tests.ts
│   │   ├── claims/
│   │   │   ├── claims.routes.ts
│   │   │   ├── claims.controller.ts
│   │   │   ├── claims.service.ts
│   │   │   ├── claims.schema.ts
│   │   │   └── claims.tests.ts
│   │   ├── bookings/
│   │   │   ├── bookings.routes.ts
│   │   │   ├── bookings.controller.ts
│   │   │   ├── bookings.service.ts
│   │   │   ├── technicians.service.ts
│   │   │   ├── scheduling.service.ts
│   │   │   ├── bookings.schema.ts
│   │   │   └── bookings.tests.ts
│   │   ├── orders/
│   │   │   ├── orders.routes.ts
│   │   │   ├── orders.controller.ts
│   │   │   ├── orders.service.ts
│   │   │   ├── trade-ins.service.ts
│   │   │   ├── orders.schema.ts
│   │   │   └── orders.tests.ts
│   │   ├── products/
│   │   │   ├── products.routes.ts
│   │   │   ├── products.controller.ts
│   │   │   ├── products.service.ts
│   │   │   ├── products.schema.ts
│   │   │   └── products.tests.ts
│   │   ├── protection-plans/
│   │   │   ├── plans.routes.ts
│   │   │   ├── plans.controller.ts
│   │   │   ├── plans.service.ts
│   │   │   ├── plans.schema.ts
│   │   │   └── plans.tests.ts
│   │   ├── payments/
│   │   │   ├── payments.routes.ts
│   │   │   ├── payments.controller.ts
│   │   │   ├── payments.service.ts
│   │   │   ├── stripe.service.ts
│   │   │   ├── installments.service.ts
│   │   │   ├── webhooks.controller.ts     # Stripe webhooks
│   │   │   ├── payments.schema.ts
│   │   │   └── payments.tests.ts
│   │   ├── notifications/
│   │   │   ├── notifications.routes.ts
│   │   │   ├── notifications.controller.ts
│   │   │   ├── notifications.service.ts
│   │   │   ├── push.service.ts            # FCM
│   │   │   ├── email.service.ts           # SES templates
│   │   │   ├── sms.service.ts             # Twilio
│   │   │   ├── notifications.schema.ts
│   │   │   └── notifications.tests.ts
│   │   ├── alerts/
│   │   │   ├── alerts.routes.ts
│   │   │   ├── alerts.controller.ts
│   │   │   ├── alerts.service.ts          # Auto-generate alerts
│   │   │   ├── alerts.schema.ts
│   │   │   └── alerts.tests.ts
│   │   └── ai/
│   │       ├── ai.routes.ts
│   │       ├── ai.controller.ts
│   │       ├── ai.service.ts
│   │       ├── openai.client.ts           # GPT-4o-mini + DALL-E proxy
│   │       ├── ai.schema.ts
│   │       └── ai.tests.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts             # JWT verification
│   │   ├── rbac.middleware.ts             # Role-based access (owner/admin/member/viewer)
│   │   ├── rate-limit.middleware.ts
│   │   ├── request-id.middleware.ts
│   │   ├── error-handler.middleware.ts
│   │   └── validate.middleware.ts         # Zod schema validation
│   ├── jobs/
│   │   ├── queue.ts                       # BullMQ queue setup
│   │   ├── email.job.ts                   # Send emails
│   │   ├── push.job.ts                    # Send push notifications
│   │   ├── sms.job.ts                     # Send SMS (OTP)
│   │   ├── health-score.job.ts            # Recompute asset health scores
│   │   ├── maintenance-reminder.job.ts    # Generate upcoming reminders
│   │   ├── warranty-alert.job.ts          # Check expiring warranties
│   │   ├── ai-analysis.job.ts             # Async AI processing
│   │   └── cleanup.job.ts                # Expired tokens, old OTPs
│   ├── shared/
│   │   ├── types.ts                       # Shared TypeScript types
│   │   ├── errors.ts                      # Custom error classes
│   │   ├── pagination.ts                  # Pagination helper
│   │   ├── id-generator.ts               # Generate HQ-ORD-*, CLM-*, BKG-* IDs
│   │   └── constants.ts                   # App-wide constants
│   └── utils/
│       ├── jwt.ts                         # Token sign/verify/refresh
│       ├── hash.ts                        # bcrypt wrapper
│       ├── otp.ts                         # OTP generation/verification
│       ├── upload.ts                      # S3 upload helper
│       ├── email-templates.ts             # HTML email templates
│       └── logger.ts                      # Pino logger config
├── tests/
│   ├── setup.ts                           # Test DB setup
│   ├── helpers.ts                         # Test utilities
│   └── integration/                       # E2E API tests
├── .env.example
├── .env.development
├── .env.staging
├── .env.production
├── .eslintrc.js
├── tsconfig.json
├── package.json
└── README.md
```

---

## 4. Database Schema

> See separate file: `01_DATABASE_SCHEMA.sql`

The database has **30+ tables** organized into these domains:

| Domain | Tables | Purpose |
|--------|--------|---------|
| **Auth** | `users`, `user_sessions`, `otp_codes` | Authentication, sessions |
| **Households** | `households`, `household_members`, `invites` | Multi-home, family |
| **Assets** | `assets`, `asset_documents`, `asset_warranties`, `asset_categories`, `asset_subcategories` | Asset inventory |
| **Maintenance** | `maintenance_templates`, `maintenance_reminders`, `maintenance_records`, `asset_health_scores` | Health scoring, reminders |
| **Claims** | `claims`, `claim_status_history`, `claim_documents` | Claims lifecycle |
| **Bookings** | `service_categories`, `service_providers`, `service_bookings`, `booking_status_history` | Service bookings |
| **Orders** | `orders`, `order_items`, `order_status_history`, `trade_ins` | Shopping, trade-ins |
| **Products** | `products` | Product catalog |
| **Plans** | `protection_plan_templates`, `user_protection_plans` | Protection plans |
| **Payments** | `payment_methods`, `payments`, `installment_plans`, `installment_payments` | Payment processing |
| **Notifications** | `notifications`, `critical_alerts`, `push_tokens` | Alerts & notifications |
| **AI** | `ai_sessions` | AI usage tracking |

### Key Design Decisions

1. **UUIDs** for all primary keys — essential for distributed systems, prevents enumeration
2. **`household_id` as the main partition key** — all data is scoped to a household
3. **JSONB** for flexible/variable data (service details, coverage items, addresses, booking specifics)
4. **Status history tables** for claims, orders, bookings — full audit trail of every transition
5. **Soft deletes** (`deleted_at` column) for users and assets — never lose data
6. **Separate `push_tokens` table** — one user can have multiple devices
7. **Indexes** on every foreign key and frequently queried column

---

## 5. Complete API Contract

> See separate file: `02_API_CONTRACT.md`

### Base URL
```
Production:  https://api.homeiq.com/v1
Staging:     https://api-staging.homeiq.com/v1
Development: http://localhost:3000/v1
```

### API Summary (70+ endpoints)

| Module | Endpoints | Auth Required |
|--------|-----------|---------------|
| Auth | 8 endpoints | No (except logout, refresh) |
| Users | 3 endpoints | Yes |
| Households | 8 endpoints | Yes |
| Assets | 8 endpoints | Yes |
| Maintenance | 8 endpoints | Yes |
| Claims | 5 endpoints | Yes |
| Bookings | 7 endpoints | Yes |
| Orders | 4 endpoints | Yes |
| Products | 4 endpoints | Yes (partial) |
| Protection Plans | 5 endpoints | Yes |
| Payments | 6 endpoints | Yes |
| Notifications | 4 endpoints | Yes |
| Alerts | 3 endpoints | Yes |
| AI | 5 endpoints | Yes |

### Standard Response Format
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 150,
    "totalPages": 8
  }
}
```

### Standard Error Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": [
      { "field": "email", "message": "Must be a valid email address" }
    ]
  }
}
```

---

## 6. Authentication & Authorization

### Auth Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Sign Up │────▶│ Send OTP │────▶│Verify OTP│────▶│  Home    │
│  Form    │     │(SMS/Email)│     │  Screen  │     │  Screen  │
└──────────┘     └──────────┘     └──────────┘     └──────────┘

┌──────────┐     ┌──────────┐     ┌──────────┐
│  Sign In │────▶│ Send OTP │────▶│  Home    │
│  Form    │     │(SMS/Email)│     │  Screen  │
└──────────┘     └──────────┘     └──────────┘

┌──────────┐     ┌──────────┐     ┌──────────┐
│  Google  │────▶│ Backend  │────▶│  Home    │
│  Button  │     │ Verify   │     │  Screen  │
└──────────┘     └──────────┘     └──────────┘
```

### Token Strategy

| Token | Lifetime | Storage | Purpose |
|-------|----------|---------|---------|
| Access Token (JWT) | 15 minutes | Memory (Flutter) | API authentication |
| Refresh Token | 30 days | flutter_secure_storage | Get new access token |
| OTP Code | 5 minutes | Redis (hashed) | Verify email/phone |
| Invite Token | 7 days | PostgreSQL (hashed) | Family member invite |

### JWT Payload
```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "iat": 1708732800,
  "exp": 1708733700,
  "type": "access"
}
```

### Role-Based Access Control (RBAC)

| Role | Can View Home | Can Add Assets | Can Book Services | Can Manage Members | Can Delete Home |
|------|:---:|:---:|:---:|:---:|:---:|
| **Owner** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Admin** | ✅ | ✅ | ✅ | ✅ (except owner) | ❌ |
| **Member** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Viewer** | ✅ | ❌ | ❌ | ❌ | ❌ |

### RBAC Middleware
```
Every request with household context:
1. JWT verify → extract userId
2. Check household_members → get role for this user + household
3. Compare role against required permission for this endpoint
4. Allow or deny (403)
```

---

## 7. Service-by-Service Backend Design

### 7.1 Asset Health Scoring Engine

The health score is a **computed value (0–100)** based on multiple factors:

```
healthScore = weighted_average(
  age_factor          × 0.25,   // Based on purchase date vs expected lifespan
  maintenance_rate    × 0.30,   // % of maintenance tasks completed on time
  issue_history       × 0.25,   // Number and severity of past claims/issues
  brand_reliability   × 0.20    // Brand reliability data (static table)
)

riskScore = inverse(healthScore) with adjustments for:
  - Expired warranty (+20 risk)
  - No protection plan (+10 risk)
  - Overdue maintenance (+15 risk per overdue task)
```

**When to recompute:**
- Asset created → initial score
- Maintenance completed/skipped → cron job (every 6 hours) or event-driven
- Claim resolved → immediate recompute
- Daily cron → recompute all assets with `last_computed > 24 hours`

### 7.2 Maintenance Reminder Engine

```
On asset creation:
  1. Look up maintenance_templates for asset's subcategory
  2. Generate initial reminders based on template intervals
  3. Set first due_date = purchase_date + interval (or now + interval if old)

Daily cron job:
  1. Find all reminders where due_date <= today AND status = 'pending'
  2. Mark as 'overdue'
  3. Generate notification for user
  4. Update asset health score

On reminder completion:
  1. Mark current reminder as 'completed'
  2. Create next reminder (due_date = now + interval)
  3. Recompute asset health score
```

### 7.3 Claims Lifecycle

```
submitted → underReview → approved → inProgress → resolved
                       ↘ denied
                       
State transitions:
  submitted:   User files claim. System auto-checks warranty/plan coverage.
  underReview:  Background job or admin reviews. Check deductible.
  approved:     Calculate approved amount. Notify user.
  denied:       Set resolution notes. Notify user.
  inProgress:   Technician assigned or replacement shipped.
  resolved:     Service completed or replacement delivered. Close claim.
```

### 7.4 Service Booking Categories

| # | Category | Prefix | Base Price | Special Fields |
|---|----------|--------|-----------|----------------|
| 1 | Assembly | BK | $55 | items (furniture/office/kids/outdoor), addons |
| 2 | Mounting | MNT | $49 | wallType, mountingHeight, items |
| 3 | Moving | MOV | $60 | homeType, homeSize, rooms, floor, elevator, pickup/drop addresses, distance, packing level |
| 4 | Cleaning | CL | $50 | frequency, intensity, condition multiplier, recurring discounts |
| 5 | Outdoor | OH | $50 | lawn/garden/pressure/gutter/deck/seasonal, condition multiplier |
| 6 | Home Repairs | HR | $65 | leak/electrical/wall/door/appliance issues, urgency multiplier |
| 7 | Painting | PT | $100 | interior/exterior/cabinets/touchups, surface condition multiplier, estimate visit fee $49 |
| 8 | Security | SC | $75 | camera/lock/alarm/full setup, installation type multiplier, device options |
| 9 | Lifestyle | HQ | Varies | cab/restaurant/hotel/healthcare (each with unique fields) |

All bookings share: scheduled date/time, contact info, address, payment, status lifecycle, terms acceptance.

### 7.5 AI Service (OpenAI Proxy)

**CRITICAL**: Never expose OpenAI API key to clients. All AI calls go through your backend.

```
Client → POST /v1/ai/brand-lookup → Backend → OpenAI GPT-4o-mini → response
Client → POST /v1/ai/analyze-issue → Backend → OpenAI GPT-4o-mini → response
Client → POST /v1/ai/diy-steps → Backend → OpenAI GPT-4o-mini → response
Client → POST /v1/ai/nameplate-guide → Backend → OpenAI DALL-E 3 → response
```

**Caching**: Cache brand lookups and subcategory lists in Redis (TTL: 24 hours). Same asset type + brand combo always returns same brands — no need to hit OpenAI every time.

**Rate limiting**: Max 10 AI requests per user per hour. Track in Redis.

**Cost control**: Log every AI call in `ai_sessions` table with `tokens_used` and `cost_cents`.

### 7.6 Notification Types (9 types)

| Type | Trigger | Channel |
|------|---------|---------|
| `booking_confirmed` | Booking created | Push + In-app |
| `order_confirmed` | Order placed | Push + In-app + Email |
| `asset_added` | Asset registered | In-app |
| `technician_on_way` | Technician status update | Push + In-app |
| `service_reminder` | 24h before scheduled service | Push + In-app |
| `payment_successful` | Payment succeeded | In-app + Email |
| `maintenance_due` | Reminder becomes overdue | Push + In-app |
| `maintenance_completed` | Reminder marked done | In-app |
| `plan_renewed` | Protection plan auto-renewed | Push + In-app + Email |
| `warranty_expiring` | 30 days before warranty expires | Push + In-app + Email |
| `claim_status_changed` | Any claim status transition | Push + In-app |
| `invite_received` | Family invite sent | Email + Push (if existing user) |

### 7.7 Alert Engine

**Automatic alert generation** (daily cron job):

```
1. WARRANTY ALERTS:
   - Find assets where warranty_end_date <= today → severity: critical
   - Find assets where warranty_end_date <= today + 30 days → severity: warning

2. HEALTH ALERTS:
   - Find assets where health_score < 30 → severity: critical
   - Find assets where health_score < 50 → severity: warning

3. MAINTENANCE ALERTS:
   - Find reminders overdue > 7 days → severity: warning
   - Find reminders overdue > 30 days → severity: critical

4. SAFETY ALERTS:
   - Find assets with type 'gas' and last_inspection > 1 year → severity: critical
   - Find assets with type 'electrical' and age > 15 years → severity: warning
```

---

## 8. Infrastructure & Deployment

### AWS Architecture (Phase 1–2)

```
┌──────────────────────────────────────────────────────┐
│                      AWS VPC                          │
│                                                       │
│  ┌─────────────── Public Subnet ───────────────────┐ │
│  │                                                  │ │
│  │  ┌──────────┐     ┌──────────┐                  │ │
│  │  │   ALB    │────▶│   NAT    │                  │ │
│  │  │  (HTTPS) │     │ Gateway  │                  │ │
│  │  └────┬─────┘     └──────────┘                  │ │
│  │       │                                          │ │
│  └───────┼──────────────────────────────────────────┘ │
│          │                                            │
│  ┌───────┼───── Private Subnet ─────────────────────┐ │
│  │       ▼                                           │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │ │
│  │  │ ECS Task │  │ ECS Task │  │ ECS Task │       │ │
│  │  │ (API #1) │  │ (API #2) │  │ (Worker) │       │ │
│  │  └──────────┘  └──────────┘  └──────────┘       │ │
│  │                                                   │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │ │
│  │  │   RDS    │  │ RDS Read │  │  Elasti  │       │ │
│  │  │ Primary  │  │ Replica  │  │  Cache   │       │ │
│  │  │(Postgres)│  │(Postgres)│  │ (Redis)  │       │ │
│  │  └──────────┘  └──────────┘  └──────────┘       │ │
│  │                                                   │ │
│  └───────────────────────────────────────────────────┘ │
│                                                       │
│  ┌────────┐  ┌────────┐  ┌──────────┐               │
│  │   S3   │  │  SES   │  │CloudFront│               │
│  │(Files) │  │(Email) │  │  (CDN)   │               │
│  └────────┘  └────────┘  └──────────┘               │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### Docker Compose (Local Development)

```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build:
      context: .
      dockerfile: docker/Dockerfile.dev
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://homeiq:homeiq@postgres:5432/homeiq_dev
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=dev-secret-change-in-production
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - S3_BUCKET=homeiq-uploads-dev
    volumes:
      - ./src:/app/src
    depends_on:
      - postgres
      - redis

  worker:
    build:
      context: .
      dockerfile: docker/Dockerfile.dev
    command: npm run worker
    environment:
      - DATABASE_URL=postgresql://homeiq:homeiq@postgres:5432/homeiq_dev
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=homeiq
      - POSTGRES_PASSWORD=homeiq
      - POSTGRES_DB=homeiq_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Environment Variables

```env
# .env.example

# Server
NODE_ENV=development
PORT=3000
HOST=0.0.0.0
API_VERSION=v1
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/homeiq
DATABASE_POOL_MIN=5
DATABASE_POOL_MAX=20

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PREFIX=homeiq:

# JWT
JWT_SECRET=your-256-bit-secret
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=30d

# OTP
OTP_LENGTH=6
OTP_EXPIRY_MINUTES=5
OTP_MAX_ATTEMPTS=3

# Google OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Apple OAuth
APPLE_CLIENT_ID=
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=

# Stripe
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_PUBLISHABLE_KEY=

# OpenAI
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=2000
OPENAI_RATE_LIMIT_PER_USER=10

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_BUCKET=homeiq-uploads
CLOUDFRONT_URL=https://cdn.homeiq.com

# Email (AWS SES)
SES_FROM_EMAIL=noreply@homeiq.com
SES_REGION=us-east-1

# SMS (Twilio)
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# Push Notifications (Firebase)
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=

# Sentry
SENTRY_DSN=

# Logging
LOG_LEVEL=info
```

---

## 9. Caching Strategy

### What to Cache (Redis)

| Key Pattern | TTL | Data |
|-------------|-----|------|
| `session:{userId}` | 30 days | Refresh token hash, device info |
| `otp:{emailOrPhone}` | 5 min | Hashed OTP code, attempts count |
| `rate:{ip}:{endpoint}` | 1 min | Request count |
| `rate:ai:{userId}` | 1 hour | AI request count |
| `user:{userId}` | 1 hour | User profile data |
| `homes:{userId}` | 1 hour | User's household list |
| `assets:{householdId}` | 30 min | Asset list for a home |
| `health:{assetId}` | 6 hours | Asset health score |
| `brands:{assetType}` | 24 hours | AI brand lookup result |
| `subcats:{assetType}` | 24 hours | AI subcategory lookup result |
| `plans:templates` | 24 hours | Protection plan templates |
| `products:popular` | 1 hour | Popular products list |
| `notifications:unread:{userId}` | 5 min | Unread notification count |

### Cache Invalidation Rules

```
User updates profile       → DELETE user:{userId}
Asset added/updated/deleted → DELETE assets:{householdId}
Member added/removed       → DELETE homes:{userId} for ALL members of that household
Health score recomputed    → DELETE health:{assetId}, UPDATE assets:{householdId}
New notification created   → DELETE notifications:unread:{userId}
```

---

## 10. Security Architecture

### API Security Checklist

| Layer | Implementation |
|-------|---------------|
| **HTTPS** | TLS 1.3 everywhere. HSTS header. |
| **Authentication** | JWT (short-lived) + refresh tokens |
| **Authorization** | RBAC middleware on every household-scoped endpoint |
| **Rate Limiting** | Per-IP: 100 req/min. Per-user: 200 req/min. Auth endpoints: 5 req/min. AI: 10 req/hour. |
| **Input Validation** | Zod schemas on every endpoint. Reject unknown fields. |
| **SQL Injection** | Prisma parameterized queries (never raw SQL with user input) |
| **XSS** | Sanitize all user input. CSP headers on web. |
| **CORS** | Whitelist only `homeiq.com`, `app.homeiq.com`, `localhost` (dev only) |
| **File Upload** | Validate file type, size (max 10MB). Scan for malware. Store in S3 (never local). |
| **Sensitive Data** | Never store raw card numbers (Stripe handles PCI). Hash OTP codes. Encrypt PII at rest. |
| **API Keys** | OpenAI key ONLY on backend. Stripe secret ONLY on backend. |
| **Audit Log** | Log: login, password change, payment, claim status change, member invite/remove. |
| **Secrets** | AWS Secrets Manager / Parameter Store. Never in code. |
| **Dependencies** | `npm audit` in CI. Dependabot alerts enabled. |
| **Headers** | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `X-XSS-Protection: 1; mode=block` |

### Data Encryption

| Data | At Rest | In Transit |
|------|---------|-----------|
| Passwords | bcrypt (12 rounds) | TLS |
| OTP codes | SHA-256 hash | TLS |
| Refresh tokens | SHA-256 hash in DB | TLS |
| Invite tokens | SHA-256 hash in DB | TLS |
| Card numbers | Stripe vault (never touch) | TLS + Stripe.js |
| User PII | AES-256 (optional for sensitive fields) | TLS |
| Files (S3) | SSE-S3 encryption | TLS |

---

## 11. Monitoring & Observability

### Three Pillars

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   METRICS    │    │    LOGS      │    │   TRACES     │
│              │    │              │    │              │
│ • Request/s  │    │ • Structured │    │ • Request ID │
│ • Latency    │    │ • JSON logs  │    │ • Span IDs   │
│ • Error rate │    │ • Request ID │    │ • Service map│
│ • DB pool    │    │ • User ID    │    │ • Bottleneck │
│ • Redis hits │    │ • Error stack│    │   detection  │
│ • Queue size │    │ • AI costs   │    │              │
│              │    │              │    │              │
│  Prometheus  │    │   Pino →     │    │  OpenTelemetry│
│  + Grafana   │    │  CloudWatch  │    │  + Jaeger    │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Key Dashboards

1. **API Health**: Request rate, error rate (4xx, 5xx), p50/p95/p99 latency
2. **Database**: Active connections, query time, replication lag, disk usage
3. **Redis**: Hit rate, memory usage, evictions, connected clients
4. **Queue**: Job throughput, failed jobs, queue depth, processing time
5. **Business**: Sign-ups/day, bookings/day, orders/day, claims filed, AI usage
6. **Costs**: OpenAI spend, Twilio spend, SES spend, infra spend

### Alerting Rules

| Alert | Condition | Severity |
|-------|-----------|----------|
| API Error Rate | >5% of requests returning 5xx | Critical |
| API Latency | p95 > 2 seconds | Warning |
| Database CPU | >80% for 5 minutes | Critical |
| Database Connections | >80% of max pool | Warning |
| Redis Memory | >80% | Warning |
| Queue Backlog | >1000 pending jobs | Warning |
| Queue Failed Jobs | >50 in 1 hour | Critical |
| Disk Space | >85% on any volume | Warning |
| SSL Certificate | Expires in <14 days | Critical |
| OpenAI Spend | >$100/day | Warning |

---

## 12. Cost Projections

### Phase 1: Launch 

| Service | Spec | Monthly Cost |
|---------|------|-------------|
| ECS Fargate (2 tasks) | 0.5 vCPU, 1GB each | ~$30 |
| RDS PostgreSQL | db.t4g.medium (2 vCPU, 4GB) | ~$70 |
| ElastiCache Redis | cache.t4g.micro | ~$15 |
| S3 | 50GB storage | ~$2 |
| CloudFront | 100GB transfer | ~$10 |
| ALB | 1 load balancer | ~$25 |
| SES | 10K emails/month | ~$1 |
| **Subtotal (AWS)** | | **~$153** |
| Twilio SMS | 5K OTPs/month | ~$40 |
| OpenAI API | Light usage | ~$50 |
| Sentry | Free tier | $0 |
| GitHub Actions | Free tier | $0 |
| **Total** | | **~$250/month** |

### Phase 2: Growth 

| Service | Spec | Monthly Cost |
|---------|------|-------------|
| ECS Fargate (5–10 tasks) | 1 vCPU, 2GB each | ~$300 |
| RDS PostgreSQL (Primary + 2 replicas) | db.r6g.large | ~$800 |
| ElastiCache Redis (3-node cluster) | cache.r6g.large | ~$500 |
| S3 | 1TB storage | ~$25 |
| CloudFront | 5TB transfer | ~$500 |
| ALB | 1 load balancer | ~$50 |
| ElasticSearch | 2 nodes, m5.large | ~$400 |
| SES | 500K emails/month | ~$50 |
| **Subtotal (AWS)** | | **~$2,625** |
| Twilio SMS | 200K OTPs/month | ~$1,600 |
| OpenAI API | Moderate usage | ~$500 |
| Stripe | 2.9% + $0.30/txn | Variable |
| Sentry | Team plan | ~$30 |
| Datadog | Pro plan | ~$200 |
| **Total** | | **~$5K–$8K/month** |

### Phase 3: Scale 

| Service | Monthly Cost |
|---------|-------------|
| EKS + EC2 instances (20–50 pods) | ~$5,000 |
| RDS PostgreSQL (Multi-AZ + 5 replicas) | ~$5,000 |
| ElastiCache Redis (6-node cluster) | ~$3,000 |
| S3 + CloudFront | ~$3,000 |
| ElasticSearch (3 nodes) | ~$2,000 |
| SES + Twilio | ~$5,000 |
| OpenAI API | ~$5,000 |
| Datadog | ~$1,000 |
| **Total** | **~$30K–$50K/month** |

### Phase 4: Massive 

| Service | Monthly Cost |
|---------|-------------|
| EKS Multi-Region (100+ pods) | ~$30,000 |
| RDS + Citus Sharding (Multi-Region) | ~$40,000 |
| ElastiCache Global Datastore | ~$15,000 |
| S3 + CloudFront (global) | ~$20,000 |
| ElasticSearch (large cluster) | ~$10,000 |
| SES + Twilio (millions of messages) | ~$30,000 |
| OpenAI API (heavy usage) | ~$50,000 |
| Datadog Enterprise | ~$15,000 |
| **Total** | **~$200K–$350K/month** |

---

## 13. Build Order & Sprint Plan

### Sprint 1–2 (Weeks 1–4): Foundation + Auth
- [ ] Set up Node.js + Fastify + TypeScript project
- [ ] Set up Docker + docker-compose (Postgres + Redis)
- [ ] Set up Prisma + initial schema migration
- [ ] Implement auth module: signup, signin, OTP (send via Twilio, verify)
- [ ] Implement JWT access/refresh token flow
- [ ] Implement Google OAuth + Apple Sign In
- [ ] Auth middleware (JWT verify)
- [ ] Rate limiting middleware
- [ ] Error handling + request logging
- [ ] Connect Flutter app to auth endpoints

### Sprint 3–4 (Weeks 5–8): Users + Households + Family
- [ ] User profile CRUD (GET/PUT /users/me)
- [ ] Household CRUD (create, list, update, delete)
- [ ] Family invite flow (create invite → send email → accept/reject)
- [ ] RBAC middleware (owner/admin/member/viewer)
- [ ] Household member management (list, remove, change role)
- [ ] Connect Flutter app: replace mock UserService, HomeSelectionProvider

### Sprint 5–6 (Weeks 9–12): Assets + Warranties + Documents
- [ ] Asset CRUD scoped to household
- [ ] Asset categories + subcategories seed data
- [ ] Asset document upload (S3 integration)
- [ ] Warranty management (create, update, check expiry)
- [ ] Asset health score engine (initial implementation)
- [ ] Connect Flutter app: replace mock assets, warranty screens

### Sprint 7–8 (Weeks 13–16): Maintenance Engine
- [ ] Maintenance templates per asset subcategory
- [ ] Reminder generation engine (auto-create on asset add)
- [ ] Reminder actions: complete, skip, snooze
- [ ] Maintenance records history
- [ ] Health score recomputation on maintenance events
- [ ] Daily cron: overdue reminders, health alerts
- [ ] Connect Flutter app: replace mock maintenance data

### Sprint 9–10 (Weeks 17–20): Claims
- [ ] Claims CRUD with status lifecycle
- [ ] Claim status history table + transitions
- [ ] Auto-coverage check (warranty + protection plan)
- [ ] Claim document upload
- [ ] Claim notifications on status change
- [ ] Connect Flutter app: replace ClaimsService

### Sprint 11–12 (Weeks 21–24): Service Bookings
- [ ] Service categories seed data (all 9 categories)
- [ ] Service provider management
- [ ] Booking creation (all 9 category types with JSONB details)
- [ ] Booking status lifecycle (scheduled → confirmed → in_progress → completed)
- [ ] Booking cancel, reschedule
- [ ] Technician assignment
- [ ] Connect Flutter app: replace BookingService

### Sprint 13–14 (Weeks 25–28): Shopping + Orders + Payments
- [ ] Product catalog (CRUD, search, filter)
- [ ] Shopping cart (if server-side)
- [ ] Order creation (purchase, upgrade, parts)
- [ ] Trade-in flow (estimate → approve → credit)
- [ ] Stripe integration (payment intents, payment methods)
- [ ] Installment plans
- [ ] Order status tracking
- [ ] Stripe webhooks (payment success/fail)
- [ ] Connect Flutter app: replace OrderService, checkout flows

### Sprint 15–16 (Weeks 29–32): Protection Plans
- [ ] Plan templates (Essential/Premium/Ultimate)
- [ ] Plan purchase flow (one-time, monthly, yearly)
- [ ] Stripe subscriptions for recurring billing
- [ ] Plan assignment to assets
- [ ] Auto-renewal handling
- [ ] Coverage verification for claims
- [ ] Connect Flutter app: replace ProtectionPlanService

### Sprint 17–18 (Weeks 33–36): AI Services
- [ ] OpenAI proxy (brand lookup, subcategory lookup)
- [ ] AI brand lookup caching (Redis, 24h TTL)
- [ ] DALL-E nameplate wireframe generation proxy
- [ ] AI issue analysis endpoint
- [ ] AI DIY troubleshooting generation endpoint
- [ ] AI DIY maintenance steps endpoint
- [ ] AI usage tracking (ai_sessions table)
- [ ] Rate limiting (10 AI requests/user/hour)
- [ ] Connect Flutter app: migrate ChatGPTService to backend proxy

### Sprint 19–20 (Weeks 37–40): Notifications + Alerts
- [ ] Push notification service (FCM)
- [ ] Email notification service (SES templates)
- [ ] SMS notification service (Twilio)
- [ ] In-app notification CRUD (list, mark read, mark all read)
- [ ] Notification preference management
- [ ] Alert engine (daily cron: warranty expiry, health score, maintenance overdue, safety)
- [ ] Critical alerts CRUD
- [ ] Connect Flutter app: replace mock notifications/alerts

### Sprint 21–22 (Weeks 41–44): Polish + Performance + Testing
- [ ] Load testing (k6 or Artillery) — target 10K concurrent users
- [ ] Database query optimization (EXPLAIN ANALYZE, add missing indexes)
- [ ] API response time optimization (<200ms p95)
- [ ] Integration test suite (all endpoints)
- [ ] Security audit (OWASP Top 10)
- [ ] Documentation (API docs with Swagger/OpenAPI)
- [ ] Monitoring setup (Datadog/Grafana dashboards)
- [ ] Error tracking setup (Sentry)

---

## Quick Reference: ID Patterns

| Entity | Pattern | Example |
|--------|---------|---------|
| User ID | UUID v4 | `a1b2c3d4-e5f6-...` |
| Household ID | UUID v4 | `h1h2h3h4-h5h6-...` |
| Asset ID | UUID v4 | `as1as2as-as3a-...` |
| Booking Number | `HQyyyy-MMDD-nnnn` | `HQ2026-0223-0001` |
| Claim Number | `CLM-yyyy-nnnn` | `CLM-2026-0001` |
| Order Number | `HQ-ORD-yyyy-nnnn` | `HQ-ORD-2026-0001` |

## Quick Reference: All Enums

```
ClaimStatus:    submitted | underReview | approved | inProgress | resolved | denied | closed
ClaimType:      repair | replacement | maintenance
OrderStatus:    placed | processing | shipped | outForDelivery | delivered | installed | completed | canceled
OrderType:      purchase | upgrade_trade_in | parts
TradeInStatus:  pending | scheduled | pickedUp | inspected | credited
TradeInCond:    excellent | good | fair | poor
BookingStatus:  pending | confirmed | technicianAssigned | technicianOnWay | inProgress | completed | canceled | rescheduled
PaymentStatus:  pending | processing | succeeded | failed | canceled | refunded
PaymentMode:    payNow | payOnVisit
PaymentMethod:  creditCard | debitCard | applePay | googlePay | bankTransfer
MemberRole:     owner | admin | member | viewer
MemberStatus:   active | pending | removed
AlertSeverity:  critical | warning | info
AlertCategory:  warranty | service | maintenance | safety
ReminderStatus: upcoming | overdue | snoozed | completed | skipped
ReminderPriority: low | medium | high
MaintenanceFreq: monthly | quarterly | biAnnual | annual | seasonal | usageBased
MaintenanceCat:  cleaning | inspection | replacement | service
SkipReason:     dontKnowHow | notNeeded | willDoLater
AssetCategory:  appliances | homeSystems | electronics
UserStatus:     active | suspended | deleted
PropertyType:   house | apartment | condo | townhouse
```
