# Echoes Domain Model

This document describes the current data model and the pieces that are implemented in the codebase today.

## Current data model

Echoes currently implements the following core tables:

- `profiles`
- `characters`
- `scenes`
- `sessions`
- `messages`

The backend stores session state and narrative continuity in JSON fields on `sessions`.

## profiles

**Purpose**: identifies the authenticated profile owning sessions and messages.

**Key fields**:
- `id` (UUID, primary key)
- `status` (string)
- `preferences` (JSON)
- `created_at`, `updated_at`

**Notes**:
- Current local development uses a fixed `X-Profile-Id` header for authentication.
- Profiles are required for session creation and message persistence.

## characters

**Purpose**: represents story personas used across scenes.

**Key fields**:
- `id` (UUID)
- `slug` (string)
- `name` (string)
- `description` (text)
- `avatar_url` (nullable)
- `tags` (JSON)
- `is_active` (boolean)
- `is_featured` (boolean)
- `created_at`, `updated_at`

**Notes**:
- Active characters are exposed through `GET /api/v1/characters`.
- Each scene references a primary character.

## scenes

**Purpose**: defines discoverable narrative entry points and the story context for sessions.

**Key fields**:
- `id` (UUID)
- `character_id` (UUID)
- `slug` (string)
- `title` (string)
- `description` (text)
- `intro_text` (text)
- `prompt_template` (text)
- `thumbnail_url` (nullable)
- `mood_tags` (JSON)
- `difficulty_level` (integer)
- `access_tier` (string)
- `is_public_browse` (boolean)
- `is_active` (boolean)
- `sort_order` (integer)
- `created_at`, `updated_at`

**Notes**:
- Public scenes are shown on Explore and can be filtered by tier.
- Scene detail is available through `GET /api/v1/scenes/{id}`.

## sessions

**Purpose**: stores an active or resumed story experience for a profile.

**Key fields**:
- `id` (UUID)
- `profile_id` (UUID)
- `scene_id` (UUID)
- `source_type` (string)
- `story_metadata` (JSON)
- `progression_state` (JSON)
- `status` (string)
- `started_at`, `ended_at`
- `total_messages` (integer)
- `total_tokens` (integer)
- `created_at`, `updated_at`

**Notes**:
- `story_metadata` and `progression_state` are used to keep story context and progression state.
- Sessions are created via `POST /api/v1/sessions/start`.
- The current implementation supports active sessions only; session resume / history is in roadmap.

## messages

**Purpose**: stores each turn in a session conversation.

**Key fields**:
- `id` (UUID)
- `session_id` (UUID)
- `sender_type` (string)
- `speaker_type` (string)
- `speaker_character_id` (UUID, nullable)
- `content` (text)
- `token_count` (integer)
- `metadata` (JSON)
- `created_at`

**Notes**:
- Messages are written during session turns and loaded in chronological order.
- The current UI fetches messages with `GET /api/v1/sessions/{id}/messages`.

## practical model notes

- The product currently uses a single primary character per scene.
- Schema extensions such as `scene_participants` and premium access gating are planned but not yet implemented.
- Session state is intentionally kept in the backend JSON fields to support concept-first flow and future scene branching.

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