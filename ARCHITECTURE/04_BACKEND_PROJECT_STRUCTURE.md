# HomeIQ — Backend Project Structure & Code Scaffolding

> **Runtime**: Node.js 20 LTS  
> **Framework**: Fastify 4  
> **Language**: TypeScript 5.4+  
> **ORM**: Prisma 5  
> **Queue**: BullMQ  
> **Package Manager**: npm  

---

## 1. Project Structure

```
homeiq-backend/
├── .github/
│   └── workflows/
│       ├── deploy.yml                    # Main CI/CD pipeline
│       └── migrate.yml                   # Database migration workflow
├── prisma/
│   ├── schema.prisma                     # Prisma schema (source of truth)
│   ├── migrations/                       # Auto-generated migrations
│   └── seed.ts                           # Seed data script
├── src/
│   ├── server.ts                         # App entry point
│   ├── app.ts                            # Fastify app factory
│   ├── worker.ts                         # BullMQ worker entry point
│   │
│   ├── config/
│   │   ├── env.ts                        # Environment variable validation (zod)
│   │   ├── database.ts                   # Prisma client singleton
│   │   ├── redis.ts                      # Redis client singleton
│   │   ├── logger.ts                     # Pino logger configuration
│   │   └── stripe.ts                     # Stripe client initialization
│   │
│   ├── plugins/
│   │   ├── auth.ts                       # JWT auth plugin (decorates request)
│   │   ├── cors.ts                       # CORS plugin
│   │   ├── rate-limit.ts                 # Rate limiting plugin
│   │   ├── error-handler.ts              # Global error handler
│   │   ├── request-context.ts            # Request ID, timing, platform
│   │   └── swagger.ts                    # OpenAPI/Swagger docs
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.routes.ts            # POST /auth/signup, signin, etc.
│   │   │   ├── auth.controller.ts        # Request handlers
│   │   │   ├── auth.service.ts           # Business logic
│   │   │   ├── auth.schema.ts            # Zod request/response schemas
│   │   │   ├── auth.types.ts             # TypeScript interfaces
│   │   │   ├── strategies/
│   │   │   │   ├── email.strategy.ts     # Email/password auth
│   │   │   │   ├── google.strategy.ts    # Google OAuth
│   │   │   │   └── apple.strategy.ts     # Apple Sign In
│   │   │   └── __tests__/
│   │   │       ├── auth.service.test.ts
│   │   │       └── auth.routes.test.ts
│   │   │
│   │   ├── users/
│   │   │   ├── users.routes.ts
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── users.schema.ts
│   │   │   └── __tests__/
│   │   │
│   │   ├── households/
│   │   │   ├── households.routes.ts
│   │   │   ├── households.controller.ts
│   │   │   ├── households.service.ts
│   │   │   ├── households.schema.ts
│   │   │   ├── members.service.ts        # Member management
│   │   │   ├── invites.service.ts        # Invite logic
│   │   │   └── __tests__/
│   │   │
│   │   ├── assets/
│   │   │   ├── assets.routes.ts
│   │   │   ├── assets.controller.ts
│   │   │   ├── assets.service.ts
│   │   │   ├── assets.schema.ts
│   │   │   ├── documents.service.ts      # Asset document management
│   │   │   ├── warranties.service.ts     # Warranty CRUD
│   │   │   └── __tests__/
│   │   │
│   │   ├── maintenance/
│   │   │   ├── maintenance.routes.ts
│   │   │   ├── maintenance.controller.ts
│   │   │   ├── reminders.service.ts      # Reminder CRUD + scheduling
│   │   │   ├── records.service.ts        # Completion records
│   │   │   ├── maintenance.schema.ts
│   │   │   └── __tests__/
│   │   │
│   │   ├── health/
│   │   │   ├── health.routes.ts          # /health + /health/ready
│   │   │   ├── health-score.service.ts   # Asset health scoring engine
│   │   │   ├── health-score.calculator.ts # Score computation logic
│   │   │   └── __tests__/
│   │   │
│   │   ├── claims/
│   │   │   ├── claims.routes.ts
│   │   │   ├── claims.controller.ts
│   │   │   ├── claims.service.ts
│   │   │   ├── claims.schema.ts
│   │   │   └── __tests__/
│   │   │
│   │   ├── bookings/
│   │   │   ├── bookings.routes.ts
│   │   │   ├── bookings.controller.ts
│   │   │   ├── bookings.service.ts
│   │   │   ├── bookings.schema.ts
│   │   │   ├── pricing.service.ts        # Dynamic pricing calculator
│   │   │   └── __tests__/
│   │   │
│   │   ├── orders/
│   │   │   ├── orders.routes.ts
│   │   │   ├── orders.controller.ts
│   │   │   ├── orders.service.ts
│   │   │   ├── orders.schema.ts
│   │   │   ├── trade-in.service.ts       # Trade-in valuation
│   │   │   └── __tests__/
│   │   │
│   │   ├── products/
│   │   │   ├── products.routes.ts
│   │   │   ├── products.controller.ts
│   │   │   ├── products.service.ts
│   │   │   ├── products.schema.ts
│   │   │   └── __tests__/
│   │   │
│   │   ├── plans/
│   │   │   ├── plans.routes.ts
│   │   │   ├── plans.controller.ts
│   │   │   ├── plans.service.ts          # Protection plan management
│   │   │   ├── plans.schema.ts
│   │   │   └── __tests__/
│   │   │
│   │   ├── payments/
│   │   │   ├── payments.routes.ts
│   │   │   ├── payments.controller.ts
│   │   │   ├── payments.service.ts
│   │   │   ├── payments.schema.ts
│   │   │   ├── stripe.webhook.ts         # Stripe webhook handler
│   │   │   ├── installments.service.ts   # Installment plan logic
│   │   │   └── __tests__/
│   │   │
│   │   ├── notifications/
│   │   │   ├── notifications.routes.ts
│   │   │   ├── notifications.controller.ts
│   │   │   ├── notifications.service.ts
│   │   │   ├── notifications.schema.ts
│   │   │   └── __tests__/
│   │   │
│   │   ├── alerts/
│   │   │   ├── alerts.routes.ts
│   │   │   ├── alerts.controller.ts
│   │   │   ├── alerts.service.ts         # Alert engine (warranty/maintenance/health)
│   │   │   ├── alerts.schema.ts
│   │   │   └── __tests__/
│   │   │
│   │   ├── ai/
│   │   │   ├── ai.routes.ts
│   │   │   ├── ai.controller.ts
│   │   │   ├── ai.service.ts            # OpenAI proxy (GPT + DALL-E)
│   │   │   ├── ai.schema.ts
│   │   │   ├── prompts/
│   │   │   │   ├── brand-lookup.prompt.ts
│   │   │   │   ├── subcategory.prompt.ts
│   │   │   │   ├── nameplate.prompt.ts
│   │   │   │   ├── issue-analysis.prompt.ts
│   │   │   │   └── diy-steps.prompt.ts
│   │   │   └── __tests__/
│   │   │
│   │   └── uploads/
│   │       ├── uploads.routes.ts
│   │       ├── uploads.controller.ts
│   │       ├── uploads.service.ts        # S3 upload + presigned URLs
│   │       └── __tests__/
│   │
│   ├── jobs/
│   │   ├── queues.ts                     # BullMQ queue definitions
│   │   ├── processors/
│   │   │   ├── email.processor.ts        # Send emails via SES
│   │   │   ├── push.processor.ts         # Send push via FCM
│   │   │   ├── sms.processor.ts          # Send SMS via Twilio
│   │   │   ├── health-score.processor.ts # Recompute health scores
│   │   │   ├── maintenance.processor.ts  # Generate reminders from templates
│   │   │   ├── ai.processor.ts           # Async AI calls
│   │   │   └── cleanup.processor.ts      # Data cleanup jobs
│   │   └── schedulers/
│   │       ├── daily.scheduler.ts        # Runs every day at 2 AM UTC
│   │       ├── weekly.scheduler.ts       # Runs every Monday
│   │       └── monthly.scheduler.ts      # Runs 1st of month
│   │
│   ├── middleware/
│   │   ├── authenticate.ts              # JWT verification middleware
│   │   ├── authorize.ts                 # RBAC role check
│   │   ├── household-access.ts          # Verify user belongs to household
│   │   └── validate.ts                  # Zod schema validator
│   │
│   ├── shared/
│   │   ├── errors/
│   │   │   ├── app-error.ts             # Custom error classes
│   │   │   ├── not-found.error.ts
│   │   │   ├── unauthorized.error.ts
│   │   │   ├── forbidden.error.ts
│   │   │   └── validation.error.ts
│   │   ├── utils/
│   │   │   ├── pagination.ts            # Pagination helper
│   │   │   ├── hash.ts                  # bcrypt wrapper
│   │   │   ├── token.ts                 # JWT sign/verify helpers
│   │   │   ├── otp.ts                   # OTP generation (6-digit)
│   │   │   ├── id-generator.ts          # Sequential ID generator
│   │   │   └── date.ts                  # Date formatting utils
│   │   ├── types/
│   │   │   ├── fastify.d.ts             # Fastify type augmentations
│   │   │   ├── common.ts                # Shared types
│   │   │   └── enums.ts                 # Shared enums
│   │   └── constants/
│   │       ├── redis-keys.ts            # Redis key patterns
│   │       └── defaults.ts              # Default values
│   │
│   └── integrations/
│       ├── openai/
│       │   ├── client.ts                # OpenAI SDK wrapper
│       │   └── rate-limiter.ts          # Per-user AI rate limiting
│       ├── stripe/
│       │   ├── client.ts                # Stripe SDK wrapper
│       │   └── events.ts               # Webhook event handlers
│       ├── aws/
│       │   ├── s3.ts                    # S3 client (upload, presign, delete)
│       │   ├── ses.ts                   # SES email sender
│       │   └── cloudwatch.ts           # Custom metrics publisher
│       └── firebase/
│           └── fcm.ts                   # Firebase Cloud Messaging
│
├── tests/
│   ├── setup.ts                          # Test setup (database, redis)
│   ├── helpers/
│   │   ├── auth.helper.ts               # Create test users with tokens
│   │   ├── factory.ts                   # Test data factories
│   │   └── database.helper.ts           # Database cleanup between tests
│   └── integration/
│       ├── auth.integration.test.ts
│       ├── assets.integration.test.ts
│       ├── bookings.integration.test.ts
│       └── claims.integration.test.ts
│
├── docker-compose.yml                    # Local development stack
├── Dockerfile                            # Production Docker image
├── .env.example                          # Environment variable template
├── .eslintrc.json                        # ESLint config
├── .prettierrc                           # Prettier config
├── tsconfig.json                         # TypeScript config
├── vitest.config.ts                      # Vitest test runner config
├── package.json                          # Dependencies
└── README.md                             # Getting started guide
```

---

## 2. package.json

```json
{
  "name": "homeiq-backend",
  "version": "1.0.0",
  "description": "HomeIQ API Server — Home asset management platform",
  "main": "dist/server.js",
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "dev:worker": "tsx watch src/worker.ts",
    "build": "tsc -p tsconfig.json",
    "start": "node dist/server.js",
    "start:worker": "node dist/worker.js",
    "lint": "eslint src/ --ext .ts",
    "lint:fix": "eslint src/ --ext .ts --fix",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:integration": "vitest run --config vitest.integration.config.ts",
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev",
    "db:migrate:deploy": "prisma migrate deploy",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio",
    "db:reset": "prisma migrate reset --force",
    "docker:up": "docker compose up -d",
    "docker:down": "docker compose down",
    "docker:logs": "docker compose logs -f"
  },
  "dependencies": {
    "@fastify/cors": "^9.0.0",
    "@fastify/helmet": "^11.0.0",
    "@fastify/multipart": "^8.0.0",
    "@fastify/rate-limit": "^9.0.0",
    "@fastify/swagger": "^8.0.0",
    "@fastify/swagger-ui": "^3.0.0",
    "@prisma/client": "^5.15.0",
    "@aws-sdk/client-s3": "^3.600.0",
    "@aws-sdk/client-ses": "^3.600.0",
    "@aws-sdk/s3-request-presigner": "^3.600.0",
    "bcryptjs": "^2.4.3",
    "bullmq": "^5.8.0",
    "fastify": "^4.28.0",
    "firebase-admin": "^12.2.0",
    "ioredis": "^5.4.0",
    "jsonwebtoken": "^9.0.2",
    "openai": "^4.50.0",
    "pino": "^9.2.0",
    "pino-pretty": "^11.2.0",
    "stripe": "^15.8.0",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/jsonwebtoken": "^9.0.6",
    "@types/node": "^20.14.0",
    "@typescript-eslint/eslint-plugin": "^7.13.0",
    "@typescript-eslint/parser": "^7.13.0",
    "@vitest/coverage-v8": "^1.6.0",
    "eslint": "^8.57.0",
    "prisma": "^5.15.0",
    "tsx": "^4.15.0",
    "typescript": "^5.5.0",
    "vitest": "^1.6.0"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
```

---

## 3. Core Files (Starter Code)

### src/config/env.ts — Environment Validation
```typescript
import { z } from 'zod';

const envSchema = z.object({
  // Server
  NODE_ENV: z.enum(['development', 'staging', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default('0.0.0.0'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),

  // Database
  DATABASE_URL: z.string().url(),
  DATABASE_READ_REPLICA_URL: z.string().url().optional(),

  // Redis
  REDIS_URL: z.string(),
  REDIS_KEY_PREFIX: z.string().default('hiq:'),

  // JWT
  JWT_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRY: z.string().default('15m'),
  JWT_REFRESH_EXPIRY: z.string().default('30d'),

  // OAuth
  GOOGLE_CLIENT_ID: z.string().optional(),
  APPLE_CLIENT_ID: z.string().optional(),
  APPLE_TEAM_ID: z.string().optional(),
  APPLE_KEY_ID: z.string().optional(),

  // Stripe
  STRIPE_SECRET_KEY: z.string(),
  STRIPE_WEBHOOK_SECRET: z.string(),

  // OpenAI
  OPENAI_API_KEY: z.string(),
  OPENAI_MODEL: z.string().default('gpt-4o-mini'),
  OPENAI_MAX_TOKENS: z.coerce.number().default(2000),

  // AWS
  AWS_REGION: z.string().default('us-east-1'),
  S3_BUCKET: z.string(),
  S3_CDN_URL: z.string().url().optional(),
  SES_FROM_EMAIL: z.string().email(),

  // Firebase
  FCM_PROJECT_ID: z.string().optional(),

  // App
  APP_URL: z.string().url().default('http://localhost:3000'),
  CORS_ORIGINS: z.string().default('http://localhost:3000'),

  // Rate Limits
  RATE_LIMIT_GENERAL: z.coerce.number().default(200),
  RATE_LIMIT_AUTH: z.coerce.number().default(5),
  RATE_LIMIT_AI: z.coerce.number().default(10),
});

export type Env = z.infer<typeof envSchema>;

function validateEnv(): Env {
  const result = envSchema.safeParse(process.env);

  if (!result.success) {
    console.error('❌ Invalid environment variables:');
    console.error(result.error.flatten().fieldErrors);
    process.exit(1);
  }

  return result.data;
}

export const env = validateEnv();
```

### src/app.ts — Fastify App Factory
```typescript
import Fastify, { FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import multipart from '@fastify/multipart';
import { env } from './config/env';
import { logger } from './config/logger';
import { prisma } from './config/database';
import { redis } from './config/redis';
import { errorHandler } from './plugins/error-handler';
import { requestContext } from './plugins/request-context';

// Module routes
import { authRoutes } from './modules/auth/auth.routes';
import { userRoutes } from './modules/users/users.routes';
import { householdRoutes } from './modules/households/households.routes';
import { assetRoutes } from './modules/assets/assets.routes';
import { maintenanceRoutes } from './modules/maintenance/maintenance.routes';
import { healthRoutes } from './modules/health/health.routes';
import { claimRoutes } from './modules/claims/claims.routes';
import { bookingRoutes } from './modules/bookings/bookings.routes';
import { orderRoutes } from './modules/orders/orders.routes';
import { productRoutes } from './modules/products/products.routes';
import { planRoutes } from './modules/plans/plans.routes';
import { paymentRoutes } from './modules/payments/payments.routes';
import { notificationRoutes } from './modules/notifications/notifications.routes';
import { alertRoutes } from './modules/alerts/alerts.routes';
import { aiRoutes } from './modules/ai/ai.routes';
import { uploadRoutes } from './modules/uploads/uploads.routes';

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger,
    requestIdHeader: 'x-request-id',
    genReqId: () => crypto.randomUUID(),
  });

  // ─── Decorate with shared instances ───
  app.decorate('prisma', prisma);
  app.decorate('redis', redis);

  // ─── Plugins ───
  await app.register(helmet);
  await app.register(cors, {
    origin: env.CORS_ORIGINS.split(','),
    credentials: true,
  });
  await app.register(rateLimit, {
    max: env.RATE_LIMIT_GENERAL,
    timeWindow: '1 minute',
    redis,
  });
  await app.register(multipart, {
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  });
  await app.register(requestContext);
  app.setErrorHandler(errorHandler);

  // ─── Routes ───
  await app.register(healthRoutes);                                        // /health
  await app.register(authRoutes,         { prefix: '/v1/auth' });
  await app.register(userRoutes,         { prefix: '/v1/users' });
  await app.register(householdRoutes,    { prefix: '/v1/households' });
  await app.register(assetRoutes,        { prefix: '/v1' });               // /v1/households/:hid/assets + /v1/assets/:id
  await app.register(maintenanceRoutes,  { prefix: '/v1' });
  await app.register(claimRoutes,        { prefix: '/v1/claims' });
  await app.register(bookingRoutes,      { prefix: '/v1/bookings' });
  await app.register(orderRoutes,        { prefix: '/v1/orders' });
  await app.register(productRoutes,      { prefix: '/v1/products' });
  await app.register(planRoutes,         { prefix: '/v1/plans' });
  await app.register(paymentRoutes,      { prefix: '/v1' });
  await app.register(notificationRoutes, { prefix: '/v1/notifications' });
  await app.register(alertRoutes,        { prefix: '/v1/alerts' });
  await app.register(aiRoutes,           { prefix: '/v1/ai' });
  await app.register(uploadRoutes,       { prefix: '/v1/uploads' });

  // ─── Graceful Shutdown ───
  app.addHook('onClose', async () => {
    await prisma.$disconnect();
    redis.disconnect();
  });

  return app;
}
```

### src/server.ts — Entry Point
```typescript
import { buildApp } from './app';
import { env } from './config/env';

async function main() {
  const app = await buildApp();

  try {
    await app.listen({ port: env.PORT, host: env.HOST });
    app.log.info(`🚀 HomeIQ API running on ${env.HOST}:${env.PORT}`);
    app.log.info(`📝 Environment: ${env.NODE_ENV}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }

  // Handle graceful shutdown
  const signals = ['SIGINT', 'SIGTERM'] as const;
  for (const signal of signals) {
    process.on(signal, async () => {
      app.log.info(`Received ${signal}, shutting down gracefully...`);
      await app.close();
      process.exit(0);
    });
  }
}

main();
```

### src/worker.ts — BullMQ Worker Entry Point
```typescript
import { env } from './config/env';
import { logger } from './config/logger';
import { redis } from './config/redis';
import { registerAllProcessors } from './jobs/queues';

async function main() {
  logger.info('🔧 Starting HomeIQ background worker...');
  logger.info(`📝 Environment: ${env.NODE_ENV}`);

  const workers = await registerAllProcessors(redis);

  logger.info(`✅ ${workers.length} job processors registered`);

  // Graceful shutdown
  const signals = ['SIGINT', 'SIGTERM'] as const;
  for (const signal of signals) {
    process.on(signal, async () => {
      logger.info(`Received ${signal}, shutting down worker...`);
      await Promise.all(workers.map((w) => w.close()));
      redis.disconnect();
      process.exit(0);
    });
  }
}

main();
```

### src/config/database.ts — Prisma Client
```typescript
import { PrismaClient } from '@prisma/client';
import { env } from './env';

export const prisma = new PrismaClient({
  datasources: {
    db: { url: env.DATABASE_URL },
  },
  log:
    env.NODE_ENV === 'development'
      ? ['query', 'info', 'warn', 'error']
      : ['warn', 'error'],
});
```

### src/config/redis.ts — Redis Client
```typescript
import Redis from 'ioredis';
import { env } from './env';

export const redis = new Redis(env.REDIS_URL, {
  keyPrefix: env.REDIS_KEY_PREFIX,
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => {
    if (times > 10) return null; // Stop retrying
    return Math.min(times * 100, 3000);
  },
});

redis.on('error', (err) => {
  console.error('Redis connection error:', err.message);
});

redis.on('connect', () => {
  console.log('✅ Redis connected');
});
```

### src/middleware/authenticate.ts — JWT Auth Middleware
```typescript
import { FastifyRequest, FastifyReply } from 'fastify';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { UnauthorizedError } from '../shared/errors/unauthorized.error';

export interface JWTPayload {
  userId: string;
  email: string;
  iat: number;
  exp: number;
}

export async function authenticate(
  request: FastifyRequest,
  reply: FastifyReply,
) {
  const authHeader = request.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    throw new UnauthorizedError('Missing or invalid authorization header');
  }

  const token = authHeader.substring(7);

  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as JWTPayload;
    request.user = {
      userId: payload.userId,
      email: payload.email,
    };
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      throw new UnauthorizedError('Token expired');
    }
    throw new UnauthorizedError('Invalid token');
  }
}
```

### src/middleware/authorize.ts — RBAC Middleware
```typescript
import { FastifyRequest, FastifyReply } from 'fastify';
import { ForbiddenError } from '../shared/errors/forbidden.error';
import { prisma } from '../config/database';

type HouseholdRole = 'owner' | 'admin' | 'member' | 'viewer';

const ROLE_HIERARCHY: Record<HouseholdRole, number> = {
  owner: 4,
  admin: 3,
  member: 2,
  viewer: 1,
};

/**
 * Factory: creates middleware that checks if user has
 * at least the minimum required role for this household.
 */
export function requireRole(minRole: HouseholdRole) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = request.user;
    const householdId =
      (request.params as any).hid || (request.params as any).id;

    if (!householdId) {
      throw new ForbiddenError('Household ID required');
    }

    const membership = await prisma.householdMember.findFirst({
      where: {
        user_id: userId,
        household_id: householdId,
        status: 'active',
      },
    });

    if (!membership) {
      throw new ForbiddenError('You are not a member of this household');
    }

    const userLevel = ROLE_HIERARCHY[membership.role as HouseholdRole] || 0;
    const requiredLevel = ROLE_HIERARCHY[minRole];

    if (userLevel < requiredLevel) {
      throw new ForbiddenError(
        `Requires ${minRole} role. You have ${membership.role}.`,
      );
    }

    // Attach role to request for downstream use
    request.householdRole = membership.role as HouseholdRole;
  };
}
```

### src/plugins/error-handler.ts — Global Error Handler
```typescript
import { FastifyError, FastifyReply, FastifyRequest } from 'fastify';
import { ZodError } from 'zod';
import { AppError } from '../shared/errors/app-error';

export function errorHandler(
  error: FastifyError | Error,
  request: FastifyRequest,
  reply: FastifyReply,
) {
  // Known app errors
  if (error instanceof AppError) {
    return reply.status(error.statusCode).send({
      success: false,
      error: {
        code: error.code,
        message: error.message,
        details: error.details,
      },
    });
  }

  // Zod validation errors
  if (error instanceof ZodError) {
    return reply.status(400).send({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request data',
        details: error.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        })),
      },
    });
  }

  // Fastify validation errors
  if ('validation' in error && error.validation) {
    return reply.status(400).send({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: error.message,
      },
    });
  }

  // Rate limit errors
  if (error.statusCode === 429) {
    return reply.status(429).send({
      success: false,
      error: {
        code: 'RATE_LIMITED',
        message: 'Too many requests. Please try again later.',
      },
    });
  }

  // Unknown errors
  request.log.error(error);
  return reply.status(500).send({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message:
        process.env.NODE_ENV === 'production'
          ? 'An unexpected error occurred'
          : error.message,
    },
  });
}
```

### src/shared/errors/app-error.ts — Base Error Class
```typescript
export class AppError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public code: string,
    public details?: any,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    super(
      id ? `${resource} with ID ${id} not found` : `${resource} not found`,
      404,
      'NOT_FOUND',
    );
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(message, 409, 'CONFLICT');
  }
}
```

### src/shared/utils/pagination.ts — Pagination Helper
```typescript
import { z } from 'zod';

export const paginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
  sortBy: z.string().optional(),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

export type PaginationParams = z.infer<typeof paginationSchema>;

export function paginate(params: PaginationParams) {
  const { page, pageSize } = params;
  return {
    skip: (page - 1) * pageSize,
    take: pageSize,
  };
}

export function buildMeta(
  params: PaginationParams,
  totalItems: number,
) {
  return {
    page: params.page,
    pageSize: params.pageSize,
    totalItems,
    totalPages: Math.ceil(totalItems / params.pageSize),
  };
}
```

### src/shared/constants/redis-keys.ts
```typescript
/**
 * Redis key patterns for the HomeIQ cache layer.
 * All keys are auto-prefixed with "hiq:" by ioredis keyPrefix.
 */
export const REDIS_KEYS = {
  // Sessions
  session: (userId: string) => `session:${userId}`,
  refreshToken: (token: string) => `refresh:${token}`,

  // OTP
  otp: (identifier: string) => `otp:${identifier}`,
  otpAttempts: (identifier: string) => `otp:attempts:${identifier}`,

  // Rate limiting
  rateLimit: (userId: string, action: string) => `rl:${userId}:${action}`,

  // Cache
  userProfile: (userId: string) => `cache:user:${userId}`,
  householdSummary: (hid: string) => `cache:household:${hid}:summary`,
  assetDetail: (assetId: string) => `cache:asset:${assetId}`,
  healthScore: (assetId: string) => `cache:health:${assetId}`,
  maintenanceSummary: (hid: string) => `cache:maintenance:${hid}`,

  // AI Cache
  brandLookup: (assetType: string) => `ai:brands:${assetType.toLowerCase()}`,
  subcategoryLookup: (assetType: string) => `ai:subcats:${assetType.toLowerCase()}`,
  nameplateGuide: (brand: string, model: string) =>
    `ai:nameplate:${brand.toLowerCase()}:${model.toLowerCase()}`,

  // Feature data
  assetCategories: () => 'ref:categories',
  serviceCategories: () => 'ref:services',
  planTemplates: () => 'ref:plans',

  // Notification badge
  unreadCount: (userId: string) => `notify:unread:${userId}`,
} as const;

export const REDIS_TTL = {
  SESSION: 15 * 60,           // 15 minutes (matches JWT access token)
  REFRESH_TOKEN: 30 * 24 * 3600, // 30 days
  OTP: 5 * 60,                // 5 minutes
  OTP_ATTEMPTS: 15 * 60,      // 15 minutes lockout

  USER_PROFILE: 30 * 60,      // 30 minutes
  HOUSEHOLD_SUMMARY: 10 * 60, // 10 minutes
  ASSET_DETAIL: 15 * 60,      // 15 minutes
  HEALTH_SCORE: 60 * 60,      // 1 hour

  AI_BRANDS: 24 * 3600,       // 24 hours
  AI_SUBCATS: 24 * 3600,      // 24 hours
  AI_NAMEPLATE: 7 * 24 * 3600, // 7 days

  REF_DATA: 12 * 3600,        // 12 hours (categories, services, plans)
  UNREAD_COUNT: 5 * 60,       // 5 minutes
} as const;
```

### src/modules/auth/auth.schema.ts — Example Zod Schemas
```typescript
import { z } from 'zod';

export const signupSchema = z.object({
  full_name: z.string().min(2).max(100),
  email: z.string().email().optional(),
  phone: z
    .string()
    .regex(/^\+1\d{10}$/, 'Must be a valid US phone number (+1XXXXXXXXXX)')
    .optional(),
  password: z
    .string()
    .min(8)
    .regex(/[A-Z]/, 'Must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Must contain at least one number')
    .regex(/[^A-Za-z0-9]/, 'Must contain at least one special character')
    .optional(),
}).refine(
  (data) => data.email || data.phone,
  { message: 'Either email or phone is required' },
);

export const signinSchema = z.object({
  email_or_phone: z.string().min(1),
  password: z.string().optional(),
});

export const otpSendSchema = z.object({
  identifier: z.string().min(1),
  type: z.enum(['sms', 'email']),
});

export const otpVerifySchema = z.object({
  identifier: z.string().min(1),
  code: z.string().length(6),
  type: z.enum(['sms', 'email']),
});

export const googleAuthSchema = z.object({
  id_token: z.string().min(1),
});

export const appleAuthSchema = z.object({
  identity_token: z.string().min(1),
  authorization_code: z.string().min(1),
  user_identifier: z.string().optional(),
  full_name: z.string().optional(),
  email: z.string().email().optional(),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(1),
});

export type SignupInput = z.infer<typeof signupSchema>;
export type SigninInput = z.infer<typeof signinSchema>;
export type OTPSendInput = z.infer<typeof otpSendSchema>;
export type OTPVerifyInput = z.infer<typeof otpVerifySchema>;
```

### src/modules/auth/auth.routes.ts — Example Route File
```typescript
import { FastifyInstance } from 'fastify';
import { AuthController } from './auth.controller';
import { authenticate } from '../../middleware/authenticate';

export async function authRoutes(app: FastifyInstance) {
  const controller = new AuthController();

  // Public routes
  app.post('/signup',      controller.signup);
  app.post('/signin',      controller.signin);
  app.post('/otp/send',    controller.sendOTP);
  app.post('/otp/verify',  controller.verifyOTP);
  app.post('/google',      controller.googleAuth);
  app.post('/apple',       controller.appleAuth);
  app.post('/refresh',     controller.refreshToken);

  // Authenticated routes
  app.post('/logout', { preHandler: [authenticate] }, controller.logout);
}
```

---

## 4. tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "paths": {
      "@config/*": ["./src/config/*"],
      "@modules/*": ["./src/modules/*"],
      "@shared/*": ["./src/shared/*"],
      "@middleware/*": ["./src/middleware/*"],
      "@jobs/*": ["./src/jobs/*"],
      "@integrations/*": ["./src/integrations/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

---

## 5. vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./tests/setup.ts'],
    include: ['src/**/__tests__/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.ts'],
      exclude: [
        'src/**/__tests__/**',
        'src/**/*.d.ts',
        'src/config/logger.ts',
      ],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
  },
  resolve: {
    alias: {
      '@config': path.resolve(__dirname, './src/config'),
      '@modules': path.resolve(__dirname, './src/modules'),
      '@shared': path.resolve(__dirname, './src/shared'),
      '@middleware': path.resolve(__dirname, './src/middleware'),
      '@jobs': path.resolve(__dirname, './src/jobs'),
      '@integrations': path.resolve(__dirname, './src/integrations'),
    },
  },
});
```

---

## 6. .env.example

```bash
# ─── Server ───
NODE_ENV=development
PORT=3000
HOST=0.0.0.0
LOG_LEVEL=debug

# ─── Database ───
DATABASE_URL=postgresql://homeiq_dev:dev_password@localhost:5432/homeiq

# ─── Redis ───
REDIS_URL=redis://localhost:6379
REDIS_KEY_PREFIX=hiq:

# ─── JWT ───
JWT_SECRET=change-this-to-a-random-64-char-string-in-production-please
JWT_REFRESH_SECRET=change-this-to-another-random-64-char-string-in-production
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=30d

# ─── Stripe ───
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# ─── OpenAI ───
OPENAI_API_KEY=sk-xxx
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=2000

# ─── AWS ───
AWS_REGION=us-east-1
S3_BUCKET=homeiq-uploads-dev
SES_FROM_EMAIL=noreply@homeiq.com

# ─── App ───
APP_URL=http://localhost:3000
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

---

## 7. Getting Started (Developer Onboarding)

```bash
# 1. Clone and install
git clone git@github.com:301io/homeiq-backend.git
cd homeiq-backend
npm install

# 2. Copy env
cp .env.example .env
# Edit .env with your API keys

# 3. Start local infrastructure
docker compose up -d postgres redis

# 4. Run database migrations
npx prisma migrate dev

# 5. Seed database
npm run db:seed

# 6. Start API server (with hot reload)
npm run dev

# 7. Start background worker (separate terminal)
npm run dev:worker

# 8. Run tests
npm run test

# 9. Open Prisma Studio (database viewer)
npm run db:studio
```

API will be available at `http://localhost:3000`  
Health check: `http://localhost:3000/health`
