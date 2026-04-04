# HomeIQ — Complete System Architecture Review & Design

> **Reviewer**: Senior Software Architect  
> **Date**: February 23, 2026  
> **Scope**: Full-stack architecture for 200M+ US users  
> **Verdict**: Ambitious UI prototype with strong scaffolding. Zero production readiness today.

---

## PART 1: PROJECT ANALYSIS — WHAT I FOUND

---

### 1. What Is This Project?

HomeIQ (branded as SquareTrade / Allstate Protection Plans) is a **home asset lifecycle management platform**. Think of it as **"Carfax + AppleCare + TaskRabbit for your home."**

A homeowner registers their appliances, electronics, and home systems. The app then:
- Tracks every asset's warranty, health, and maintenance schedule
- Sells tiered protection plans (Essential / Premium / Ultimate)
- Provides AI-powered troubleshooting (diagnose → DIY → parts order → technician)
- Offers 9 categories of home services (assembly, mounting, moving, cleaning, outdoor, repairs, painting, security, lifestyle)
- Enables shopping for replacement products with trade-in credit
- Processes claims (repair, replacement, maintenance) with full status lifecycle
- Supports multi-home management with family sharing and role-based access

**The competitive space**: Allstate Protection Plans, Asurion, Home Depot Protection, Amazon Home Services, Frontdoor (AHS/HSA).

---

### 2. Who Are the Target Users?

- **Primary**: US homeowners (25–55 age range) who own multiple appliances/electronics
- **Secondary**: Renters with valuable electronics who want protection plans
- **Tertiary**: Property managers with multiple homes
- **Scale target**: 200M+ users (essentially every US household)

---

### 3. What Core Features Exist (Flutter App)?

| Feature | Screens | Status |
|---------|---------|--------|
| Authentication | 4 (splash, signin, signup, OTP) | UI complete, no real auth |
| Home Dashboard | 3 (home, alerts, notifications) | UI complete, 100% mock data |
| Assets | 15+ (detail, warranties, add flow, upgrade flow, protection plan flow) | UI complete, mock data |
| Services | 6 + 9 booking flows (all 9 categories) | UI complete, SharedPreferences |
| Maintenance | 5+ (dashboard, AI fix, parts order flow) | UI complete, SharedPreferences |
| Claims | 1 (my claims + detail) | UI complete, mock + SharedPreferences |
| Shopping | 4 + 7 checkout screens | UI complete, mock data |
| Profile | 5 (profile, settings, family, deliveries, payments) | UI complete, mock data |

**Total: 308 Dart files, 63+ screens, 17 core widgets.**

---

### 4. What Architectural Decisions Are Already Visible?

| Decision | What They Chose | Assessment |
|----------|----------------|------------|
| State management | Riverpod 2.x | ✅ Right choice, but underutilized — most screens use raw `setState()` |
| Navigation | GoRouter | ✅ Solid — typed route models, proper error screens |
| HTTP client | `http` package | ⚠️ Should be `dio` for interceptors, retry, cancellation |
| Folder structure | Feature-based modules under `lib/features/` | ✅ Good — follows clean architecture pattern |
| Core layer | `core/` with base classes, errors, constants, widgets | ✅ Well-scaffolded — `Result<T>`, `AsyncState<T>`, `BaseNotifier` |
| Theming | Centralized `AppTheme.lightTheme` + `AppStrings` | ✅ Excellent — single source of truth, easy rebrand |
| Local storage | SharedPreferences | ⚠️ Fragile for complex data — should use Drift/SQLite |
| Backend API | Two redundant API clients, neither used | ❌ No backend exists |
| AI integration | Direct OpenAI API calls from client | 🔴 Critical security issue — API key exposed in client code |
| Testing | 7 utility tests out of 308 files | 🔴 ~2% coverage — unacceptable |

---

### 5. What Are the Weaknesses in Current Structure?

#### 🔴 CRITICAL

1. **No backend whatsoever**. 100% of data is hardcoded mock or SharedPreferences. There is no database, no API server, no authentication system.

2. **OpenAI API key is exposed in the Flutter client code** (loaded via `EnvironmentConfig.openAiApiKey` but still compiled into the app binary). Anyone can decompile the APK and extract it. This is a **billing and security disaster**.

3. **God-object screens**. `HomeScreen` is 2,465 lines. `AssetDetailScreen` is 1,914 lines. These are unmaintainable, untestable monoliths. In a production app, no file should exceed 300 lines.

4. **Near-zero test coverage** (7 test files for 308 source files). No widget tests, no integration tests, no golden tests. You cannot deploy what you cannot test.

5. **Two redundant API clients** (`ApiService` and `ApiClient`) doing the same thing. Neither is wired to any real backend.

#### 🟡 SIGNIFICANT

6. **Riverpod is declared but not used properly**. Most screens load data via static mock methods and manage state with `setState()`. The `BaseNotifier<T>` and `AsyncState<T>` infrastructure is excellent but sits unused.

7. **SharedPreferences for complex data** (bookings, claims, maintenance records). SharedPreferences is a key-value store designed for settings, not relational data. Data integrity issues will emerge immediately at scale.

8. **No offline-first strategy**. The app doesn't handle network failures, sync conflicts, or optimistic updates. For a 200M user app, offline capability is non-negotiable.

9. **No analytics, no crash reporting, no performance monitoring** in the Flutter app. No Firebase Analytics, no Sentry, no custom telemetry.

10. **No deep linking, no push notifications, no biometric auth** — all table-stakes for a US consumer app.

#### 🟢 GOOD FOUNDATIONS

11. Feature-based folder structure is clean and scalable
12. `AppStrings` centralization allows instant rebranding
13. `Result<T>` type and error hierarchy are production-grade patterns
14. GoRouter setup with typed route models is solid
15. Theme system with centralized colors/dimensions is well done
16. The existing architecture doc (00_FULL_ARCHITECTURE.md) shows strong planning

---

### 6. What Is Missing for Production-Grade US-Level Product?

| Category | What's Missing |
|----------|---------------|
| **Backend** | Everything — API server, database, auth, file storage |
| **Authentication** | Real auth flow with JWT, OAuth, OTP, biometrics |
| **Data layer** | Repository pattern, real API calls, local cache (Drift/SQLite) |
| **State management** | Proper Riverpod providers per feature, not setState() |
| **Security** | Certificate pinning, jailbreak detection, ProGuard/R8, code obfuscation |
| **Testing** | Unit tests (>80%), widget tests, integration tests, golden tests |
| **CI/CD** | Automated builds, tests, deployments (Codemagic/Fastlane) |
| **Monitoring** | Sentry, Firebase Crashlytics, Firebase Analytics, custom metrics |
| **Accessibility** | Semantic labels, screen reader support, dynamic text scaling |
| **Localization** | Even for US-only: proper `intl` setup with ARB files |
| **Deep linking** | Universal links (iOS) + App Links (Android) |
| **Push notifications** | FCM integration with backend |
| **App Store** | Privacy policy, terms of service, EULA, App Store / Play Store listing |
| **Performance** | Image optimization, lazy loading, memory profiling, frame rate monitoring |
| **Legal/Compliance** | CCPA (California), state insurance regulations, PCI DSS (via Stripe), SOC 2 |

---

## PART 2: COMPLETE SYSTEM ARCHITECTURE FOR 200M+ USERS

---

## A. FRONTEND ARCHITECTURE (Flutter)

### A.1 State Management — Riverpod Done Right

**Current problem**: Riverpod is a dependency but screens use `setState()`.

**Target architecture**: Every feature gets its own provider layer.

```
lib/features/assets/
├── data/
│   ├── models/              # Dart data classes (fromJson/toJson)
│   │   ├── asset.dart
│   │   ├── warranty.dart
│   │   └── health_score.dart
│   ├── repositories/        # Abstract contracts
│   │   └── asset_repository.dart
│   └── sources/
│       ├── asset_remote_source.dart   # API calls
│       └── asset_local_source.dart    # Drift cache
├── domain/                  # Business logic (optional, use when complex)
│   └── use_cases/
│       ├── get_assets.dart
│       └── add_asset.dart
├── presentation/
│   ├── providers/
│   │   ├── asset_list_provider.dart       # StateNotifierProvider
│   │   ├── asset_detail_provider.dart
│   │   └── add_asset_provider.dart
│   ├── screens/
│   │   ├── asset_list_screen.dart         # MAX 200 lines
│   │   └── asset_detail_screen.dart       # MAX 300 lines
│   └── widgets/
│       ├── asset_card.dart
│       ├── health_score_gauge.dart
│       └── warranty_badge.dart
└── asset_providers.dart     # Barrel file exporting all providers
```

**Rules**:
1. Every screen is a `ConsumerWidget` or `ConsumerStatefulWidget`
2. No `setState()` for any data-driven UI — only Riverpod
3. `setState()` is allowed ONLY for local UI state (animation controllers, form focus)
4. Every API call goes through a repository → provider chain
5. No file exceeds 300 lines. Period.

### A.2 API Handling — Dio + Repository Pattern

**Replace `http` package with `dio`**. Here's why:

| Feature | `http` | `dio` |
|---------|--------|-------|
| Interceptors | ❌ | ✅ (auth, logging, retry) |
| Request cancellation | ❌ | ✅ (CancelToken) |
| Automatic retry | ❌ | ✅ (dio_retry) |
| File upload with progress | ❌ | ✅ |
| Request/response transform | ❌ | ✅ |
| Certificate pinning | ❌ | ✅ |

**Architecture**:

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   Screen    │────▶│   Provider   │────▶│  Repository  │
│ (Riverpod)  │     │ (StateNotif) │     │  (abstract)  │
└─────────────┘     └──────────────┘     └──────┬───────┘
                                                │
                                    ┌───────────┼───────────┐
                                    ▼                       ▼
                            ┌──────────────┐       ┌──────────────┐
                            │ Remote Source │       │ Local Source  │
                            │   (Dio API)  │       │   (Drift DB) │
                            └──────────────┘       └──────────────┘
```

**Dio setup with interceptors**:
```
DioClient
  ├── AuthInterceptor        → Attach JWT, auto-refresh on 401
  ├── LoggingInterceptor     → Log requests in debug mode
  ├── RetryInterceptor       → Retry on network failure (3 attempts, exponential backoff)
  ├── CacheInterceptor       → Cache GET responses locally (offline-first)
  └── ErrorInterceptor       → Map HTTP errors to typed Failure objects
```

### A.3 Error Handling — Use What You Already Built

Your `Result<T>` / `Failure` / `Exception` hierarchy is **excellent**. The problem is nobody uses it.

**Enforce this rule**: Every repository method returns `Future<Result<T>>`. Every provider maps `Result<T>` to `AsyncState<T>`.

```dart
// Repository
Future<Result<List<Asset>>> getAssets(String householdId);

// Provider
class AssetListNotifier extends StateNotifier<AsyncState<List<Asset>>> {
  Future<void> loadAssets(String householdId) async {
    state = const AsyncLoading();
    final result = await repository.getAssets(householdId);
    state = result.when(
      success: (assets) => AsyncData(assets),
      failed: (failure) => AsyncError(failure.message),
    );
  }
}
```

### A.4 Offline-First Strategy

For 200M US users, many will have poor connectivity. Use a **cache-first, network-refresh** pattern:

```
User opens screen
  → Read from Drift (local DB) immediately → Show cached data
  → Fire API request in background
  → On success: update Drift + update UI
  → On failure: show cached data + subtle "offline" indicator
```

**Drift (SQLite)** replaces SharedPreferences for ALL persistent data:
- Assets, warranties, maintenance records
- Bookings, claims, orders
- Notifications, alerts
- User profile, household data

SharedPreferences stays ONLY for:
- Auth tokens (via `flutter_secure_storage`)
- Theme preferences
- Onboarding completion flags
- Feature flags

### A.5 Performance Optimization

| Technique | Implementation |
|-----------|---------------|
| **Image optimization** | `cached_network_image` (already have) + WebP format from CDN + progressive loading |
| **Lazy loading** | `ListView.builder` for all lists (never `ListView(children: [])`) |
| **Code splitting** | Deferred loading for heavy features (`deferred as shopping`) — Flutter 3.x supports this |
| **Tree shaking** | Remove unused dependencies, use `--split-debug-info` and `--obfuscate` |
| **Memory management** | Dispose all controllers, cancel all subscriptions in `dispose()` |
| **Frame rate** | Profile with DevTools, target 60fps. Avoid `setState()` on parent widgets |
| **Startup time** | Minimize `main()` work, lazy-initialize services, use `compute()` for heavy parsing |
| **Bundle size** | Android App Bundle (AAB), iOS bitcode. Target <30MB download |
| **Network** | Request batching, response compression (gzip), pagination everywhere |

### A.6 Production Folder Structure (Final)

```
lib/
├── main.dart                           # Entry point (< 30 lines)
├── app.dart                            # MaterialApp.router setup
├── bootstrap.dart                      # Service initialization
│
├── core/
│   ├── config/
│   │   ├── environment.dart            # Env config (API URL, keys)
│   │   └── app_config.dart             # Feature flags, timeouts
│   ├── constants/
│   │   ├── api_endpoints.dart          # All API paths
│   │   ├── app_strings.dart            # UI strings (keep your excellent one)
│   │   ├── app_colors.dart
│   │   ├── app_dimensions.dart
│   │   └── storage_keys.dart
│   ├── errors/
│   │   ├── exceptions.dart             # (keep)
│   │   └── failures.dart               # (keep)
│   ├── network/
│   │   ├── dio_client.dart             # Singleton Dio with interceptors
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── retry_interceptor.dart
│   │   │   ├── logging_interceptor.dart
│   │   │   └── cache_interceptor.dart
│   │   └── network_info.dart           # Connectivity check
│   ├── storage/
│   │   ├── database/
│   │   │   ├── app_database.dart       # Drift database class
│   │   │   ├── daos/                   # Data access objects
│   │   │   └── tables/                 # Table definitions
│   │   └── secure_storage.dart         # flutter_secure_storage wrapper
│   ├── utils/
│   │   ├── logger.dart                 # (keep your AppLogger)
│   │   ├── result.dart                 # (keep your Result<T>)
│   │   ├── validators.dart
│   │   ├── date_utils.dart
│   │   └── extensions/
│   ├── theme/
│   │   ├── app_theme.dart              # (keep)
│   │   └── text_styles.dart
│   ├── widgets/                        # (keep your 17 core widgets)
│   └── base/                           # (keep BaseNotifier, AsyncState)
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── auth_providers.dart
│   ├── home/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── home_providers.dart
│   ├── assets/
│   ├── maintenance/
│   ├── claims/
│   ├── services/
│   ├── shopping/
│   ├── profile/
│   └── notifications/
│
├── routes/
│   ├── app_router.dart                 # (keep, but break into feature route files)
│   ├── route_guards.dart               # Auth guard, onboarding guard
│   └── route_models.dart               # (keep)
│
└── providers/
    └── global_providers.dart           # App-wide providers (auth state, user, theme)
```

---

## B. BACKEND ARCHITECTURE

### B.1 Monolith vs Microservices — The Honest Answer

**Start with a Modular Monolith. No exceptions.**

Here's why, and I'm not being theoretical:

| Factor | Modular Monolith | Microservices |
|--------|-----------------|---------------|
| Time to MVP | 3–4 months | 8–12 months |
| Team size needed | 2–3 devs | 8–15 devs |
| Debugging | Stack trace in one process | Distributed tracing across 10 services |
| Deployment | One pipeline | 10+ pipelines, service mesh, API gateway |
| Data consistency | Transactions work | Saga pattern, eventual consistency, compensating actions |
| Cost | ~$300/month | ~$3,000/month minimum |
| Operational complexity | Low | Extremely high (K8s, service discovery, circuit breakers) |

**Your existing architecture doc proposes microservices from Phase 3.** That's correct timing. But Phase 1 must be a monolith.

**The trick**: Structure the monolith so extraction is trivial. Each module has its own:
- Routes, controllers, services, schemas
- No cross-module direct imports (communicate via an internal event bus)
- Each module could become its own service with minimal refactoring

### B.2 Framework Choice — Fastify (Already in Your Doc)

Your doc already chose **Fastify**. I agree. Here's the comparison that justifies it:

| Framework | Requests/sec | TypeScript | Validation | Plugin System | Learning Curve |
|-----------|-------------|-----------|------------|--------------|---------------|
| **Express** | ~15,000 | Via TS | Manual (Joi/Zod) | Middleware | Low |
| **Fastify** | ~30,000 | Native | Built-in (JSON Schema / Zod) | Encapsulated plugins | Medium |
| **NestJS** | ~12,000 | Native | Built-in (class-validator) | Modules + DI | High |

Fastify wins because:
1. **2× Express throughput** — matters at 200M users
2. **Built-in validation** with JSON Schema (or Zod plugin)
3. **Encapsulated plugin system** — perfect for modular monolith
4. **TypeScript-first** — not bolted on
5. **Lower overhead than NestJS** — NestJS adds abstraction layers you don't need yet

### B.3 API Versioning Strategy

```
https://api.homeiq.com/v1/assets          ← Current
https://api.homeiq.com/v2/assets          ← Breaking changes (future)
```

**Rules**:
1. URL-based versioning (`/v1/`, `/v2/`) — simplest for mobile clients
2. Never break existing versions — old app versions must keep working
3. Support at most 2 versions simultaneously (N and N-1)
4. Deprecation: 6-month notice → sunset header → remove
5. Non-breaking changes (new fields, new endpoints) go into current version

### B.4 Authentication System

**JWT + Refresh Token + OTP** (your doc's design is correct). But here are critical details your doc misses:

```
┌─────────────────────────────────────────────────────────┐
│                    AUTH FLOW DETAIL                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  SIGN UP:                                                │
│  1. Client → POST /v1/auth/signup {email, phone, name}  │
│  2. Server → Create user (status: pending_verification)  │
│  3. Server → Generate OTP → Hash → Store in Redis (5min) │
│  4. Server → Send OTP via SMS (Twilio)                   │
│  5. Client → POST /v1/auth/otp/verify {phone, code}     │
│  6. Server → Compare hash → If match:                    │
│     a. Update user status → active                       │
│     b. Generate access_token (15min) + refresh_token (30d)│
│     c. Store refresh_token hash in DB (user_sessions)    │
│     d. Return tokens to client                           │
│                                                          │
│  SIGN IN:                                                │
│  1. Client → POST /v1/auth/signin {phone}               │
│  2. Server → Check user exists → Send OTP               │
│  3. Same OTP verify flow → Return tokens                 │
│                                                          │
│  SOCIAL (Google/Apple):                                  │
│  1. Client → Native SDK → Get id_token                   │
│  2. Client → POST /v1/auth/google {id_token}            │
│  3. Server → Verify id_token with Google's API           │
│  4. Server → Find or create user                         │
│  5. Server → Return access_token + refresh_token         │
│                                                          │
│  TOKEN REFRESH:                                          │
│  1. Client Dio interceptor detects 401                   │
│  2. Client → POST /v1/auth/refresh {refresh_token}      │
│  3. Server → Validate refresh_token hash in DB           │
│  4. Server → Generate new access + refresh tokens        │
│  5. Server → Invalidate old refresh token                │
│  6. Client → Retry original request with new access token│
│                                                          │
│  CRITICAL SECURITY:                                      │
│  - Refresh token rotation (new token on every refresh)   │
│  - Automatic reuse detection (if old token used → revoke │
│    ALL tokens for that user → force re-login)            │
│  - Device fingerprinting in user_sessions                │
│  - Max 5 active sessions per user                        │
│  - Rate limit: 5 OTP requests per phone per hour         │
│  - OTP brute force: 3 attempts max → lock for 15 min    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### B.5 Rate Limiting

| Endpoint Category | Limit | Window | Key |
|-------------------|-------|--------|-----|
| Auth (signup/signin/OTP) | 5 requests | 1 minute | IP |
| OTP verify | 3 attempts | 5 minutes | Phone number |
| General API (authenticated) | 200 requests | 1 minute | User ID |
| General API (unauthenticated) | 50 requests | 1 minute | IP |
| AI endpoints | 10 requests | 1 hour | User ID |
| File upload | 20 requests | 1 hour | User ID |
| Stripe webhooks | No limit | — | Verify signature |

**Implementation**: Redis-backed sliding window counter. Use `@fastify/rate-limit` plugin.

### B.6 Caching Layer — Redis

Your existing architecture doc covers this well. I'll add what's missing:

**Cache warming strategy**:
1. On user login → pre-cache: user profile, household list, active assets, unread notification count
2. On app open (if cached) → serve from cache, refresh in background
3. On data mutation → invalidate related keys immediately

**Cache stampede protection**:
- Use probabilistic early expiration (add jitter to TTL)
- Use lock-based recomputation (Redis `SETNX` lock) for expensive queries

**What NOT to cache**:
- Payment data
- OTP codes longer than their TTL
- Anything that must be real-time (claim status after a transition)

### B.7 Queue System — BullMQ (Redis-backed)

Your doc chose BullMQ. I agree for Phase 1–3. Here's the queue design:

```
Queues:
├── email           → Priority: normal    │ Workers: 2  │ Retry: 3x
├── push            → Priority: high      │ Workers: 2  │ Retry: 3x
├── sms             → Priority: high      │ Workers: 1  │ Retry: 3x
├── health-score    → Priority: low       │ Workers: 1  │ Retry: 1x
├── maintenance     → Priority: normal    │ Workers: 1  │ Retry: 2x
├── ai-processing   → Priority: normal    │ Workers: 2  │ Retry: 2x
├── file-processing → Priority: low       │ Workers: 1  │ Retry: 2x
└── cleanup         → Priority: low       │ Workers: 1  │ Retry: 0x
```

**When to upgrade to Kafka**: Phase 4 (50M+ users), when you need:
- Event sourcing for claims/orders
- Cross-service event bus
- Replay capability
- Multi-consumer groups

### B.8 Logging and Monitoring

**Logging stack**: Pino (Fastify's built-in, structured JSON) → CloudWatch Logs → CloudWatch Insights

**Every log entry must have**:
```json
{
  "level": "info",
  "requestId": "req-abc123",
  "userId": "user-uuid",
  "householdId": "hh-uuid",
  "method": "GET",
  "path": "/v1/assets",
  "statusCode": 200,
  "responseTime": 45,
  "timestamp": "2026-02-23T10:15:30.123Z"
}
```

**Monitoring**: Your doc proposes Datadog or Grafana+Prometheus. For cost reasons:
- Phase 1–2: **CloudWatch** (included with AWS, free tier covers a lot)
- Phase 3+: **Datadog** or **Grafana Cloud** (dedicated observability)

### B.9 CI/CD Strategy

```
┌─────────────────────────────────────────────────────┐
│                    CI/CD PIPELINE                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ON PULL REQUEST:                                    │
│  ├── Lint (ESLint + Prettier)                       │
│  ├── Type check (tsc --noEmit)                      │
│  ├── Unit tests (Vitest) — must pass                │
│  ├── Integration tests (against test DB)            │
│  ├── Security audit (npm audit, Snyk)               │
│  └── Build check (docker build --target=builder)    │
│                                                      │
│  ON MERGE TO main:                                   │
│  ├── All PR checks                                   │
│  ├── Build Docker image                              │
│  ├── Push to ECR                                     │
│  ├── Deploy to STAGING                               │
│  ├── Run smoke tests against staging                 │
│  └── Notify Slack                                    │
│                                                      │
│  ON RELEASE TAG (v1.2.3):                           │
│  ├── Deploy to PRODUCTION (rolling update)           │
│  ├── Run production smoke tests                      │
│  ├── Notify Slack                                    │
│  └── Create GitHub release with changelog            │
│                                                      │
│  FLUTTER (Mobile):                                   │
│  ├── ON PR: flutter analyze, flutter test            │
│  ├── ON main: Build APK + IPA                       │
│  ├── ON tag: Upload to TestFlight + Play Console     │
│  └── Use Codemagic or GitHub Actions + Fastlane      │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## C. DATABASE DESIGN

### C.1 Schema Design Principles

Your existing doc defines 30+ tables. The design is solid. Here are principles I'd enforce:

1. **UUIDs everywhere** (v4) — you already do this ✅
2. **`household_id` as the partition key** — you already planned this ✅
3. **Timestamps on every table**: `created_at`, `updated_at`, `deleted_at` (soft delete)
4. **JSONB for polymorphic data** (booking details, service specifics) — you already do this ✅
5. **Status history tables** for auditability — you already do this ✅
6. **Never store computed values permanently** — recompute health scores, don't trust cached values without a `computed_at` timestamp

### C.2 Normalization vs Denormalization

| Rule | When |
|------|------|
| **Normalize** (3NF) | Core entities: users, households, assets, claims, orders |
| **Denormalize** | Read-heavy views: dashboard summaries, notification counts, asset list with inline warranty status |
| **JSONB** | Variable-structure data: booking details per service type, coverage items per plan tier |
| **Materialized views** | Dashboard aggregations, health score summaries per household |

**Critical**: Never denormalize writes. Only denormalize reads, and only when query performance demands it (>200ms p95).

### C.3 Indexing Strategy

```sql
-- EVERY foreign key gets an index (PostgreSQL doesn't do this automatically)
CREATE INDEX idx_assets_household ON assets(household_id);
CREATE INDEX idx_assets_category ON assets(category_id);
CREATE INDEX idx_claims_asset ON claims(asset_id);
CREATE INDEX idx_bookings_household ON service_bookings(household_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);

-- Composite indexes for common queries
CREATE INDEX idx_assets_household_status ON assets(household_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_reminders_due ON maintenance_reminders(household_id, status, due_date);
CREATE INDEX idx_claims_status ON claims(household_id, status, created_at DESC);

-- Partial indexes for performance
CREATE INDEX idx_active_bookings ON service_bookings(household_id, scheduled_date)
  WHERE status NOT IN ('completed', 'canceled');

-- GIN index for JSONB search
CREATE INDEX idx_booking_details ON service_bookings USING GIN(details);

-- Full-text search
CREATE INDEX idx_products_search ON products USING GIN(to_tsvector('english', name || ' ' || description));
```

**Rule**: Run `EXPLAIN ANALYZE` on every query that appears in your top 20 endpoints. If seq scan appears on a table >10K rows, add an index.

### C.4 Partitioning

**When**: Table exceeds 100M rows.

**First candidate**: `notifications` table (highest write volume).

```sql
-- Range partition by created_at (monthly)
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  ...
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

CREATE TABLE notifications_2026_01 PARTITION OF notifications
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE notifications_2026_02 PARTITION OF notifications
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
-- Auto-create future partitions via pg_partman
```

**Also partition**: `audit_logs`, `ai_sessions`, `maintenance_records` (all high-volume, time-series data).

### C.5 Read Replicas

```
Phase 1 (0-100K):    Primary only
Phase 2 (100K-5M):   Primary + 2 read replicas
Phase 3 (5M-50M):    Primary + 5 read replicas (across AZs)
Phase 4 (50M-200M):  Primary + replicas + Citus sharding

Route reads to replicas:
- Dashboard data → replica
- Asset list → replica
- Notification list → replica
- Search results → replica (or ElasticSearch)

Always use primary for:
- Any write operation
- Reads immediately after a write (read-your-own-writes consistency)
- Payment and claim status checks
```

### C.6 Sharding Strategy (Phase 4)

**Shard key**: `household_id`

**Why `household_id` and not `user_id`**:
- All data in the app is scoped to a household
- One query never crosses household boundaries (except admin/search)
- Family members in the same household hit the same shard (locality)
- Even distribution (households are roughly equal in data volume)

**Implementation**: Citus extension for PostgreSQL (distributed tables).

```sql
-- Distribute tables by household_id
SELECT create_distributed_table('assets', 'household_id');
SELECT create_distributed_table('maintenance_reminders', 'household_id');
SELECT create_distributed_table('service_bookings', 'household_id');
SELECT create_distributed_table('claims', 'household_id');
SELECT create_distributed_table('notifications', 'user_id'); -- exception: user-scoped

-- Reference tables (small, replicated to all shards)
SELECT create_reference_table('asset_categories');
SELECT create_reference_table('protection_plan_templates');
SELECT create_reference_table('service_categories');
```

### C.7 Backup Strategy

| Type | Frequency | Retention | Where |
|------|-----------|-----------|-------|
| Automated snapshots (RDS) | Daily | 35 days | Same region |
| Point-in-time recovery | Continuous (5-min granularity) | 35 days | Same region |
| Cross-region backup | Daily | 90 days | US-West-2 |
| Manual snapshots | Before major migrations | 1 year | S3 Glacier |
| Logical dump (pg_dump) | Weekly | 12 months | S3 |

**RTO** (Recovery Time Objective): < 1 hour  
**RPO** (Recovery Point Objective): < 5 minutes

### C.8 Migration Strategy

**Tool**: Prisma Migrate (already in your doc)

**Rules**:
1. Every migration is forward-only. Never edit a migration that has been applied.
2. Every migration is reversible (include a `down` step).
3. Run migrations against a staging DB before production. Always.
4. Large data migrations (backfills) go in background jobs, not in migration files.
5. Schema changes that affect >1M rows: use `CREATE INDEX CONCURRENTLY`, `ALTER TABLE ... ADD COLUMN` (non-blocking in PG 11+).
6. Never rename a column in one step. Instead: add new column → backfill → update code → drop old column.

### C.9 Core Tables (Refined)

```sql
-- ═══════════════════════════════════════════════════════════
-- USERS
-- ═══════════════════════════════════════════════════════════
CREATE TABLE users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           VARCHAR(255) UNIQUE,
  phone           VARCHAR(20) UNIQUE,
  full_name       VARCHAR(100) NOT NULL,
  avatar_url      TEXT,
  auth_provider   VARCHAR(20) NOT NULL DEFAULT 'phone',  -- phone | google | apple
  status          VARCHAR(20) NOT NULL DEFAULT 'active',  -- active | suspended | deleted
  last_login_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_phone ON users(phone) WHERE deleted_at IS NULL;

-- ═══════════════════════════════════════════════════════════
-- HOUSEHOLDS (Multi-home support)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE households (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            VARCHAR(100) NOT NULL,             -- "Main House", "Beach House"
  address_line1   VARCHAR(255),
  address_line2   VARCHAR(255),
  city            VARCHAR(100),
  state           VARCHAR(2),                         -- US state code
  zip_code        VARCHAR(10),
  property_type   VARCHAR(20),                        -- house | apartment | condo | townhouse
  owner_id        UUID NOT NULL REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_households_owner ON households(owner_id);

-- ═══════════════════════════════════════════════════════════
-- HOUSEHOLD MEMBERS (Family sharing with RBAC)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE household_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id),
  role            VARCHAR(20) NOT NULL DEFAULT 'member',  -- owner | admin | member | viewer
  status          VARCHAR(20) NOT NULL DEFAULT 'active',
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(household_id, user_id)
);

CREATE INDEX idx_members_household ON household_members(household_id);
CREATE INDEX idx_members_user ON household_members(user_id);

-- ═══════════════════════════════════════════════════════════
-- ASSETS
-- ═══════════════════════════════════════════════════════════
CREATE TABLE assets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  name            VARCHAR(200) NOT NULL,              -- "Samsung French Door Refrigerator"
  brand           VARCHAR(100),
  model_number    VARCHAR(100),
  serial_number   VARCHAR(100),
  category_id     UUID REFERENCES asset_categories(id),
  subcategory_id  UUID REFERENCES asset_subcategories(id),
  purchase_date   DATE,
  purchase_price  DECIMAL(10,2),
  location        VARCHAR(100),                       -- "Kitchen", "Living Room"
  condition       VARCHAR(20) DEFAULT 'good',         -- excellent | good | fair | poor
  photo_url       TEXT,
  receipt_url     TEXT,
  health_score    INTEGER DEFAULT 80,                 -- 0-100, computed
  health_computed_at TIMESTAMPTZ,
  status          VARCHAR(20) NOT NULL DEFAULT 'active',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_assets_household ON assets(household_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_assets_category ON assets(category_id);

-- ═══════════════════════════════════════════════════════════
-- ASSET WARRANTIES
-- ═══════════════════════════════════════════════════════════
CREATE TABLE asset_warranties (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id        UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  type            VARCHAR(30) NOT NULL,               -- manufacturer | extended | protection_plan
  provider        VARCHAR(100),
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  coverage_details JSONB,                             -- Flexible coverage items
  document_url    TEXT,
  status          VARCHAR(20) NOT NULL DEFAULT 'active', -- active | expired | claimed
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_warranties_asset ON asset_warranties(asset_id);
CREATE INDEX idx_warranties_expiry ON asset_warranties(end_date) WHERE status = 'active';

-- ═══════════════════════════════════════════════════════════
-- MAINTENANCE REMINDERS
-- ═══════════════════════════════════════════════════════════
CREATE TABLE maintenance_reminders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id        UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  household_id    UUID NOT NULL REFERENCES households(id),
  title           VARCHAR(200) NOT NULL,
  description     TEXT,
  category        VARCHAR(30) NOT NULL,               -- cleaning | inspection | replacement | service
  frequency       VARCHAR(20) NOT NULL,               -- monthly | quarterly | biAnnual | annual
  priority        VARCHAR(10) NOT NULL DEFAULT 'medium',
  due_date        DATE NOT NULL,
  status          VARCHAR(20) NOT NULL DEFAULT 'upcoming',  -- upcoming | overdue | completed | skipped | snoozed
  completed_at    TIMESTAMPTZ,
  skip_reason     VARCHAR(50),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reminders_household ON maintenance_reminders(household_id, status, due_date);
CREATE INDEX idx_reminders_asset ON maintenance_reminders(asset_id);
CREATE INDEX idx_reminders_overdue ON maintenance_reminders(due_date, status)
  WHERE status IN ('upcoming', 'overdue');

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════
CREATE TABLE notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id),
  type            VARCHAR(50) NOT NULL,               -- booking_confirmed | claim_status_changed | etc.
  title           VARCHAR(200) NOT NULL,
  body            TEXT NOT NULL,
  data            JSONB,                              -- Deep link data, entity references
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  channel         VARCHAR(20) NOT NULL DEFAULT 'in_app', -- in_app | push | email | sms
  sent_at         TIMESTAMPTZ,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- ═══════════════════════════════════════════════════════════
-- CLAIMS
-- ═══════════════════════════════════════════════════════════
CREATE TABLE claims (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_number    VARCHAR(30) UNIQUE NOT NULL,        -- CLM-2026-0001
  household_id    UUID NOT NULL REFERENCES households(id),
  asset_id        UUID NOT NULL REFERENCES assets(id),
  type            VARCHAR(20) NOT NULL,               -- repair | replacement | maintenance
  status          VARCHAR(20) NOT NULL DEFAULT 'submitted',
  description     TEXT NOT NULL,
  issue_photos    TEXT[],                              -- S3 URLs
  coverage_type   VARCHAR(30),                        -- warranty | protection_plan | none
  approved_amount DECIMAL(10,2),
  deductible      DECIMAL(10,2),
  resolution_notes TEXT,
  submitted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_claims_household ON claims(household_id, status);
CREATE INDEX idx_claims_asset ON claims(asset_id);

-- ═══════════════════════════════════════════════════════════
-- SERVICE BOOKINGS
-- ═══════════════════════════════════════════════════════════
CREATE TABLE service_bookings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_number  VARCHAR(30) UNIQUE NOT NULL,        -- HQ2026-0223-0001
  household_id    UUID NOT NULL REFERENCES households(id),
  category_id     UUID NOT NULL REFERENCES service_categories(id),
  status          VARCHAR(30) NOT NULL DEFAULT 'pending',
  scheduled_date  DATE NOT NULL,
  scheduled_time  VARCHAR(20) NOT NULL,               -- "9:00 AM - 12:00 PM"
  address         JSONB NOT NULL,
  contact_name    VARCHAR(100) NOT NULL,
  contact_phone   VARCHAR(20) NOT NULL,
  details         JSONB NOT NULL,                     -- Category-specific booking details
  estimated_price DECIMAL(10,2),
  final_price     DECIMAL(10,2),
  technician_id   UUID REFERENCES service_providers(id),
  payment_status  VARCHAR(20) DEFAULT 'pending',
  payment_mode    VARCHAR(20) DEFAULT 'payOnVisit',
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bookings_household ON service_bookings(household_id, status);
CREATE INDEX idx_bookings_date ON service_bookings(scheduled_date)
  WHERE status NOT IN ('completed', 'canceled');

-- ═══════════════════════════════════════════════════════════
-- PROTECTION PLANS (User purchases)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE user_protection_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id),
  asset_id        UUID NOT NULL REFERENCES assets(id),
  template_id     UUID NOT NULL REFERENCES protection_plan_templates(id),
  tier            VARCHAR(20) NOT NULL,               -- essential | premium | ultimate
  status          VARCHAR(20) NOT NULL DEFAULT 'active',
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  billing_cycle   VARCHAR(20) NOT NULL,               -- monthly | annual | one_time
  price           DECIMAL(10,2) NOT NULL,
  deductible      DECIMAL(10,2) NOT NULL DEFAULT 0,
  stripe_subscription_id VARCHAR(100),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_plans_user ON user_protection_plans(user_id);
CREATE INDEX idx_plans_asset ON user_protection_plans(asset_id);

-- ═══════════════════════════════════════════════════════════
-- ORDERS (Shopping, upgrades, parts)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number    VARCHAR(30) UNIQUE NOT NULL,        -- HQ-ORD-2026-0001
  user_id         UUID NOT NULL REFERENCES users(id),
  household_id    UUID NOT NULL REFERENCES households(id),
  type            VARCHAR(20) NOT NULL,               -- purchase | upgrade_trade_in | parts
  status          VARCHAR(30) NOT NULL DEFAULT 'placed',
  subtotal        DECIMAL(10,2) NOT NULL,
  tax             DECIMAL(10,2) NOT NULL DEFAULT 0,
  shipping_cost   DECIMAL(10,2) NOT NULL DEFAULT 0,
  trade_in_credit DECIMAL(10,2) DEFAULT 0,
  total           DECIMAL(10,2) NOT NULL,
  shipping_address JSONB NOT NULL,
  payment_method_id UUID REFERENCES payment_methods(id),
  stripe_payment_intent_id VARCHAR(100),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user ON orders(user_id, status);
CREATE INDEX idx_orders_household ON orders(household_id);

-- ═══════════════════════════════════════════════════════════
-- PAYMENT METHODS
-- ═══════════════════════════════════════════════════════════
CREATE TABLE payment_methods (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id),
  type            VARCHAR(20) NOT NULL,               -- credit_card | debit_card | apple_pay | google_pay
  stripe_pm_id    VARCHAR(100) NOT NULL,              -- Stripe PaymentMethod ID
  last_four       VARCHAR(4) NOT NULL,
  brand           VARCHAR(20),                        -- visa | mastercard | amex
  exp_month       INTEGER,
  exp_year        INTEGER,
  is_default      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_methods_user ON payment_methods(user_id);

-- ═══════════════════════════════════════════════════════════
-- AUDIT LOG
-- ═══════════════════════════════════════════════════════════
CREATE TABLE audit_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id),
  action          VARCHAR(50) NOT NULL,               -- user.login | claim.submitted | payment.succeeded
  entity_type     VARCHAR(50),                        -- user | asset | claim | order | booking
  entity_id       UUID,
  old_values      JSONB,
  new_values      JSONB,
  ip_address      INET,
  user_agent      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

CREATE INDEX idx_audit_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
```

### C.10 Entity Relationship Summary

```
users ──1:N──▶ household_members ◀──N:1── households
                                              │
                          ┌───────────────────┼───────────────────┐
                          ▼                   ▼                   ▼
                       assets           service_bookings        claims
                          │                                       │
              ┌───────────┼───────────┐                          │
              ▼           ▼           ▼                          │
         warranties  reminders  health_scores                   │
                                                                 │
users ──1:N──▶ payment_methods                                  │
users ──1:N──▶ orders ──1:N──▶ order_items                     │
users ──1:N──▶ notifications                                    │
users ──1:N──▶ user_protection_plans ◀──references── assets    │
assets ◀──────────────────────────────────────────────── claims ┘
```

---

## D. INFRASTRUCTURE

### D.1 Cloud Provider — AWS

**Why AWS over GCP/Azure for this product**:
1. **RDS PostgreSQL** is the best managed Postgres offering (Aurora PostgreSQL for Phase 3+)
2. **ECS Fargate** — serverless containers, no EC2 management
3. **ElastiCache** — managed Redis
4. **S3 + CloudFront** — unbeatable CDN + storage
5. **SES** — cheapest email at scale ($0.10 per 1K emails)
6. **Most enterprise customers and SOC 2 auditors expect AWS**
7. **Citus on AWS** is well-supported for PostgreSQL sharding

### D.2 Containerization — Docker

```dockerfile
# Dockerfile (production)
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production=false
COPY . .
RUN npm run build

FROM node:22-alpine
WORKDIR /app
RUN addgroup -g 1001 -S homeiq && adduser -S homeiq -u 1001
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
USER homeiq
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q --spider http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
```

### D.3 Orchestration

| Phase | Orchestration | Why |
|-------|--------------|-----|
| Phase 1–2 (0–5M) | **ECS Fargate** | Zero server management, auto-scaling, pay-per-use |
| Phase 3–4 (5M–200M) | **EKS (Kubernetes)** | Fine-grained control, HPA, custom metrics scaling, multi-region |

**Do NOT start with Kubernetes.** ECS Fargate is simpler, cheaper, and sufficient until you have a dedicated DevOps team.

### D.4 Load Balancer

**AWS Application Load Balancer (ALB)**:
- SSL termination (ACM certificates — free)
- Path-based routing (`/v1/auth/*` → auth targets, `/v1/assets/*` → core targets)
- Health checks every 30 seconds
- Connection draining (120 seconds)
- Sticky sessions: OFF (stateless JWT auth)
- WAF integration (Phase 2+)

### D.5 CDN

**CloudFront**:
- Asset images (WebP, progressive JPEG)
- User uploads (receipts, photos) — signed URLs with 1-hour expiry
- Product images
- Static web app bundle (React)
- Edge caching with TTLs: images (30 days), API responses (0 — no CDN caching for API)

### D.6 API Gateway

| Phase | Gateway | Why |
|-------|---------|-----|
| Phase 1–2 | **ALB + Fastify middleware** | API gateway overhead not justified yet |
| Phase 3+ | **Kong** or **AWS API Gateway** | Rate limiting, auth verification, request transformation, API key management |

### D.7 Horizontal Scaling Strategy

```
Phase 1 (0-100K users):
  2 Fargate tasks (API) + 1 Fargate task (worker)
  1 RDS instance (db.t4g.medium)
  1 Redis node (cache.t4g.micro)

Phase 2 (100K-5M users):
  Auto-scaling: 3-10 Fargate tasks (API) + 2-3 workers
  RDS: Primary + 2 read replicas
  Redis: 3-node cluster
  PgBouncer: Connection pooling

Phase 3 (5M-50M users):
  EKS: 20-50 pods across 3 AZs
  RDS: Multi-AZ Primary + 5 replicas + Aurora Serverless for bursty reads
  Redis: 6-node cluster (3 primary + 3 replica)
  ElasticSearch: 3-node cluster
  BullMQ: Dedicated worker nodes

Phase 4 (50M-200M+ users):
  EKS: 100+ pods across 3 US regions
  Aurora PostgreSQL Global Database + Citus sharding
  ElastiCache Global Datastore
  Multi-region: US-East-1 (primary) + US-West-2 + US-Central-1
  CQRS: Separate read/write databases for dashboard + notifications
  Event sourcing: Kafka for claims, orders, bookings
```

### D.8 Disaster Recovery Plan

| Scenario | RTO | RPO | Action |
|----------|-----|-----|--------|
| Single AZ failure | 0 (auto) | 0 | Multi-AZ RDS failover, ECS reschedules tasks |
| Region failure | < 30 min | < 5 min | DNS failover to secondary region, promote read replica |
| Database corruption | < 1 hour | < 5 min | Point-in-time recovery from RDS |
| Complete data loss | < 4 hours | < 24 hours | Restore from cross-region backup |
| Ransomware/security breach | < 2 hours | < 1 hour | Isolate, restore clean backup, rotate all credentials |

**Runbook**: Document every disaster scenario with step-by-step instructions. Practice quarterly.

---

## E. SECURITY

### E.1 US Compliance Requirements

| Regulation | Applies To | What You Must Do |
|-----------|-----------|-----------------|
| **CCPA** (California) | All US users (CA residents specifically) | Right to know, right to delete, right to opt-out of data sale, privacy policy disclosure |
| **State Privacy Laws** (VA, CO, CT, UT, TX, MT, OR) | Users in those states | Similar to CCPA — data rights, consent management |
| **PCI DSS** | Payment processing | Use Stripe.js/Elements — card numbers never touch your server. This makes you SAQ-A (minimal PCI scope) |
| **SOC 2 Type II** | Enterprise credibility | Annual audit of security controls. Needed for B2B partnerships and investor trust |
| **COPPA** | If users under 13 | Unlikely for home management app, but add age gate in signup |
| **CAN-SPAM** | Email marketing | Unsubscribe link in every email, honor opt-outs within 10 days |
| **TCPA** | SMS/phone calls | Explicit consent before sending SMS. Document consent. Provide opt-out (STOP) |
| **ADA / WCAG 2.1** | Accessibility | App must be usable by people with disabilities. Target AA compliance |
| **State Insurance Regulations** | Protection plan sales | If protection plans are classified as "service contracts," they may need state licensing. Consult a lawyer. This is critical. |

### E.2 Data Encryption

| Layer | Method | Notes |
|-------|--------|-------|
| **In transit** | TLS 1.3 | All connections — API, DB, Redis, S3 |
| **At rest (DB)** | AES-256 (RDS encryption) | Enabled by default on RDS |
| **At rest (S3)** | SSE-S3 | Default S3 encryption |
| **Passwords** | N/A | No passwords — OTP-based auth |
| **OTP codes** | SHA-256 hash | Stored hashed in Redis |
| **Refresh tokens** | SHA-256 hash | Stored hashed in DB |
| **PII fields** | Application-level AES-256 (optional) | SSN, if ever collected |
| **Mobile storage** | `flutter_secure_storage` | Uses Keychain (iOS) / EncryptedSharedPreferences (Android) |
| **API keys** | AWS Secrets Manager | Never in code, never in environment files in production |

### E.3 Role-Based Access Control

Already well-defined in your doc. Implementation detail:

```
Every authenticated request:
  1. AuthMiddleware: Verify JWT → extract userId
  2. RBACMiddleware(requiredRole): 
     - Extract householdId from request (path param or body)
     - Query household_members WHERE user_id AND household_id
     - Compare member.role against requiredRole
     - If insufficient → 403 Forbidden
```

**Role hierarchy**: `owner > admin > member > viewer`

### E.4 Additional Security Measures

| Measure | Implementation |
|---------|---------------|
| **Certificate pinning** | Pin your API domain's certificate in the Flutter app (using `dio` + custom `SecurityContext`) |
| **Jailbreak/root detection** | `flutter_jailbreak_detection` — warn or block on rooted devices |
| **Code obfuscation** | `flutter build apk --obfuscate --split-debug-info=build/symbols` |
| **ProGuard (Android)** | Enable R8 minification in release builds |
| **API key rotation** | Rotate JWT_SECRET every 90 days. Rotate all API keys quarterly |
| **Dependency scanning** | `npm audit` + Snyk in CI. `dart pub outdated` for Flutter |
| **Penetration testing** | Annual third-party pentest before major releases |
| **Bug bounty** | Launch after 1M users (HackerOne or Bugcrowd) |
| **DDoS protection** | AWS Shield Standard (free with ALB). Shield Advanced ($3K/month) for Phase 3+ |
| **WAF** | AWS WAF on ALB — block SQL injection, XSS, known bad IPs |

### E.5 Audit Logging

**Log these events to `audit_logs` table** (immutable, append-only):
- User: login, logout, profile update, account deletion
- Household: create, delete, member invite/remove, role change
- Asset: create, update, delete
- Claim: submit, status change, resolution
- Payment: method added/removed, payment succeeded/failed, refund
- Order: placed, canceled
- Booking: created, canceled, rescheduled
- Admin: any admin action on any entity
- Security: failed login, rate limit hit, suspicious activity

---

## F. PERFORMANCE STRATEGY

### F.1 How to Serve 200M Users

200M users ≠ 200M concurrent users. Realistic concurrency math:

```
200M registered users
  → 40% Monthly Active Users (MAU) = 80M
  → 15% Daily Active Users (DAU) = 30M
  → Peak hour: 10% of DAU = 3M users in one hour
  → Per second: 3M / 3600 = ~833 users/second
  → Avg 3 requests per session per second = ~2,500 requests/second sustained
  → Peak burst (10x): ~25,000 requests/second

So you need to handle:
  - Sustained: 2,500 req/s
  - Peak: 25,000 req/s
  - Target latency: p50 < 100ms, p95 < 300ms, p99 < 1s
```

This is achievable with:
- 50–100 API instances
- 10+ read replicas + Citus sharding
- Aggressive Redis caching (80%+ cache hit rate)
- CDN for all static assets

### F.2 Caching Strategy (Detailed)

```
Request flow with caching:

Client request
  │
  ▼
CDN Cache (static assets, images)
  │ miss
  ▼
API Gateway / ALB
  │
  ▼
Application Layer
  │
  ├── Check Redis cache
  │     │ hit → return cached response (< 5ms)
  │     │ miss ↓
  │
  ├── Check local in-memory cache (LRU, 1000 items)
  │     │ hit → return cached (< 1ms)
  │     │ miss ↓
  │
  ├── Query PostgreSQL
  │     │ → Write result to Redis (with TTL)
  │     │ → Return response
  │
  └── Return to client

Cache hit rate targets:
  - Home dashboard: > 95% (cached per household, 30-min TTL)
  - Asset list: > 90% (cached per household)
  - Notification count: > 80% (cached per user, 5-min TTL)
  - Product search: > 70% (cached per query hash)
  - User profile: > 95% (cached per user, 1-hour TTL)
```

### F.3 Database Optimization

| Technique | When to Apply |
|-----------|--------------|
| **Connection pooling** (PgBouncer) | Always (Phase 2+) — maintain 200 connections to DB, serve 10,000+ app connections |
| **Prepared statements** | Prisma handles this automatically |
| **Batch queries** | Dashboard: fetch assets + alerts + bookings in one query (or parallel queries) |
| **EXPLAIN ANALYZE** | Run on every query in your top 20 endpoints quarterly |
| **Materialized views** | Dashboard summary per household (refresh every 30 min) |
| **Table partitioning** | Tables > 100M rows (notifications, audit_logs) |
| **Vacuum/Analyze** | Auto-vacuum is on by default in RDS. Monitor dead tuples. |
| **pg_stat_statements** | Enable to find slow queries automatically |

### F.4 Scaling Step-by-Step

```
10K Users (Month 1-2):
  ✅ 1 Fargate task, 1 Postgres, 1 Redis
  ✅ Total cost: ~$200/month
  ✅ Focus: Get features right, not scale

100K Users (Month 3-6):
  ✅ 2-3 Fargate tasks behind ALB
  ✅ 1 Postgres + 1 read replica
  ✅ Redis for cache + sessions + rate limiting
  ✅ Total cost: ~$500/month
  ✅ Focus: Monitoring, identify bottlenecks

1M Users (Month 6-12):
  ✅ 5-8 Fargate tasks (auto-scaling)
  ✅ 1 Postgres primary + 2 read replicas
  ✅ PgBouncer for connection pooling
  ✅ Redis 3-node cluster
  ✅ BullMQ workers (separate tasks)
  ✅ Total cost: ~$3K/month
  ✅ Focus: Query optimization, caching strategy

10M Users (Month 12-24):
  ✅ Migrate to EKS (Kubernetes)
  ✅ Aurora PostgreSQL (auto-scaling storage)
  ✅ 5 read replicas
  ✅ ElasticSearch for product/asset search
  ✅ Partition notifications + audit_logs tables
  ✅ Total cost: ~$20K/month
  ✅ Focus: Extract first microservice (notifications)

50M Users (Month 24-36):
  ✅ Full microservices architecture
  ✅ Citus sharding by household_id
  ✅ Multi-AZ deployment
  ✅ Kafka for event bus
  ✅ CQRS for read-heavy endpoints
  ✅ Total cost: ~$100K/month
  ✅ Focus: Reliability, SLA guarantees

200M Users (Month 36+):
  ✅ Multi-region (US-East + US-West + US-Central)
  ✅ Aurora Global Database
  ✅ ElastiCache Global Datastore
  ✅ Event sourcing for claims + orders
  ✅ Data warehouse (Redshift) for analytics
  ✅ ML pipeline for predictive maintenance
  ✅ Total cost: ~$250K-$350K/month
  ✅ Focus: Predictive features, data moat, global expansion prep
```

---

## PART 3: BRUTALLY HONEST FINAL ADVICE

---

### Mistakes Beginners Make at This Stage

1. **Building the backend for 200M users before you have 200 users.** You have zero users. Your first 10K users don't care about Kubernetes, Kafka, or Citus sharding. They care if the app works, looks good, and solves their problem.

2. **Spending 6 months on architecture docs instead of shipping.** Your `ARCHITECTURE/00_FULL_ARCHITECTURE.md` is impressive — but it's theoretical. Not a single line of backend code exists. Architecture docs don't survive contact with reality. Ship, learn, iterate.

3. **Choosing microservices on day one.** Every single company that successfully runs microservices (Netflix, Uber, Airbnb) started with a monolith and extracted services as they grew. They had 100+ engineers before they needed microservices. You don't.

4. **Exposing API keys in client code.** Your OpenAI API key is in the Flutter app. This is not a "we'll fix it later" issue. This is a "someone will find it in week 1 and run up a $10K bill" issue. Fix it before anything else.

5. **Designing 30+ database tables before having one real user interaction.** Half of these tables will change once real users touch the product. Start with 8–10 core tables. Add the rest as features demand.

6. **No testing culture.** 7 test files for 308 source files. When you connect a real backend and real payments, bugs will cost real money. Every service method, every API endpoint, every state transition needs a test.

7. **Massive screen files.** A 2,465-line `HomeScreen` means every bug fix risks breaking 10 unrelated things. This is technical debt that compounds daily.

### What You Must NOT Do

1. **Do NOT build the admin panel yet.** You are the admin. Use a database client (pgAdmin, DBeaver) for the first 6 months.

2. **Do NOT implement all 9 service booking categories at once.** Launch with 2–3 (the most common: assembly, cleaning, home repairs). Add the rest based on demand.

3. **Do NOT build the shopping/trade-in flow first.** It requires the most complex backend (inventory, pricing, shipping, returns). Save it for Sprint 13+.

4. **Do NOT integrate Kafka, ElasticSearch, or event sourcing before 5M users.** These are solutions to problems you don't have yet.

5. **Do NOT skip the OTP flow.** Every US consumer app needs verified phone/email. This is your auth system — build it first, build it right.

6. **Do NOT store any payment card data yourself.** Stripe handles PCI compliance. Use Stripe.js/Elements exclusively. Never, ever let a card number touch your server.

7. **Do NOT delay crash reporting and analytics.** Integrate Sentry + Firebase Analytics in the Flutter app in Sprint 1. You need data from day one.

### What to Build First (Priority Order)

```
WEEK 1-2: Foundation
  ├── Backend project setup (Fastify + TypeScript + Prisma + Docker)
  ├── Move OpenAI calls to backend (SECURITY FIX — URGENT)
  ├── Integrate Sentry in Flutter app
  ├── Integrate Firebase Analytics in Flutter app
  └── Break HomeScreen.dart (2465 lines) into smaller widgets

WEEK 3-4: Authentication
  ├── Real OTP auth (Twilio SMS → verify → JWT)
  ├── Google Sign-In + Apple Sign-In
  ├── Token refresh flow (Dio interceptor)
  ├── flutter_secure_storage for tokens
  └── Auth state management (Riverpod)

WEEK 5-8: Core Data
  ├── User profile CRUD (real API)
  ├── Household CRUD (real API)
  ├── Asset CRUD (real API + S3 photo upload)
  ├── Replace all mock data with real API calls
  └── Drift local cache for offline support

WEEK 9-12: Value Features
  ├── Maintenance reminder engine (backend cron)
  ├── Asset health scoring (backend computation)
  ├── Push notifications (FCM)
  ├── Claims submission (real API)
  └── Basic service booking (2-3 categories)

WEEK 13-16: Monetization
  ├── Protection plan purchase (Stripe)
  ├── Payment method management
  ├── Basic shopping/checkout flow
  └── Installment plans (Stripe)

WEEK 17-20: Polish for App Store
  ├── Accessibility audit (WCAG AA)
  ├── Performance profiling (< 3s cold start, 60fps)
  ├── Test coverage > 70%
  ├── Privacy policy + Terms of Service
  ├── App Store / Play Store listing
  └── Beta testing (TestFlight + internal track)
```

### What Can Wait

| Feature | When | Why |
|---------|------|-----|
| Admin panel | After 10K users | You don't need a UI to manage 50 users |
| ElasticSearch | After 1M users | PostgreSQL full-text search is fine until then |
| Service booking (all 9 categories) | After validating 3 | See which categories users actually want |
| Shopping + trade-in | After core asset management is solid | Complex backend, low initial value |
| Multi-region | After 10M users | Single US region covers the entire US with < 80ms latency |
| Kubernetes | After 5M users | ECS Fargate is simpler and cheaper |
| Event sourcing / Kafka | After 50M users | BullMQ handles everything until then |
| ML-powered health scoring | After 1M assets registered | You need training data first |
| WebSocket real-time updates | After service booking is live | Push notifications cover 90% of use cases |
| Dark mode | After launch | Nice to have, not a launch blocker |
| Localization (non-English) | After US market dominance | US-only is fine for years |

---

## Summary

You have built an **impressive, feature-rich UI prototype** with 308 Dart files and 63 screens. The foundation is thoughtful — `Result<T>`, `BaseNotifier<T>`, `AppStrings` centralization, feature-based folders, GoRouter. These are the right patterns.

But you have **zero production readiness**. No backend, no auth, no real data, no tests, no monitoring, no security. The gap between "demo app" and "200M-user product" is 12–18 months of focused backend work, security hardening, testing, and operational maturity.

**Your #1 action item right now**: Move the OpenAI API key out of the client app and into a backend proxy. Today. Not tomorrow.

**Your #2 action item**: Set up the backend project (Fastify + Prisma + Docker) and implement auth. Everything else depends on this.

**Your #3 action item**: Break `HomeScreen.dart` (2,465 lines) and `AssetDetailScreen.dart` (1,914 lines) into smaller widgets. This is the kind of debt that makes every future change 3× harder.

Stop planning. Start shipping.
