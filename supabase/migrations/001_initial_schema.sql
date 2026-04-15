-- Initial Commercial Launch Schema for Echoes
-- Supabase/Postgres compatible
-- Monetization-ready with subscriptions, entitlements, and usage tracking

-- This schema uses application-level profiles that map directly to auth.users for authenticated users only.
-- Profiles.id references auth.users.id directly.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enums
CREATE TYPE profile_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE scene_access_tier AS ENUM ('free', 'premium');
CREATE TYPE subscription_plan_type AS ENUM ('free', 'premium_monthly', 'premium_yearly');
CREATE TYPE subscription_status AS ENUM ('active', 'canceled', 'expired', 'trial', 'grace_period');
CREATE TYPE session_status AS ENUM ('active', 'completed', 'abandoned');
CREATE TYPE message_sender_type AS ENUM ('user', 'ai');
CREATE TYPE message_speaker_type AS ENUM ('user', 'ai', 'character');
CREATE TYPE session_source_type AS ENUM ('biblical', 'generative');
CREATE TYPE entitlement_feature_type AS ENUM ('unlimited_messages', 'premium_scenes', 'advanced_reflections', 'voice_mode', 'priority_access');
CREATE TYPE entitlement_granted_source AS ENUM ('subscription', 'promotion', 'campaign', 'admin');
CREATE TYPE report_type AS ENUM ('daily_usage', 'monthly_revenue', 'churn', 'engagement', 'conversion');
CREATE TYPE usage_period_type AS ENUM ('daily', 'monthly');

-- Profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    status profile_status NOT NULL DEFAULT 'active',
    preferences JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Characters table
CREATE TABLE characters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(120) NOT NULL,
    name VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    avatar_url VARCHAR(500),
    category VARCHAR(120),
    tags JSONB DEFAULT '{}'::JSONB,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT characters_slug_unique UNIQUE (slug),
    CONSTRAINT characters_name_unique UNIQUE (name)
);

-- Scenes table
CREATE TABLE scenes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE RESTRICT,
    slug VARCHAR(140) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    intro_text TEXT NOT NULL,
    prompt_template TEXT NOT NULL,
    thumbnail_url VARCHAR(500),
    mood_tags JSONB DEFAULT '{}'::JSONB,
    difficulty_level INTEGER NOT NULL CHECK (difficulty_level BETWEEN 1 AND 5),
    access_tier scene_access_tier NOT NULL DEFAULT 'free',
    is_public_browse BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT scenes_slug_unique UNIQUE (slug)
);

-- Scene participants table
CREATE TABLE scene_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scene_id UUID NOT NULL REFERENCES scenes(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    role_in_scene VARCHAR(100),
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT scene_participants_unique UNIQUE (scene_id, character_id)
);

-- Sessions table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    scene_id UUID NOT NULL REFERENCES scenes(id) ON DELETE RESTRICT,
    source_type session_source_type NOT NULL DEFAULT 'biblical',
    story_metadata JSONB DEFAULT '{}'::JSONB,
    progression_state JSONB DEFAULT '{}'::JSONB,
    status session_status NOT NULL DEFAULT 'active',
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    total_messages INTEGER NOT NULL DEFAULT 0,
    total_tokens INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT sessions_non_negative_counts CHECK (total_messages >= 0 AND total_tokens >= 0)
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    sender_type message_sender_type NOT NULL,
    speaker_type message_speaker_type NOT NULL,
    speaker_character_id UUID REFERENCES characters(id) NULL,
    content TEXT NOT NULL,
    token_count INTEGER NOT NULL DEFAULT 0,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT messages_non_negative_tokens CHECK (token_count >= 0),
    CONSTRAINT messages_content_not_empty CHECK (TRIM(content) != '')
);

-- Subscriptions table
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    plan_type subscription_plan_type NOT NULL DEFAULT 'free',
    status subscription_status NOT NULL DEFAULT 'active',
    payment_provider VARCHAR(100),
    external_id VARCHAR(255),
    auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::JSONB,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT subscriptions_external_unique UNIQUE (payment_provider, external_id)
);

-- One paid active subscription per profile
CREATE UNIQUE INDEX subscriptions_active_paid_unique ON subscriptions(profile_id)
    WHERE status = 'active' AND plan_type != 'free';

-- Entitlements table
CREATE TABLE entitlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    feature_type entitlement_feature_type NOT NULL,
    granted_source entitlement_granted_source NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::JSONB,
    CONSTRAINT entitlements_validity CHECK (
        revoked_at IS NULL OR revoked_at >= granted_at
    )
);

-- Usage counters table
CREATE TABLE usage_counters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    period_type usage_period_type NOT NULL DEFAULT 'monthly',
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    messages_sent INTEGER NOT NULL DEFAULT 0,
    sessions_started INTEGER NOT NULL DEFAULT 0,
    tokens_used INTEGER NOT NULL DEFAULT 0,
    premium_scene_opens INTEGER NOT NULL DEFAULT 0,
    voice_seconds_used INTEGER NOT NULL DEFAULT 0,
    resets_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT usage_counters_non_negative CHECK (
        messages_sent >= 0 AND sessions_started >= 0 AND tokens_used >= 0 AND premium_scene_opens >= 0 AND voice_seconds_used >= 0
    ),
    CONSTRAINT usage_counters_period UNIQUE (profile_id, period_type, period_start)
);

-- Analytics reports table
CREATE TABLE analytics_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type report_type NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    data JSONB NOT NULL,
    source VARCHAR(120),
    generated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT analytics_reports_unique_period UNIQUE (report_type, period_start, period_end)
);

-- Indexes
CREATE INDEX idx_profiles_status ON profiles(status);
CREATE INDEX idx_characters_slug ON characters(slug);
CREATE INDEX idx_scenes_character_id ON scenes(character_id);
CREATE INDEX idx_scenes_access_tier ON scenes(access_tier);
CREATE INDEX idx_scene_participants_scene_id ON scene_participants(scene_id);
CREATE INDEX idx_scene_participants_character_id ON scene_participants(character_id);
CREATE INDEX idx_sessions_profile_id ON sessions(profile_id);
CREATE INDEX idx_sessions_scene_id ON sessions(scene_id);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_messages_session_id ON messages(session_id);
CREATE INDEX idx_subscriptions_profile_id ON subscriptions(profile_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_entitlements_profile_id ON entitlements(profile_id);
CREATE INDEX idx_entitlements_subscription_id ON entitlements(subscription_id);
CREATE INDEX idx_usage_counters_profile_id ON usage_counters(profile_id);
CREATE INDEX idx_usage_counters_period ON usage_counters(profile_id, period_type, period_start);
CREATE INDEX idx_analytics_reports_type_period ON analytics_reports(report_type, period_start, period_end);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_characters_updated_at
BEFORE UPDATE ON characters
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scenes_updated_at
BEFORE UPDATE ON scenes
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scene_participants_updated_at
BEFORE UPDATE ON scene_participants
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessions_updated_at
BEFORE UPDATE ON sessions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
BEFORE UPDATE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usage_counters_updated_at
BEFORE UPDATE ON usage_counters
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();