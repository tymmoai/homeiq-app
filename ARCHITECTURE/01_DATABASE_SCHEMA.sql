-- ============================================================================
-- HomeIQ (SquareTrade) — Complete PostgreSQL Database Schema
-- Version: 1.0
-- Date: February 23, 2026
-- Scale Target: 200+ million users
-- ============================================================================

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";        -- Encryption functions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- Trigram similarity for search
CREATE EXTENSION IF NOT EXISTS "btree_gist";      -- GiST index support

-- ============================================================================
-- CUSTOM TYPES (ENUMS)
-- ============================================================================

-- Auth & Users
CREATE TYPE user_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE auth_provider AS ENUM ('email', 'google', 'apple');
CREATE TYPE otp_type AS ENUM ('sms', 'email');

-- Households & Family
CREATE TYPE member_role AS ENUM ('owner', 'admin', 'member', 'viewer');
CREATE TYPE member_status AS ENUM ('active', 'pending', 'removed');
CREATE TYPE invite_status AS ENUM ('pending', 'accepted', 'expired', 'revoked');
CREATE TYPE property_type AS ENUM ('house', 'apartment', 'condo', 'townhouse');

-- Assets
CREATE TYPE asset_status AS ENUM ('active', 'replaced', 'disposed', 'sold');
CREATE TYPE warranty_type AS ENUM ('manufacturer', 'extended', 'protection_plan');
CREATE TYPE warranty_status AS ENUM ('active', 'expired', 'claimed');
CREATE TYPE document_type AS ENUM ('receipt', 'manual', 'warranty_card', 'photo', 'invoice', 'other');
CREATE TYPE identification_method AS ENUM ('photo', 'manual');

-- Maintenance
CREATE TYPE maintenance_frequency AS ENUM ('monthly', 'quarterly', 'bi_annual', 'annual', 'seasonal', 'usage_based');
CREATE TYPE maintenance_category AS ENUM ('cleaning', 'inspection', 'replacement', 'service');
CREATE TYPE maintenance_status AS ENUM ('pending', 'completed', 'snoozed', 'skipped');
CREATE TYPE reminder_status AS ENUM ('upcoming', 'overdue', 'snoozed', 'completed', 'skipped');
CREATE TYPE reminder_priority AS ENUM ('low', 'medium', 'high');
CREATE TYPE skip_reason AS ENUM ('dont_know_how', 'not_needed', 'will_do_later');

-- Claims
CREATE TYPE claim_type AS ENUM ('repair', 'replacement', 'maintenance');
CREATE TYPE claim_status AS ENUM ('submitted', 'under_review', 'approved', 'in_progress', 'resolved', 'denied', 'closed');
CREATE TYPE resolution_type AS ENUM ('repaired', 'replaced', 'denied', 'pending_parts');

-- Bookings
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'technician_assigned', 'technician_on_way', 'in_progress', 'completed', 'canceled', 'rescheduled');
CREATE TYPE service_category_type AS ENUM ('home_service', 'lifestyle');
CREATE TYPE payment_mode AS ENUM ('pay_now', 'pay_on_visit');

-- Orders
CREATE TYPE order_type AS ENUM ('purchase', 'upgrade_trade_in', 'parts', 'protection_plan');
CREATE TYPE order_status AS ENUM ('placed', 'processing', 'shipped', 'out_for_delivery', 'delivered', 'installed', 'completed', 'canceled', 'returned');
CREATE TYPE trade_in_status AS ENUM ('pending', 'scheduled', 'picked_up', 'inspected', 'credited');
CREATE TYPE trade_in_condition AS ENUM ('excellent', 'good', 'fair', 'poor');

-- Payments
CREATE TYPE payment_method_type AS ENUM ('credit_card', 'debit_card', 'apple_pay', 'google_pay', 'bank_transfer');
CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'succeeded', 'failed', 'canceled', 'refunded');
CREATE TYPE billing_type AS ENUM ('monthly', 'yearly', 'one_time');
CREATE TYPE installment_status AS ENUM ('active', 'completed', 'defaulted');
CREATE TYPE installment_payment_status AS ENUM ('pending', 'paid', 'overdue');

-- Notifications & Alerts
CREATE TYPE notification_type AS ENUM (
  'booking_confirmed', 'order_confirmed', 'asset_added',
  'technician_on_way', 'service_reminder', 'payment_successful',
  'maintenance_due', 'maintenance_completed', 'plan_renewed',
  'warranty_expiring', 'claim_status_changed', 'invite_received',
  'system'
);
CREATE TYPE notification_channel AS ENUM ('push', 'email', 'sms', 'in_app');
CREATE TYPE alert_severity AS ENUM ('critical', 'warning', 'info');
CREATE TYPE alert_category AS ENUM ('warranty', 'service', 'maintenance', 'safety');

-- AI
CREATE TYPE ai_session_type AS ENUM ('troubleshoot', 'diy_guide', 'brand_lookup', 'nameplate_guide', 'subcategory_lookup');


-- ============================================================================
-- 1. AUTHENTICATION & USERS
-- ============================================================================

CREATE TABLE users (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email             VARCHAR(255) UNIQUE,
  phone             VARCHAR(20) UNIQUE,
  full_name         VARCHAR(100) NOT NULL,
  avatar_url        TEXT,
  language          VARCHAR(10) NOT NULL DEFAULT 'en-US',
  auth_provider     auth_provider NOT NULL DEFAULT 'email',
  auth_provider_id  VARCHAR(255),           -- Google sub or Apple user ID
  password_hash     VARCHAR(255),           -- bcrypt hash (null for social-only users)
  email_verified    BOOLEAN NOT NULL DEFAULT FALSE,
  phone_verified    BOOLEAN NOT NULL DEFAULT FALSE,
  status            user_status NOT NULL DEFAULT 'active',
  last_login_at     TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ,            -- Soft delete

  -- At least one of email or phone must exist
  CONSTRAINT users_email_or_phone CHECK (email IS NOT NULL OR phone IS NOT NULL),
  -- Provider ID required for social auth
  CONSTRAINT users_social_provider_id CHECK (
    (auth_provider = 'email') OR (auth_provider != 'email' AND auth_provider_id IS NOT NULL)
  )
);

CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_users_auth_provider ON users(auth_provider, auth_provider_id) WHERE auth_provider_id IS NOT NULL;
CREATE INDEX idx_users_status ON users(status) WHERE status != 'deleted';
CREATE INDEX idx_users_created_at ON users(created_at);


CREATE TABLE user_sessions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token   VARCHAR(255) NOT NULL,    -- SHA-256 hash of actual token
  device_info     JSONB,                     -- { os, model, appVersion, platform }
  ip_address      INET,
  user_agent      TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  expires_at      TIMESTAMPTZ NOT NULL,
  last_used_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_user ON user_sessions(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_sessions_token ON user_sessions(refresh_token);
CREATE INDEX idx_sessions_expires ON user_sessions(expires_at) WHERE is_active = TRUE;


CREATE TABLE otp_codes (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  identifier      VARCHAR(255) NOT NULL,    -- email or phone number
  code_hash       VARCHAR(255) NOT NULL,    -- SHA-256 hash of OTP
  type            otp_type NOT NULL,
  attempts        INT NOT NULL DEFAULT 0,
  max_attempts    INT NOT NULL DEFAULT 3,
  verified_at     TIMESTAMPTZ,
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_otp_identifier ON otp_codes(identifier, type) WHERE verified_at IS NULL;
CREATE INDEX idx_otp_expires ON otp_codes(expires_at);


-- ============================================================================
-- 2. HOUSEHOLDS & FAMILY MEMBERSHIP
-- ============================================================================

CREATE TABLE households (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            VARCHAR(100) NOT NULL,     -- "Mom's House", "My Apartment"
  address_line1   VARCHAR(255),
  address_line2   VARCHAR(255),
  city            VARCHAR(100),
  state           VARCHAR(50),
  zip_code        VARCHAR(10),
  country         VARCHAR(3) NOT NULL DEFAULT 'US',
  property_type   property_type,
  timezone        VARCHAR(50) DEFAULT 'America/New_York',
  created_by      UUID NOT NULL REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_households_created_by ON households(created_by);
CREATE INDEX idx_households_zip ON households(zip_code);


CREATE TABLE household_members (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role            member_role NOT NULL DEFAULT 'member',
  status          member_status NOT NULL DEFAULT 'active',
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(household_id, user_id)
);

CREATE INDEX idx_hm_household ON household_members(household_id) WHERE status = 'active';
CREATE INDEX idx_hm_user ON household_members(user_id) WHERE status = 'active';
CREATE INDEX idx_hm_role ON household_members(household_id, role);


CREATE TABLE household_invites (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  invited_by      UUID NOT NULL REFERENCES users(id),
  invited_email   VARCHAR(255) NOT NULL,
  invited_name    VARCHAR(100),
  role            member_role NOT NULL DEFAULT 'member',
  invite_token    VARCHAR(255) NOT NULL UNIQUE,  -- SHA-256 hash
  status          invite_status NOT NULL DEFAULT 'pending',
  accepted_by     UUID REFERENCES users(id),
  message         TEXT,                          -- Optional invite message
  expires_at      TIMESTAMPTZ NOT NULL,          -- Default: 7 days from creation
  accepted_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invites_token ON household_invites(invite_token) WHERE status = 'pending';
CREATE INDEX idx_invites_email ON household_invites(invited_email) WHERE status = 'pending';
CREATE INDEX idx_invites_household ON household_invites(household_id);
CREATE INDEX idx_invites_expires ON household_invites(expires_at) WHERE status = 'pending';


-- ============================================================================
-- 3. ASSETS
-- ============================================================================

CREATE TABLE asset_categories (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            VARCHAR(50) NOT NULL UNIQUE,  -- 'Appliances', 'Home Systems', 'Electronics'
  slug            VARCHAR(50) NOT NULL UNIQUE,  -- 'appliances', 'home_systems', 'electronics'
  icon_url        TEXT,
  display_order   INT NOT NULL DEFAULT 0,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE asset_subcategories (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id     UUID NOT NULL REFERENCES asset_categories(id),
  name            VARCHAR(100) NOT NULL,         -- 'Refrigerator', 'Television', 'HVAC System'
  slug            VARCHAR(100) NOT NULL,
  icon_url        TEXT,
  expected_lifespan_years INT,                   -- Average lifespan for health scoring
  display_order   INT NOT NULL DEFAULT 0,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(category_id, slug)
);

CREATE INDEX idx_subcategories_category ON asset_subcategories(category_id) WHERE is_active = TRUE;


CREATE TABLE assets (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  household_id        UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  added_by            UUID NOT NULL REFERENCES users(id),
  subcategory_id      UUID NOT NULL REFERENCES asset_subcategories(id),
  
  -- Identification
  brand               VARCHAR(100),
  model_number        VARCHAR(100),
  serial_number       VARCHAR(100),
  sub_category        VARCHAR(100),              -- Specific sub-category (e.g., "French Door" for Refrigerator)
  nickname            VARCHAR(100),              -- User-friendly name ("Kitchen Fridge")
  identification_method identification_method,
  
  -- Location & Purchase
  location_in_home    VARCHAR(100),              -- 'Kitchen', 'Living Room', 'Bedroom', 'Other'
  purchase_date       DATE,
  purchase_year       INT,
  purchase_month      INT,
  purchase_price      DECIMAL(10,2),
  retailer            VARCHAR(100),
  
  -- Status & Health
  health_score        DECIMAL(4,1) DEFAULT 0,    -- 0-100 (displayed as 1-10 in app by dividing by 10)
  risk_score          DECIMAL(4,1) DEFAULT 0,    -- 0-100
  status              asset_status NOT NULL DEFAULT 'active',
  lifecycle_status    VARCHAR(20) DEFAULT 'active',  -- 'active', 'replaced'
  
  -- Replacement chain
  replaced_by_asset_id  UUID REFERENCES assets(id),
  replaces_asset_id     UUID REFERENCES assets(id),
  replacement_date      DATE,
  
  -- Media
  image_url           TEXT,
  photo_path          TEXT,                      -- Original uploaded photo
  
  -- Timestamps
  last_service_date   DATE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ                -- Soft delete
);

CREATE INDEX idx_assets_household ON assets(household_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_assets_subcategory ON assets(subcategory_id);
CREATE INDEX idx_assets_status ON assets(household_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_assets_health ON assets(household_id, health_score) WHERE status = 'active';
CREATE INDEX idx_assets_brand ON assets(brand) WHERE brand IS NOT NULL;
CREATE INDEX idx_assets_search ON assets USING gin(
  (brand || ' ' || COALESCE(model_number, '') || ' ' || COALESCE(nickname, '')) gin_trgm_ops
);


CREATE TABLE asset_documents (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id        UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  document_type   document_type NOT NULL DEFAULT 'other',
  file_url        TEXT NOT NULL,                 -- S3 URL
  file_name       VARCHAR(255) NOT NULL,
  file_size       BIGINT,                        -- bytes
  mime_type       VARCHAR(100),
  uploaded_by     UUID NOT NULL REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documents_asset ON asset_documents(asset_id);


CREATE TABLE asset_warranties (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id          UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  warranty_type     warranty_type NOT NULL,
  provider_name     VARCHAR(100),                -- Manufacturer name or "SquareTrade"
  coverage_details  JSONB,                       -- { covered_items: [...], exclusions: [...] }
  start_date        DATE NOT NULL,
  end_date          DATE NOT NULL,
  status            warranty_status NOT NULL DEFAULT 'active',
  document_url      TEXT,                        -- Warranty document in S3
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_warranties_asset ON asset_warranties(asset_id);
CREATE INDEX idx_warranties_status ON asset_warranties(status, end_date);
CREATE INDEX idx_warranties_expiry ON asset_warranties(end_date) WHERE status = 'active';


-- ============================================================================
-- 4. PROTECTION PLANS
-- ============================================================================

CREATE TABLE protection_plan_templates (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name              VARCHAR(50) NOT NULL,          -- 'Essential', 'Premium', 'Ultimate'
  slug              VARCHAR(50) NOT NULL UNIQUE,   -- 'squaretrade-essential'
  tier              INT NOT NULL,                  -- 1, 2, 3 (for ordering)
  description       TEXT,
  
  -- Pricing
  monthly_price     DECIMAL(8,2) NOT NULL,
  yearly_price      DECIMAL(8,2) NOT NULL,
  one_time_price    DECIMAL(8,2),
  
  -- Coverage
  coverage_items    JSONB NOT NULL,                -- ["Mechanical failures", "Electrical issues", ...]
  deductible_options JSONB NOT NULL,               -- [0, 25, 50, 75, 100]
  max_claim_amount  DECIMAL(10,2),
  
  -- Meta
  is_popular        BOOLEAN NOT NULL DEFAULT FALSE,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  display_order     INT NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE user_protection_plans (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES users(id),
  asset_id              UUID NOT NULL REFERENCES assets(id),
  plan_template_id      UUID NOT NULL REFERENCES protection_plan_templates(id),
  
  -- Billing
  billing_type          billing_type NOT NULL,
  price                 DECIMAL(8,2) NOT NULL,
  price_label           VARCHAR(50),               -- "$12.99/month"
  deductible_amount     DECIMAL(8,2) NOT NULL DEFAULT 0,
  
  -- Coverage period
  coverage_start        DATE NOT NULL,
  coverage_end          DATE NOT NULL,
  
  -- Stripe
  stripe_subscription_id VARCHAR(255),
  stripe_customer_id     VARCHAR(255),
  
  -- Status
  is_active             BOOLEAN NOT NULL DEFAULT TRUE,
  auto_renew            BOOLEAN NOT NULL DEFAULT TRUE,
  canceled_at           TIMESTAMPTZ,
  
  -- Meta
  features              JSONB,                     -- Cached from template at time of purchase
  provider              VARCHAR(50) DEFAULT 'SquareTrade',
  purchased_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_plans_user ON user_protection_plans(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_plans_asset ON user_protection_plans(asset_id) WHERE is_active = TRUE;
CREATE INDEX idx_plans_expiry ON user_protection_plans(coverage_end) WHERE is_active = TRUE;
CREATE INDEX idx_plans_stripe ON user_protection_plans(stripe_subscription_id) WHERE stripe_subscription_id IS NOT NULL;


-- ============================================================================
-- 5. MAINTENANCE
-- ============================================================================

CREATE TABLE maintenance_templates (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subcategory_id        UUID NOT NULL REFERENCES asset_subcategories(id),
  task_name             VARCHAR(100) NOT NULL,       -- "Filter Replacement", "Gasket Cleaning"
  description           TEXT,
  why_it_matters        TEXT,
  safety_note           TEXT,
  category              maintenance_category NOT NULL DEFAULT 'cleaning',
  frequency             maintenance_frequency NOT NULL DEFAULT 'quarterly',
  interval_days         INT NOT NULL,                -- Actual interval in days
  estimated_time_minutes INT,
  estimated_effort      VARCHAR(50),                 -- "15 minutes", "30 minutes"
  priority              reminder_priority NOT NULL DEFAULT 'medium',
  display_order         INT NOT NULL DEFAULT 0,
  is_active             BOOLEAN NOT NULL DEFAULT TRUE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_maint_templates_subcategory ON maintenance_templates(subcategory_id) WHERE is_active = TRUE;


CREATE TABLE maintenance_reminders (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id            UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  household_id        UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  template_id         UUID REFERENCES maintenance_templates(id),
  
  -- Task info (denormalized for performance)
  task_name           VARCHAR(100) NOT NULL,
  task_description    TEXT,
  why_it_matters      TEXT,
  estimated_effort    VARCHAR(50),
  safety_note         TEXT,
  
  -- Scheduling
  due_date            DATE NOT NULL,
  status              reminder_status NOT NULL DEFAULT 'upcoming',
  priority            reminder_priority NOT NULL DEFAULT 'medium',
  risk_level          VARCHAR(20),                  -- "Low", "Medium", "High"
  
  -- Resolution
  completed_date      DATE,
  snoozed_until       DATE,
  skip_reason         skip_reason,
  
  -- Meta
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reminders_asset ON maintenance_reminders(asset_id);
CREATE INDEX idx_reminders_household ON maintenance_reminders(household_id);
CREATE INDEX idx_reminders_status ON maintenance_reminders(household_id, status, due_date);
CREATE INDEX idx_reminders_due ON maintenance_reminders(due_date) WHERE status IN ('upcoming', 'overdue');
CREATE INDEX idx_reminders_overdue ON maintenance_reminders(household_id, due_date) WHERE status = 'overdue';


CREATE TABLE maintenance_records (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reminder_id     UUID REFERENCES maintenance_reminders(id),
  asset_id        UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  task_id         VARCHAR(100),                  -- Reference to template
  task_name       VARCHAR(100) NOT NULL,
  performed_by    UUID REFERENCES users(id),
  action          maintenance_status NOT NULL,   -- 'completed' or 'skipped'
  skip_reason     skip_reason,
  notes           TEXT,
  evidence_url    TEXT,                          -- Photo evidence S3 URL
  scheduled_date  DATE,
  performed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_records_asset ON maintenance_records(asset_id);
CREATE INDEX idx_records_reminder ON maintenance_records(reminder_id);
CREATE INDEX idx_records_performed ON maintenance_records(asset_id, performed_at);


CREATE TABLE asset_health_scores (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id            UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  health_score        DECIMAL(4,1) NOT NULL,       -- 0-100
  risk_score          DECIMAL(4,1) NOT NULL,        -- 0-100
  
  -- Factor breakdown
  age_factor          DECIMAL(4,1),
  maintenance_rate    DECIMAL(4,1),                 -- % of tasks completed on time
  issue_history       DECIMAL(4,1),
  brand_reliability   DECIMAL(4,1),
  
  -- Recommendation
  recommendation      VARCHAR(20),                  -- 'maintain', 'repair', 'replace'
  recommendation_confidence INT,                    -- 0-100
  recommendation_reasoning TEXT,
  estimated_failure_window VARCHAR(50),
  replacement_urgency VARCHAR(20),                  -- 'low', 'medium', 'high'
  
  computed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(asset_id)  -- One current score per asset (upsert)
);

CREATE INDEX idx_health_asset ON asset_health_scores(asset_id);


-- ============================================================================
-- 6. CLAIMS
-- ============================================================================

CREATE TABLE claims (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  claim_number        VARCHAR(20) NOT NULL UNIQUE,  -- CLM-yyyy-nnnn
  user_id             UUID NOT NULL REFERENCES users(id),
  asset_id            UUID NOT NULL REFERENCES assets(id),
  household_id        UUID NOT NULL REFERENCES households(id),
  protection_plan_id  UUID REFERENCES user_protection_plans(id),
  
  -- Claim details
  claim_type          claim_type NOT NULL,
  title               VARCHAR(255) NOT NULL,
  description         TEXT,
  issue_category      VARCHAR(50),                   -- 'Cooling Issue', 'Leakage Issue', etc.
  
  -- Status
  status              claim_status NOT NULL DEFAULT 'submitted',
  
  -- Asset info (denormalized for display)
  asset_name          VARCHAR(100),
  asset_brand         VARCHAR(100),
  asset_location      VARCHAR(100),
  asset_type          VARCHAR(100),
  
  -- Coverage
  warranty_status     VARCHAR(50),
  plan_name           VARCHAR(50),
  is_covered          BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Financial
  estimated_cost      DECIMAL(10,2),
  approved_amount     DECIMAL(10,2),
  deductible          DECIMAL(10,2),
  
  -- Resolution
  resolution_notes    TEXT,
  resolution_type     resolution_type,
  
  -- Related entities
  linked_booking_id   VARCHAR(50),                   -- Linked service booking
  technician_name     VARCHAR(100),
  
  -- Timestamps
  submitted_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at         TIMESTAMPTZ,
  approved_at         TIMESTAMPTZ,
  in_progress_at      TIMESTAMPTZ,
  resolved_at         TIMESTAMPTZ,
  closed_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_claims_user ON claims(user_id);
CREATE INDEX idx_claims_asset ON claims(asset_id);
CREATE INDEX idx_claims_household ON claims(household_id);
CREATE INDEX idx_claims_status ON claims(user_id, status);
CREATE INDEX idx_claims_number ON claims(claim_number);
CREATE INDEX idx_claims_submitted ON claims(submitted_at);


CREATE TABLE claim_status_history (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  claim_id        UUID NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
  from_status     claim_status,
  to_status       claim_status NOT NULL,
  changed_by      UUID REFERENCES users(id),        -- NULL = system
  notes           TEXT,
  changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_claim_history ON claim_status_history(claim_id, changed_at);


CREATE TABLE claim_documents (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  claim_id        UUID NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
  file_url        TEXT NOT NULL,
  file_name       VARCHAR(255),
  file_type       VARCHAR(50),                      -- 'image/jpeg', 'application/pdf'
  file_size       BIGINT,
  uploaded_by     UUID NOT NULL REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_claim_docs ON claim_documents(claim_id);


-- ============================================================================
-- 7. SERVICE BOOKINGS
-- ============================================================================

CREATE TABLE service_categories (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            VARCHAR(50) NOT NULL,              -- 'Assembly', 'Mounting', 'Moving', etc.
  slug            VARCHAR(50) NOT NULL UNIQUE,
  type            service_category_type NOT NULL DEFAULT 'home_service',
  prefix          VARCHAR(5) NOT NULL,               -- 'BK', 'MNT', 'MOV', 'CL', 'OH', 'HR', 'PT', 'SC', 'HQ'
  base_price      DECIMAL(8,2) NOT NULL,
  icon_url        TEXT,
  description     TEXT,
  display_order   INT NOT NULL DEFAULT 0,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE service_providers (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                VARCHAR(100) NOT NULL,
  category_id         UUID NOT NULL REFERENCES service_categories(id),
  
  -- Rating & Experience
  rating              DECIMAL(2,1) NOT NULL DEFAULT 0,   -- 0.0-5.0
  total_reviews       INT NOT NULL DEFAULT 0,
  experience_years    INT,
  total_jobs          INT NOT NULL DEFAULT 0,
  
  -- Pricing
  hourly_rate         DECIMAL(8,2),
  visit_fee           DECIMAL(8,2),
  
  -- Coverage
  service_area_zips   TEXT[],                         -- Array of zip codes served
  
  -- Profile
  avatar_url          TEXT,
  bio                 TEXT,
  certifications      TEXT[],
  
  -- Status
  is_verified         BOOLEAN NOT NULL DEFAULT FALSE,
  is_available        BOOLEAN NOT NULL DEFAULT TRUE,
  status              VARCHAR(20) NOT NULL DEFAULT 'active',
  
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_providers_category ON service_providers(category_id) WHERE status = 'active';
CREATE INDEX idx_providers_rating ON service_providers(category_id, rating DESC);
CREATE INDEX idx_providers_zips ON service_providers USING gin(service_area_zips);


CREATE TABLE service_bookings (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_number      VARCHAR(20) NOT NULL UNIQUE,   -- HQyyyy-MMDD-nnnn
  user_id             UUID NOT NULL REFERENCES users(id),
  household_id        UUID NOT NULL REFERENCES households(id),
  category_id         UUID NOT NULL REFERENCES service_categories(id),
  provider_id         UUID REFERENCES service_providers(id),
  asset_id            UUID REFERENCES assets(id),    -- If linked to a specific asset
  
  -- Service details (flexible per category)
  service_type        VARCHAR(50) NOT NULL,           -- 'assembly', 'mounting', etc.
  service_name        VARCHAR(100),
  service_details     JSONB NOT NULL DEFAULT '{}',    -- Category-specific: items, quantities, addons, etc.
  /*
    Assembly:  { items: {"Bookshelf": 2}, addons: ["Wall Anchoring"], propertyType: "house" }
    Moving:    { homeType: "house", homeSize: "2 Bedroom", rooms: 3, floor: 2, hasElevator: false, 
                 pickupAddress: "...", dropoffAddress: "...", distance: 15.5, packingLevel: "Full" }
    Cleaning:  { frequency: "Weekly", intensity: "Deep", condition: "Regular", items: {"Full Home 2BHK": 1} }
    Mounting:  { wallType: "Drywall", mountingHeight: "Standard", items: {"55\" TV": 1} }
    Painting:  { paintType: "Interior", surfaceCondition: "Good", items: {"Large Room": 2} }
    Security:  { deviceBrand: "Ring", existingSystem: "None", items: {"Security Camera": 3} }
    Repairs:   { urgency: "Same Day", diagnosticFee: 89, items: {"Leaky Faucet": 1} }
    Outdoor:   { condition: "Moderate", items: {"Medium Lawn": 1}, frequency: "Monthly" }
    Lifestyle: { selectedService: "Cab", pickupLocation: "...", vehicleType: "SUV", ... }
  */
  
  -- Scheduling
  scheduled_date      DATE NOT NULL,
  scheduled_time_slot VARCHAR(50),                    -- "9 AM - 12 PM"
  date_selection_type VARCHAR(20),                    -- 'today', 'tomorrow', 'custom'
  estimated_arrival   TIMESTAMPTZ,
  actual_arrival      TIMESTAMPTZ,
  service_start_time  TIMESTAMPTZ,
  service_end_time    TIMESTAMPTZ,
  
  -- Contact & Address
  contact_name        VARCHAR(100),
  contact_email       VARCHAR(255),
  contact_phone       VARCHAR(20),
  service_address     JSONB,                          -- { line1, line2, city, state, zip, apartment }
  photo_urls          TEXT[],                          -- Uploaded photos for context
  special_requirements TEXT,
  
  -- Status
  status              booking_status NOT NULL DEFAULT 'pending',
  status_updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Payment
  payment_mode        payment_mode NOT NULL DEFAULT 'pay_now',
  payment_status      payment_status NOT NULL DEFAULT 'pending',
  items_total         DECIMAL(10,2) NOT NULL DEFAULT 0,
  service_fee         DECIMAL(10,2) NOT NULL DEFAULT 0,
  visit_fee           DECIMAL(10,2) NOT NULL DEFAULT 0,
  parts_cost          DECIMAL(10,2),
  service_charge      DECIMAL(10,2),
  tax_amount          DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_amount        DECIMAL(10,2) NOT NULL DEFAULT 0,
  
  -- Terms
  terms_accepted      BOOLEAN NOT NULL DEFAULT FALSE,
  terms_accepted_at   TIMESTAMPTZ,
  
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bookings_user ON service_bookings(user_id);
CREATE INDEX idx_bookings_household ON service_bookings(household_id);
CREATE INDEX idx_bookings_status ON service_bookings(user_id, status);
CREATE INDEX idx_bookings_date ON service_bookings(scheduled_date);
CREATE INDEX idx_bookings_provider ON service_bookings(provider_id) WHERE provider_id IS NOT NULL;
CREATE INDEX idx_bookings_number ON service_bookings(booking_number);
CREATE INDEX idx_bookings_category ON service_bookings(category_id);


CREATE TABLE booking_status_history (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id      UUID NOT NULL REFERENCES service_bookings(id) ON DELETE CASCADE,
  from_status     booking_status,
  to_status       booking_status NOT NULL,
  changed_by      UUID REFERENCES users(id),
  reason          TEXT,                             -- e.g., cancel reason, reschedule reason
  new_date        DATE,                             -- For reschedule
  new_time_slot   VARCHAR(50),                      -- For reschedule
  changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_booking_history ON booking_status_history(booking_id, changed_at);


-- ============================================================================
-- 8. PRODUCTS & SHOPPING
-- ============================================================================

CREATE TABLE products (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subcategory_id      UUID NOT NULL REFERENCES asset_subcategories(id),
  
  -- Product info
  brand               VARCHAR(100) NOT NULL,
  model               VARCHAR(100),
  name                VARCHAR(255) NOT NULL,
  description         TEXT,
  
  -- Pricing
  price               DECIMAL(10,2) NOT NULL,
  sale_price          DECIMAL(10,2),
  
  -- Features
  features            JSONB,                        -- { "Capacity": "25 cu ft", "Energy Star": true, ... }
  is_energy_star      BOOLEAN NOT NULL DEFAULT FALSE,
  is_smart            BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Media
  image_urls          TEXT[] NOT NULL DEFAULT '{}',
  
  -- Ratings
  rating              DECIMAL(2,1) NOT NULL DEFAULT 0,
  review_count        INT NOT NULL DEFAULT 0,
  
  -- Availability
  stock_status        VARCHAR(20) NOT NULL DEFAULT 'in_stock', -- 'in_stock', 'low_stock', 'out_of_stock'
  estimated_delivery_days INT,
  
  -- Trade-in eligible
  trade_in_eligible   BOOLEAN NOT NULL DEFAULT TRUE,
  estimated_trade_in_min DECIMAL(10,2),
  estimated_trade_in_max DECIMAL(10,2),
  
  -- Meta
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  display_order       INT NOT NULL DEFAULT 0,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_subcategory ON products(subcategory_id) WHERE is_active = TRUE;
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_rating ON products(rating DESC);
CREATE INDEX idx_products_search ON products USING gin(
  (brand || ' ' || name || ' ' || COALESCE(model, '')) gin_trgm_ops
);


-- ============================================================================
-- 9. ORDERS
-- ============================================================================

CREATE TABLE orders (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number        VARCHAR(25) NOT NULL UNIQUE,   -- HQ-ORD-yyyy-nnnn
  user_id             UUID NOT NULL REFERENCES users(id),
  household_id        UUID NOT NULL REFERENCES households(id),
  
  -- Order type
  order_type          order_type NOT NULL,
  
  -- Items
  items               JSONB NOT NULL,                 -- [{ product_id, name, brand, model, qty, price, image }]
  
  -- Pricing
  subtotal            DECIMAL(10,2) NOT NULL,
  tax_amount          DECIMAL(10,2) NOT NULL DEFAULT 0,
  shipping_cost       DECIMAL(10,2) NOT NULL DEFAULT 0,
  trade_in_credit     DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount_amount     DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_amount        DECIMAL(10,2) NOT NULL,
  
  -- Shipping
  shipping_address    JSONB,                          -- { line1, line2, city, state, zip }
  tracking_number     VARCHAR(100),
  carrier             VARCHAR(50),                    -- 'USPS', 'UPS', 'FedEx'
  
  -- Status
  status              order_status NOT NULL DEFAULT 'placed',
  estimated_delivery  DATE,
  actual_delivery     DATE,
  
  -- Installation (for upgrade orders)
  requires_installation BOOLEAN NOT NULL DEFAULT FALSE,
  installation_booking_id UUID REFERENCES service_bookings(id),
  installation_date   DATE,
  installation_status VARCHAR(20),
  
  -- Payment
  payment_intent_id   VARCHAR(255),                   -- Stripe payment intent
  payment_status      payment_status NOT NULL DEFAULT 'pending',
  installment_plan_id UUID,                           -- FK added after installment_plans table
  
  -- Parts order specific
  part_category       VARCHAR(100),                   -- For parts orders
  compatible_with     VARCHAR(100),                   -- "Compatible with Samsung RT-5000"
  
  -- Timestamps
  ordered_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  shipped_at          TIMESTAMPTZ,
  delivered_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_household ON orders(household_id);
CREATE INDEX idx_orders_status ON orders(user_id, status);
CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_type ON orders(order_type);
CREATE INDEX idx_orders_ordered ON orders(ordered_at);


CREATE TABLE order_status_history (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  from_status     order_status,
  to_status       order_status NOT NULL,
  title           VARCHAR(100),
  description     TEXT,
  changed_by      UUID REFERENCES users(id),
  changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_history ON order_status_history(order_id, changed_at);


CREATE TABLE trade_ins (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id            UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  old_asset_id        UUID NOT NULL REFERENCES assets(id),
  old_asset_name      VARCHAR(100),
  
  -- Valuation
  estimated_value     DECIMAL(10,2) NOT NULL,
  condition           trade_in_condition,
  adjusted_value      DECIMAL(10,2),                  -- After inspection
  
  -- Status
  status              trade_in_status NOT NULL DEFAULT 'pending',
  
  -- Pickup scheduling
  pickup_date         DATE,
  actual_pickup       DATE,
  
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trade_ins_order ON trade_ins(order_id);
CREATE INDEX idx_trade_ins_asset ON trade_ins(old_asset_id);


-- ============================================================================
-- 10. PAYMENTS
-- ============================================================================

CREATE TABLE payment_methods (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Stripe
  stripe_payment_method_id VARCHAR(255) NOT NULL,
  stripe_customer_id  VARCHAR(255),
  
  -- Display info (safe to store — not sensitive)
  type                payment_method_type NOT NULL,
  brand               VARCHAR(20),                    -- 'visa', 'mastercard', 'amex', 'discover'
  last_four           VARCHAR(4) NOT NULL,
  exp_month           INT NOT NULL,
  exp_year            INT NOT NULL,
  cardholder_name     VARCHAR(100),
  
  -- Flags
  is_default          BOOLEAN NOT NULL DEFAULT FALSE,
  
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_methods_user ON payment_methods(user_id);
CREATE UNIQUE INDEX idx_payment_methods_default ON payment_methods(user_id) WHERE is_default = TRUE;


CREATE TABLE payments (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID NOT NULL REFERENCES users(id),
  
  -- Polymorphic reference: what was paid for
  payable_type        VARCHAR(50) NOT NULL,            -- 'order', 'booking', 'protection_plan'
  payable_id          UUID NOT NULL,                   -- FK to orders.id / service_bookings.id / user_protection_plans.id
  
  -- Amount
  amount              DECIMAL(10,2) NOT NULL,
  currency            VARCHAR(3) NOT NULL DEFAULT 'USD',
  
  -- Stripe
  stripe_payment_intent_id VARCHAR(255),
  stripe_charge_id    VARCHAR(255),
  payment_method_id   UUID REFERENCES payment_methods(id),
  
  -- Status
  status              payment_status NOT NULL DEFAULT 'pending',
  error_message       TEXT,
  
  -- Refund
  refunded_amount     DECIMAL(10,2) DEFAULT 0,
  refund_reason       TEXT,
  
  -- Meta
  metadata            JSONB,                            -- Additional context
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_payable ON payments(payable_type, payable_id);
CREATE INDEX idx_payments_stripe ON payments(stripe_payment_intent_id) WHERE stripe_payment_intent_id IS NOT NULL;
CREATE INDEX idx_payments_status ON payments(status);


CREATE TABLE installment_plans (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id                UUID NOT NULL REFERENCES orders(id),
  user_id                 UUID NOT NULL REFERENCES users(id),
  
  total_amount            DECIMAL(10,2) NOT NULL,
  num_installments        INT NOT NULL,
  amount_per_installment  DECIMAL(10,2) NOT NULL,
  interest_rate           DECIMAL(5,2) NOT NULL DEFAULT 0,   -- 0 = interest-free
  
  status                  installment_status NOT NULL DEFAULT 'active',
  
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add FK from orders to installment_plans
ALTER TABLE orders ADD CONSTRAINT fk_orders_installment 
  FOREIGN KEY (installment_plan_id) REFERENCES installment_plans(id);

CREATE INDEX idx_installments_order ON installment_plans(order_id);
CREATE INDEX idx_installments_user ON installment_plans(user_id) WHERE status = 'active';


CREATE TABLE installment_payments (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id             UUID NOT NULL REFERENCES installment_plans(id) ON DELETE CASCADE,
  installment_number  INT NOT NULL,
  amount              DECIMAL(10,2) NOT NULL,
  due_date            DATE NOT NULL,
  paid_date           DATE,
  status              installment_payment_status NOT NULL DEFAULT 'pending',
  stripe_payment_id   VARCHAR(255),
  
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_inst_payments_plan ON installment_payments(plan_id);
CREATE INDEX idx_inst_payments_due ON installment_payments(due_date) WHERE status = 'pending';


-- ============================================================================
-- 11. NOTIFICATIONS & ALERTS
-- ============================================================================

CREATE TABLE push_tokens (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token           TEXT NOT NULL,
  platform        VARCHAR(10) NOT NULL,              -- 'ios', 'android', 'web'
  device_id       VARCHAR(255),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(user_id, token)
);

CREATE INDEX idx_push_tokens_user ON push_tokens(user_id) WHERE is_active = TRUE;


CREATE TABLE notifications (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Content
  type            notification_type NOT NULL,
  title           VARCHAR(255) NOT NULL,
  body            TEXT NOT NULL,
  icon            VARCHAR(50),                       -- Icon name/identifier
  
  -- Deep link data
  data            JSONB,                             -- { route: "/orders/123", orderId: "123" }
  
  -- Status
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  
  -- Delivery tracking
  push_sent       BOOLEAN NOT NULL DEFAULT FALSE,
  push_sent_at    TIMESTAMPTZ,
  email_sent      BOOLEAN NOT NULL DEFAULT FALSE,
  email_sent_at   TIMESTAMPTZ,
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Partition notifications by month for performance at scale
-- CREATE TABLE notifications (...) PARTITION BY RANGE (created_at);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_type ON notifications(user_id, type);
CREATE INDEX idx_notifications_created ON notifications(created_at);


CREATE TABLE critical_alerts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  asset_id        UUID REFERENCES assets(id),
  
  -- Alert details
  type            alert_category NOT NULL,
  severity        alert_severity NOT NULL,
  title           VARCHAR(255) NOT NULL,
  message         TEXT NOT NULL,
  
  -- Denormalized asset info for display
  asset_name      VARCHAR(100),
  asset_category  VARCHAR(50),
  asset_location  VARCHAR(100),
  
  -- Action
  action_label    VARCHAR(50),                       -- "Renew", "View", "Book Inspector", "Schedule Service"
  action_route    VARCHAR(255),                      -- Deep link route
  
  -- Status
  is_dismissed    BOOLEAN NOT NULL DEFAULT FALSE,
  dismissed_at    TIMESTAMPTZ,
  dismissed_by    UUID REFERENCES users(id),
  
  -- Expiry tracking
  is_expired      BOOLEAN NOT NULL DEFAULT FALSE,
  is_overdue      BOOLEAN NOT NULL DEFAULT FALSE,
  alert_date      DATE,                              -- When the alert condition occurred
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_household ON critical_alerts(household_id) WHERE is_dismissed = FALSE;
CREATE INDEX idx_alerts_severity ON critical_alerts(household_id, severity) WHERE is_dismissed = FALSE;
CREATE INDEX idx_alerts_asset ON critical_alerts(asset_id) WHERE asset_id IS NOT NULL;


-- ============================================================================
-- 12. NOTIFICATION PREFERENCES
-- ============================================================================

CREATE TABLE notification_preferences (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  
  -- Channel toggles
  email_enabled           BOOLEAN NOT NULL DEFAULT TRUE,
  sms_enabled             BOOLEAN NOT NULL DEFAULT TRUE,
  push_enabled            BOOLEAN NOT NULL DEFAULT TRUE,
  in_app_enabled          BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Category toggles
  maintenance_reminders   BOOLEAN NOT NULL DEFAULT TRUE,
  service_bookings        BOOLEAN NOT NULL DEFAULT TRUE,
  asset_alerts            BOOLEAN NOT NULL DEFAULT TRUE,
  order_updates           BOOLEAN NOT NULL DEFAULT TRUE,
  payment_updates         BOOLEAN NOT NULL DEFAULT TRUE,
  plan_updates            BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Maintenance preferences
  auto_schedule           BOOLEAN NOT NULL DEFAULT TRUE,
  health_score_threshold  DECIMAL(4,1) DEFAULT 50,     -- Alert when below this
  advance_notice_days     INT DEFAULT 7,
  
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notif_prefs_user ON notification_preferences(user_id);


-- ============================================================================
-- 13. USER PREFERENCES / SETTINGS
-- ============================================================================

CREATE TABLE user_settings (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  
  -- Theme
  theme             VARCHAR(10) NOT NULL DEFAULT 'light',   -- 'light', 'dark', 'system'
  color_theme       VARCHAR(20) NOT NULL DEFAULT 'default',
  
  -- Locale
  language          VARCHAR(10) NOT NULL DEFAULT 'en',
  date_format       VARCHAR(20) NOT NULL DEFAULT 'MM/DD/YYYY',
  time_format       VARCHAR(5) NOT NULL DEFAULT '12h',       -- '12h' or '24h'
  
  -- Default home
  default_home_id   UUID REFERENCES households(id),
  
  -- Feature flags
  biometrics_enabled      BOOLEAN NOT NULL DEFAULT FALSE,
  analytics_enabled       BOOLEAN NOT NULL DEFAULT TRUE,
  crash_reporting_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_settings_user ON user_settings(user_id);


-- ============================================================================
-- 14. AI SESSIONS (USAGE TRACKING)
-- ============================================================================

CREATE TABLE ai_sessions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id),
  asset_id        UUID REFERENCES assets(id),
  
  session_type    ai_session_type NOT NULL,
  
  -- Input/Output
  input_data      JSONB NOT NULL,                    -- Request payload
  output_data     JSONB,                             -- Response data
  
  -- Cost tracking
  model_used      VARCHAR(50) NOT NULL DEFAULT 'gpt-4o-mini',
  tokens_input    INT,
  tokens_output   INT,
  tokens_total    INT,
  cost_cents      INT,                               -- Cost in cents
  
  -- Performance
  response_time_ms INT,
  is_cached       BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Status
  is_success      BOOLEAN NOT NULL DEFAULT TRUE,
  error_message   TEXT,
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_sessions_user ON ai_sessions(user_id, created_at DESC);
CREATE INDEX idx_ai_sessions_type ON ai_sessions(session_type, created_at DESC);
CREATE INDEX idx_ai_sessions_cost ON ai_sessions(created_at, cost_cents);


-- ============================================================================
-- 15. AUDIT LOG (SECURITY-CRITICAL ACTIONS)
-- ============================================================================

CREATE TABLE audit_logs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id),
  action          VARCHAR(50) NOT NULL,               -- 'login', 'logout', 'password_change', 'payment', 'claim_status_change', 'member_invite', 'member_remove'
  resource_type   VARCHAR(50),                        -- 'user', 'household', 'asset', 'claim', 'order', 'booking', 'payment'
  resource_id     UUID,
  ip_address      INET,
  user_agent      TEXT,
  details         JSONB,                              -- Action-specific details
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Partition audit logs by month for performance
-- CREATE TABLE audit_logs (...) PARTITION BY RANGE (created_at);

CREATE INDEX idx_audit_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_action ON audit_logs(action, created_at DESC);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at);


-- ============================================================================
-- 16. SEQUENCE COUNTERS (FOR HUMAN-READABLE IDs)
-- ============================================================================

CREATE TABLE id_counters (
  prefix          VARCHAR(10) PRIMARY KEY,           -- 'CLM', 'ORD', 'BKG'
  current_year    INT NOT NULL,
  current_value   INT NOT NULL DEFAULT 0
);

-- Initialize counters
INSERT INTO id_counters (prefix, current_year, current_value) VALUES
  ('CLM', 2026, 0),
  ('ORD', 2026, 0),
  ('BKG', 2026, 0);

-- Function to generate next ID
CREATE OR REPLACE FUNCTION next_sequential_id(p_prefix VARCHAR, p_separator VARCHAR DEFAULT '-')
RETURNS VARCHAR AS $$
DECLARE
  v_year INT;
  v_next INT;
BEGIN
  v_year := EXTRACT(YEAR FROM NOW());
  
  -- Reset counter if year changed
  UPDATE id_counters 
  SET current_value = CASE WHEN current_year = v_year THEN current_value + 1 ELSE 1 END,
      current_year = v_year
  WHERE prefix = p_prefix
  RETURNING current_value INTO v_next;
  
  -- Handle booking format: HQyyyy-MMDD-nnnn
  IF p_prefix = 'BKG' THEN
    RETURN 'HQ' || v_year || '-' || TO_CHAR(NOW(), 'MMDD') || '-' || LPAD(v_next::TEXT, 4, '0');
  END IF;
  
  -- Standard format: PREFIX-yyyy-nnnn
  IF p_prefix = 'ORD' THEN
    RETURN 'HQ-ORD-' || v_year || p_separator || LPAD(v_next::TEXT, 4, '0');
  END IF;
  
  RETURN p_prefix || p_separator || v_year || p_separator || LPAD(v_next::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 17. UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN 
    SELECT table_name FROM information_schema.columns 
    WHERE column_name = 'updated_at' 
    AND table_schema = 'public'
  LOOP
    EXECUTE format('
      CREATE TRIGGER trg_%s_updated_at
      BEFORE UPDATE ON %I
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column()', t, t);
  END LOOP;
END $$;


-- ============================================================================
-- 18. SEED DATA — CATEGORIES
-- ============================================================================

-- Asset Categories
INSERT INTO asset_categories (id, name, slug, display_order) VALUES
  (uuid_generate_v4(), 'Appliances', 'appliances', 1),
  (uuid_generate_v4(), 'Home Systems', 'home_systems', 2),
  (uuid_generate_v4(), 'Electronics', 'electronics', 3);

-- Asset Subcategories (with expected lifespans for health scoring)
INSERT INTO asset_subcategories (id, category_id, name, slug, expected_lifespan_years, display_order) VALUES
  -- Appliances
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'appliances'), 'Refrigerator', 'refrigerator', 15, 1),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'appliances'), 'Washing Machine', 'washing_machine', 12, 2),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'appliances'), 'Air Conditioner', 'air_conditioner', 15, 3),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'appliances'), 'Microwave', 'microwave', 10, 4),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'appliances'), 'Dishwasher', 'dishwasher', 12, 5),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'appliances'), 'Dryer', 'dryer', 13, 6),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'appliances'), 'Oven', 'oven', 15, 7),
  -- Home Systems
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'home_systems'), 'HVAC System', 'hvac_system', 20, 1),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'home_systems'), 'Water Heater', 'water_heater', 12, 2),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'home_systems'), 'Garbage Disposal', 'garbage_disposal', 10, 3),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'home_systems'), 'Garage Door Opener', 'garage_door_opener', 15, 4),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'home_systems'), 'Water Softener', 'water_softener', 15, 5),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'home_systems'), 'Sump Pump', 'sump_pump', 10, 6),
  -- Electronics
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'electronics'), 'Television', 'television', 8, 1),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'electronics'), 'Computer', 'computer', 6, 2),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'electronics'), 'Audio System', 'audio_system', 10, 3),
  (uuid_generate_v4(), (SELECT id FROM asset_categories WHERE slug = 'electronics'), 'Smart Device', 'smart_device', 5, 4);

-- Service Categories
INSERT INTO service_categories (id, name, slug, type, prefix, base_price, display_order) VALUES
  (uuid_generate_v4(), 'Assembly', 'assembly', 'home_service', 'BK', 55.00, 1),
  (uuid_generate_v4(), 'Mounting', 'mounting', 'home_service', 'MNT', 49.00, 2),
  (uuid_generate_v4(), 'Moving', 'moving', 'home_service', 'MOV', 60.00, 3),
  (uuid_generate_v4(), 'Cleaning', 'cleaning', 'home_service', 'CL', 50.00, 4),
  (uuid_generate_v4(), 'Outdoor', 'outdoor', 'home_service', 'OH', 50.00, 5),
  (uuid_generate_v4(), 'Home Repairs', 'home_repairs', 'home_service', 'HR', 65.00, 6),
  (uuid_generate_v4(), 'Painting', 'painting', 'home_service', 'PT', 100.00, 7),
  (uuid_generate_v4(), 'Security', 'security', 'home_service', 'SC', 75.00, 8),
  (uuid_generate_v4(), 'Lifestyle', 'lifestyle', 'lifestyle', 'HQ', 0.00, 9);

-- Protection Plan Templates
INSERT INTO protection_plan_templates (id, name, slug, tier, monthly_price, yearly_price, one_time_price, deductible_options, coverage_items, is_popular, display_order) VALUES
  (
    uuid_generate_v4(), 'Essential', 'squaretrade-essential', 1,
    9.99, 99.99, 199.99,
    '[0, 25, 50, 75, 100]'::jsonb,
    '["Mechanical & electrical failures", "Normal wear & tear", "Power surge protection", "No deductibles on select repairs", "30-day money-back guarantee"]'::jsonb,
    FALSE, 1
  ),
  (
    uuid_generate_v4(), 'Premium', 'squaretrade-premium', 2,
    14.99, 149.99, 299.99,
    '[0, 25, 50, 75, 100]'::jsonb,
    '["Everything in Essential", "Accidental damage from handling", "Food spoilage coverage (up to $300)", "Free in-home service", "Replacement guarantee", "Priority customer support"]'::jsonb,
    TRUE, 2
  ),
  (
    uuid_generate_v4(), 'Ultimate', 'squaretrade-ultimate', 3,
    24.99, 249.99, 499.99,
    '[0, 25, 50, 75, 100]'::jsonb,
    '["Everything in Premium", "Cosmetic damage coverage", "Unlimited claims", "Same-day service (where available)", "Annual maintenance check included", "Transferable coverage", "Multi-device discount"]'::jsonb,
    FALSE, 3
  );

-- Maintenance Templates (auto-generated reminders per asset type)
INSERT INTO maintenance_templates (id, subcategory_id, task_name, description, why_it_matters, category, frequency, interval_days, estimated_effort, priority) VALUES
  -- Refrigerator
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'refrigerator'), 'Clean Condenser Coils', 'Vacuum or brush the condenser coils to remove dust and debris', 'Dirty coils make the compressor work harder, increasing energy bills and reducing lifespan', 'cleaning', 'bi_annual', 180, '30 minutes', 'medium'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'refrigerator'), 'Clean Door Gaskets', 'Wipe door gaskets with warm soapy water and check for cracks', 'Damaged gaskets let cold air escape, making the fridge work harder', 'cleaning', 'quarterly', 90, '15 minutes', 'medium'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'refrigerator'), 'Replace Water Filter', 'Replace the water/ice filter per manufacturer recommendation', 'Old filters can allow contaminants and reduce water flow', 'replacement', 'bi_annual', 180, '10 minutes', 'medium'),
  -- Air Conditioner
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'air_conditioner'), 'Replace Air Filter', 'Replace or clean the air filter', 'Clogged filters reduce airflow and efficiency by up to 15%', 'replacement', 'monthly', 30, '10 minutes', 'high'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'air_conditioner'), 'Clean Evaporator Coils', 'Clean indoor evaporator coils', 'Dirty coils reduce cooling capacity and increase energy usage', 'cleaning', 'annual', 365, '45 minutes', 'medium'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'air_conditioner'), 'Check Refrigerant Level', 'Have a professional check refrigerant levels', 'Low refrigerant means poor cooling and potential compressor damage', 'inspection', 'annual', 365, '60 minutes', 'high'),
  -- Washing Machine
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'washing_machine'), 'Clean Drum', 'Run an empty hot cycle with cleaning solution', 'Prevents mold, mildew, and odor buildup', 'cleaning', 'monthly', 30, '15 minutes', 'medium'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'washing_machine'), 'Clean Lint Filter', 'Remove and clean the lint/debris filter', 'Clogged filters cause drainage issues and reduce efficiency', 'cleaning', 'quarterly', 90, '10 minutes', 'low'),
  -- Water Heater
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'water_heater'), 'Flush Tank', 'Drain and flush the tank to remove sediment buildup', 'Sediment reduces heating efficiency and can cause tank corrosion', 'service', 'annual', 365, '45 minutes', 'high'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'water_heater'), 'Check Anode Rod', 'Inspect the sacrificial anode rod for corrosion', 'A corroded anode rod means the tank itself will start corroding', 'inspection', 'annual', 365, '30 minutes', 'high'),
  -- Dishwasher
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'dishwasher'), 'Clean Filter', 'Remove and clean the dishwasher filter', 'A clogged filter causes poor cleaning and bad odors', 'cleaning', 'monthly', 30, '10 minutes', 'medium'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'dishwasher'), 'Clean Spray Arms', 'Remove and unclog spray arm holes', 'Blocked spray arms mean dishes don''t get clean', 'cleaning', 'quarterly', 90, '20 minutes', 'low'),
  -- HVAC
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'hvac_system'), 'Replace Air Filter', 'Replace the HVAC air filter', 'A clean filter improves air quality and system efficiency', 'replacement', 'quarterly', 90, '10 minutes', 'high'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'hvac_system'), 'Professional Inspection', 'Schedule a professional HVAC inspection', 'Catches problems early, maintains warranty, ensures safety', 'inspection', 'annual', 365, '120 minutes', 'high'),
  -- Dryer
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'dryer'), 'Clean Lint Trap', 'Remove lint from the trap after every load; deep clean monthly', 'Lint buildup is a fire hazard and reduces drying efficiency', 'cleaning', 'monthly', 30, '5 minutes', 'high'),
  (uuid_generate_v4(), (SELECT id FROM asset_subcategories WHERE slug = 'dryer'), 'Clean Vent Duct', 'Clean the dryer vent duct and exterior vent', 'Blocked vents are the leading cause of dryer fires', 'cleaning', 'annual', 365, '30 minutes', 'high');


-- ============================================================================
-- 19. TABLE COUNTS SUMMARY
-- ============================================================================

-- Total: 33 tables
--
-- Auth & Users:       3 (users, user_sessions, otp_codes)
-- Households:         3 (households, household_members, household_invites)
-- Assets:             5 (asset_categories, asset_subcategories, assets, asset_documents, asset_warranties)
-- Maintenance:        4 (maintenance_templates, maintenance_reminders, maintenance_records, asset_health_scores)
-- Claims:             3 (claims, claim_status_history, claim_documents)
-- Bookings:           4 (service_categories, service_providers, service_bookings, booking_status_history)
-- Products:           1 (products)
-- Orders:             3 (orders, order_status_history, trade_ins)
-- Plans:              2 (protection_plan_templates, user_protection_plans)
-- Payments:           4 (payment_methods, payments, installment_plans, installment_payments)
-- Notifications:      4 (push_tokens, notifications, critical_alerts, notification_preferences)
-- Settings:           1 (user_settings)
-- AI:                 1 (ai_sessions)
-- Audit:              1 (audit_logs)
-- Utility:            1 (id_counters)
