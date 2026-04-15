# Echoes API Reference

This document summarizes the current backend API surface implemented in Echoes.

## Headers

- `Content-Type: application/json`
- `X-Profile-Id: {profile_uuid}` — required for session creation and message endpoints in local development.

## Scenes

### GET /api/v1/scenes

Returns a list of scene summaries for the Explore tab.

Response:
- `id`
- `title`
- `description`
- `character_id`
- `thumbnail_url`
- `access_tier`
- `is_public_browse`

### GET /api/v1/scenes/{id}

Returns a detailed scene record.

Response includes:
- `id`
- `title`
- `description`
- `intro_text`
- `prompt_template`
- `character_id`
- `thumbnail_url`
- `access_tier`
- `is_public_browse`
- `mood_tags`

## Characters

### GET /api/v1/characters

Returns a list of character metadata used for discovery and scene context.

Response items include:
- `id`
- `name`
- `slug`
- `description`
- `avatar_url`
- `tags`

## Sessions

### POST /api/v1/sessions/start

Starts a new story session.

Request body:
- `concept` (string, required)
- `scene_id` (string, optional)

Response includes:
- `id`
- `profile_id`
- `scene_id`
- `status`
- `story_metadata`
- `progression_state`

### GET /api/v1/sessions

Returns a list of sessions for the current profile.

Response items include:
- `id`
- `profile_id`
- `scene_id`
- `status`
- `started_at`
- `ended_at`

### GET /api/v1/sessions/{id}

Returns session details for the requested session.

Response includes:
- `id`
- `profile_id`
- `scene_id`
- `status`
- `story_metadata`
- `progression_state`
- `started_at`
- `ended_at`

## Messages

### GET /api/v1/sessions/{id}/messages

Returns the ordered message history for a session.

Response items include:
- `id`
- `session_id`
- `sender_type`
- `speaker_type`
- `speaker_character_id`
- `content`
- `metadata`
- `created_at`

### POST /api/v1/sessions/{id}/turns

Sends a new user turn to the session.

Request body:
- `user_input` (string, required)

Response:
- `200 OK` on success

## Notes

- The current mobile app uses `http://10.0.2.2:8000/api/v1` as the default API base URL for Android emulator development.
- The backend currently requires a fixed developer profile ID in `X-Profile-Id` for local testing.
