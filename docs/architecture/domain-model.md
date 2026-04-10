# Echoes Entity Definitions

This document defines the production-ready domain entities for Echoes.  
Echoes is designed as a commercial launch product from day one, with support for:

- public browse access and discoverability
- logged-in free users
- premium subscribers
- monetization-ready access control, entitlement logic, and usage tracking

This document is intended to serve as the implementation blueprint for:

- Supabase/Postgres schema design
- FastAPI models and business rules
- API access control
- monetization and product gating logic

---

## Identity Model Overview

Echoes uses **Supabase Auth** as the source of truth for authenticated identities.

- `auth.users` stores authentication-level identity
- `profiles` stores application-level user metadata, access state, and product-facing data

Authenticated users must have a corresponding `profiles` record using the same UUID as `auth.users.id`.

Anonymous visitors are read-only and do not create profiles, sessions, or usage records. Chat and persistence are available only to authenticated profiles.

---

## Access Model Overview

Echoes supports three primary access states:

### Public Browse Visitor
- can browse characters and discover scenes
- can view public scene metadata and teasers
- cannot start chat or create sessions
- cannot save progress or generate usage data

### Logged-in Free User
- can access free scenes for chat
- can use basic chat with usage limits
- can save sessions and resume conversations
- cannot access premium-only scenes or premium-only features

### Premium User
- can access premium scenes for chat
- can use expanded chat limits and features
- can access premium content and monetization bundles

### Suspended / Restricted User
- access is limited or blocked based on account or moderation status

---

## Monetization Model Overview

Echoes monetization is based on three layers:

1. **Subscription plans**
   - free
   - premium monthly
   - premium yearly

2. **Entitlements**
   - feature-level access grants
   - can be granted by subscription, promotion, campaign, or admin override

3. **Usage tracking**
   - supports quota enforcement
   - supports analytics and future expansion into usage-based pricing or premium upsells

---

## profiles

**Purpose**:  
Represents authenticated users in Echoes. Profiles are the primary anchor for access control, subscriptions, personalization, and usage tracking.

**Key Fields**:
- `id` (UUID, primary key, matches `auth.users.id`)
- `email` (string, optional)
- `username` (string, unique)
- `status` (enum: `active`, `suspended`, `deleted`)
- `preferences` (JSONB, optional)
- `created_at` (timestamp)
- `updated_at` (timestamp)

**Relationships**:
- One-to-many with `sessions`
- One-to-many with `subscriptions`
- One-to-many with `usage_counters`
- One-to-many with `reports` if user-level reporting is later added
- Optional one-to-many with `bookmarks` or `saved_sessions` in later versions

**Constraints**:
- `email` must be unique when present
- `username` must be unique
- profile records represent authenticated users only
- `status` must control access rights and retention handling

**Monetization Relevance**:  
Profiles are the user-facing anchor for tier, access rights, usage tracking, and revenue attribution. They connect acquisition, engagement, conversion, and retention.

---

## characters

**Purpose**:  
Defines the biblical characters and personas users explore and interact with. Characters form the top-level discovery and emotional engagement layer of the product.

**Key Fields**:
- `id` (UUID, primary key)
- `slug` (string, unique)
- `name` (string, unique)
- `description` (text)
- `avatar_url` (string, nullable)
- `category` (string, nullable)
- `tags` (JSONB, optional)
- `sort_order` (integer, default 0)
- `is_active` (boolean, default true)
- `is_featured` (boolean, default false)
- `created_at` (timestamp)
- `updated_at` (timestamp)

**Relationships**:
- One-to-many with `scenes`

**Constraints**:
- `name` must be unique
- `slug` must be unique
- inactive characters must not appear in discovery or selection flows
- content changes should preserve historical integrity where needed

**Monetization Relevance**:  
Characters drive top-of-funnel engagement and emotional attachment. Premium positioning can be strengthened through character-based premium scene packs, featured characters, or exclusive arcs.

---

## scenes

**Purpose**:  
Represents the specific biblical moments, narrative situations, and chat contexts that users can enter. Scenes are the primary product unit for discovery, conversion, engagement, and monetization.

**Key Fields**:
- `id` (UUID, primary key)
- `character_id` (UUID, foreign key to `characters`)
- `slug` (string, unique)
- `title` (string)
- `description` (text)
- `intro_text` (text)
- `prompt_template` (text)
- `thumbnail_url` (string, nullable)
- `mood_tags` (JSONB, optional)
- `difficulty_level` (integer, range 1-5)
- `access_tier` (enum: `free`, `premium`)
- `is_public_browse` (boolean, default false)
- `is_active` (boolean, default true)
- `sort_order` (integer, default 0)
- `created_at` (timestamp)
- `updated_at` (timestamp)

**Relationships**:
- Many-to-one with `characters`
- One-to-many with `sessions`

**Constraints**:
- `character_id` must reference an existing character
- inactive scenes must not be shown in browsing or chat entry flows
- public browse scenes may be visible to visitors without login
- `access_tier` determines chat gating for free or premium users
- `difficulty_level` must remain within allowed bounds

**Monetization Relevance**:  
Scenes are the primary monetization surface. Public browse scenes support acquisition, free scenes support retention, and premium scenes drive upgrade conversion.

---

## sessions

**Purpose**:  
Tracks a single conversation experience between an authenticated profile and a scene. Sessions are the core unit of engagement, progress, save/resume behavior, and quota enforcement.

**Key Fields**:
- `id` (UUID, primary key)
- `profile_id` (UUID, foreign key to `profiles`, required)
- `scene_id` (UUID, foreign key to `scenes`)
- `status` (enum: `active`, `completed`, `abandoned`)
- `started_at` (timestamp)
- `ended_at` (timestamp, nullable)
- `total_messages` (integer, default 0)
- `total_tokens` (integer, default 0)
- `created_at` (timestamp)
- `updated_at` (timestamp)

**Relationships**:
- Many-to-one with `profiles`
- Many-to-one with `scenes`
- One-to-many with `messages`

**Constraints**:
- every session must belong to an authenticated profile
- chat requires login and therefore anonymous visitors cannot create sessions
- completed or abandoned sessions should not accept new messages unless reopened by business rules
- `total_messages` and `total_tokens` must remain non-negative

**Monetization Relevance**:  
Sessions are the primary engagement record used for gating, retention analysis, save/resume value, and upsell triggers. They are also the unit for premium conversion and usage tracking.

---

## messages

**Purpose**:  
Stores each conversational turn inside a session, including user inputs and AI responses.

**Key Fields**:
- `id` (UUID, primary key)
- `session_id` (UUID, foreign key to `sessions`)
- `sender_type` (enum: `user`, `ai`)
- `content` (text)
- `token_count` (integer, default 0)
- `metadata` (JSONB, optional)
- `created_at` (timestamp)

**Relationships**:
- Many-to-one with `sessions`

**Constraints**:
- `session_id` must reference an existing session
- `content` cannot be empty
- `token_count` must be non-negative

**Monetization Relevance**:  
Messages represent the finest-grained usage unit for quota enforcement, token tracking, behavioral analytics, and future billing or usage-based premium enhancements.

---

## subscriptions

**Purpose**:  
Stores the normalized subscription state used by Echoes to determine current plan access.

**Key Fields**:
- `id` (UUID, primary key)
- `profile_id` (UUID, foreign key to `profiles`)
- `plan_type` (enum: `free`, `premium_monthly`, `premium_yearly`)
- `status` (enum: `active`, `canceled`, `expired`, `trial`, `grace_period`)
- `payment_provider` (string, nullable)
- `external_id` (string, nullable)
- `started_at` (timestamp)
- `expires_at` (timestamp, nullable)
- `auto_renew` (boolean, default false)
- `metadata` (JSONB, optional)
- `created_at` (timestamp)
- `updated_at` (timestamp)

**Relationships**:
- Many-to-one with `profiles`
- One-to-many with `entitlements`

**Constraints**:
- only one active paid subscription should exist per profile at a time
- free-tier records may exist to simplify access logic
- paid plans should include provider reference metadata
- status must always reflect normalized app-side subscription state

**Monetization Relevance**:  
Subscriptions are the foundation of recurring revenue, upgrade/downgrade handling, trial conversion, churn analysis, and paid retention.

---

## entitlements

**Purpose**:  
Represents feature-level access granted to a profile. Entitlements allow Echoes to support both subscription-driven access and non-subscription-based grants such as promotions, campaigns, and admin overrides.

**Key Fields**:
- `id` (UUID, primary key)
- `profile_id` (UUID, foreign key to `profiles`)
- `subscription_id` (UUID, nullable foreign key to `subscriptions`)
- `feature_type` (enum: `unlimited_messages`, `premium_scenes`, `advanced_reflections`, `voice_mode`, `priority_access`)
- `granted_source` (enum: `subscription`, `promotion`, `campaign`, `admin`)
- `granted_at` (timestamp)
- `expires_at` (timestamp, nullable)
- `revoked_at` (timestamp, nullable)
- `metadata` (JSONB, optional)

**Relationships**:
- Many-to-one with `profiles`
- Optional many-to-one with `subscriptions`

**Constraints**:
- entitlements must not grant access after `expires_at`
- revoked entitlements must be treated as inactive immediately
- `subscription_id` is optional because access may come from non-subscription sources
- feature grants are additive and time-bound unless explicitly permanent

**Monetization Relevance**:  
Entitlements support flexible packaging, upsells, promotions, limited-time campaigns, bonus access, and future monetization experiments beyond simple subscription tiers.

---

## usage_counters

**Purpose**:  
Tracks usage per profile and billing or quota period. This entity supports tier enforcement, analytics, and monetization visibility.

**Key Fields**:
- `id` (UUID, primary key)
- `profile_id` (UUID, foreign key to `profiles`)
- `period_start` (date)
- `period_end` (date)
- `messages_sent` (integer, default 0)
- `sessions_started` (integer, default 0)
- `tokens_used` (integer, default 0)
- `premium_scene_opens` (integer, default 0)
- `voice_seconds_used` (integer, default 0)
- `resets_at` (timestamp)
- `updated_at` (timestamp)
- `created_at` (timestamp)

**Relationships**:
- Many-to-one with `profiles`

**Constraints**:
- one usage record per profile per quota period
- all counter values must be non-negative
- free-tier logic may enforce hard caps or soft prompts
- premium-tier logic may use counters for analytics, fairness, or future expansion

**Monetization Relevance**:  
Usage counters power quota enforcement, upsell prompts, retention analysis, and future monetization models such as extended limits, feature bundles, or usage-based premium plans.

---

## analytics_reports

**Purpose**:  
Stores aggregated analytics and business snapshots used for operations, revenue review, retention analysis, and strategic reporting.

**Key Fields**:
- `id` (UUID, primary key)
- `report_type` (enum: `daily_usage`, `monthly_revenue`, `churn`, `engagement`, `conversion`)
- `period_start` (date)
- `period_end` (date)
- `data` (JSONB)
- `generated_at` (timestamp)
- `source` (string, nullable)

**Relationships**:
- Standalone analytics entity

**Constraints**:
- reports are immutable after creation
- `(report_type, period_start, period_end)` should be unique
- generated analytics must not be used as the source of truth for transactional state

**Monetization Relevance**:  
Analytics reports support pricing decisions, investor-facing reporting, funnel analysis, revenue tracking, churn monitoring, and growth planning.

---

## Future Optional Entities

These are not required for the first production launch schema, but should be considered in later phases:

- `bookmarks`
- `saved_sessions`
- `feature_flags`
- `scene_access_rules`
- `recommendation_logs`
- `payment_events`
- `refund_events`

These should only be added when the product requires them operationally.

---

## Implementation Notes

### Recommended First Schema Order
1. `profiles`
2. `characters`
3. `scenes`
4. `sessions`
5. `messages`
6. `subscriptions`
7. `entitlements`
8. `usage_counters`
9. `analytics_reports`

### Key Product Logic
- public browse visitors can discover characters and scenes, but chat requires login
- login unlocks persistent sessions and expanded access
- premium plans unlock advanced scenes and premium features
- entitlement checks should be the final access-control layer
- usage counters should support both product limits and monetization analysis

### Product Principle
Echoes should not be modeled as a lightweight chat prototype.  
It should be implemented as a monetization-ready, production-oriented product from the beginning.