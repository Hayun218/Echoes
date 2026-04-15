# Echoes Product Planning

This document captures the current product architecture and the roadmap for the implemented Echoes flow.

## Current product experience

Echoes is organized around four mobile tabs:

- **Home** — concept-first story entry with a single-line prompt
- **Explore** — discover scenes and characters
- **Story** — active session hub for messages and turns
- **My** — profile/history placeholder for future personalization

The current user flow is:
1. Enter a story concept on Home
2. Start a session with `POST /api/v1/sessions/start`
3. Continue the session with `POST /api/v1/sessions/{id}/turns`
4. Read session messages with `GET /api/v1/sessions/{id}/messages`

## Implementation focus

- Concept-first entry is the primary onboarding path.
- `Story` is the main experience for an active narrative session.
- `Explore` supports scene browsing and character detail discovery.
- Sessions and messages persist in the backend and are scoped to a profile header.

## Current backend model

- `GET /api/v1/scenes` — list scenes for Explore
- `GET /api/v1/scenes/{id}` — scene detail
- `GET /api/v1/characters` — character metadata
- `POST /api/v1/sessions/start` — create a new story session
- `POST /api/v1/sessions/{id}/turns` — add a story turn
- `GET /api/v1/sessions/{id}/messages` — load session conversation
- `GET /api/v1/sessions` — list sessions
- `GET /api/v1/sessions/{id}` — session detail

## Current product priorities

- Keep the core story loop working end-to-end
- Store session state and progression in backend JSON fields
- Expose session and message APIs for mobile app consumption
- Keep the mobile UI simple and focused on the story flow

## Roadmap

### Next areas of work
- Add session history and resume support in `Story`/`My`
- Add real authentication and profile handling instead of the fixed developer profile header
- Add backend migrations and seed scripts for easier local setup
- Expand Explore with richer scene metadata and premium gating
- Add production-grade error handling, app logging, and analytics

### Future feature direction
- Premium scene access and tiered content
- Scene participants and richer multi-character interactions
- Story reflection / recap endpoints
- Profile personalization and saved story collections
