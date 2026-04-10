CREATE TYPE message_speaker_type AS ENUM ('user', 'narrator', 'character', 'system');
CREATE TYPE session_source_type AS ENUM ('canonical', 'generative');

CREATE TABLE scene_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scene_id UUID NOT NULL REFERENCES scenes(id) ON DELETE CASCADE,
  character_id UUID NOT NULL REFERENCES characters(id) ON DELETE RESTRICT,
  role_in_scene VARCHAR(100) NOT NULL DEFAULT 'supporting',
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT scene_participants_unique UNIQUE (scene_id, character_id)
);

ALTER TABLE messages
ADD COLUMN speaker_type message_speaker_type NOT NULL DEFAULT 'narrator',
ADD COLUMN speaker_character_id UUID REFERENCES characters(id),
ADD CONSTRAINT messages_speaker_character_consistency CHECK (
  (speaker_type = 'character' AND speaker_character_id IS NOT NULL)
  OR
  (speaker_type <> 'character' AND speaker_character_id IS NULL)
);

ALTER TABLE sessions
ADD COLUMN source_type session_source_type NOT NULL DEFAULT 'canonical',
ADD COLUMN story_metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
ADD COLUMN progression_state JSONB NOT NULL DEFAULT '{}'::JSONB;

CREATE INDEX idx_scene_participants_scene_id ON scene_participants(scene_id);
CREATE INDEX idx_scene_participants_character_id ON scene_participants(character_id);
CREATE INDEX idx_messages_speaker_character_id ON messages(speaker_character_id);
CREATE INDEX idx_sessions_source_type ON sessions(source_type);