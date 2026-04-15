# Echoes

Echoes is a lightweight story-driven monorepo for a Flutter mobile client and FastAPI backend. It is designed to support conversational narrative sessions, scene discovery, and authenticated story persistence.

## Tech stack

- Flutter mobile app in `apps/mobile`
- FastAPI backend in `apps/backend`
- SQLAlchemy ORM and Pydantic schemas
- Supabase-compatible schema and config in `supabase`
- Tests with `pytest` and Flutter analysis

## Monorepo layout

- `apps/backend` — backend service, API routes, models, repositories, session and message persistence
- `apps/mobile` — Flutter app with Home, Explore, Story, and My tabs
- `supabase` — database and Supabase configuration files
- `docs` — project documentation and architecture notes
- `scripts` — development and utility scripts

## Current status

- Backend: read APIs for characters, scenes, sessions, messages, plus session start and turn submission
- Mobile: tabbed app structure, Explore browsing, Home story creation, Story session playback and turn submission
- Authentication: uses fixed `X-Profile-Id` header for local dev flows
- Persistence: sessions and messages stored in backend database

## Run locally

### Backend

1. Set `DATABASE_URL` for local development, for example:
   ```bash
   export DATABASE_URL="sqlite:///./dev.db"
   ```
2. Run the FastAPI app from `apps/backend`:
   ```bash
   cd apps/backend
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

### Flutter

1. Install dependencies and run the app from `apps/mobile`:
   ```bash
   cd apps/mobile
   flutter pub get
   flutter run
   ```
2. The app uses `http://10.0.2.2:8000/api/v1` by default for Android emulator backend calls.

## Database / seed notes

- The backend currently uses SQLAlchemy models for database schema and integration tests rely on temporary SQLite.
- There is no automatic migration workflow wired into this repo yet; schema changes are defined in the backend models and Supabase config.
- Seed data is provided inside test fixtures and initial local development data can be created through the API.

## Next planned work

- Add profile/auth flow and real user session persistence
- Implement session list and resume history in mobile UI
- Add backend migrations and seed scripts
- Expand Explore with premium gating and character detail flows
- Add production-grade error handling and analytics

## Docs

- `docs/architecture/domain-model.md` — domain and schema overview
- `docs/architecture/product-plan.md` — current product flow and roadmap
- `docs/api/README.md` — API endpoint summary and backend contract
- `docs/setup/README.md` — local architecture and run setup
