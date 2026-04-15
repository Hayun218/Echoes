# Echoes setup

## Architecture overview

Echoes is a monorepo with two main app surfaces:

- `apps/backend` — FastAPI service exposing REST APIs for scenes, characters, sessions, and messages.
- `apps/mobile` — Flutter client with the first product loop: Home, Explore, Story, My.

The backend stores session state and message history in a SQL-compatible database and uses Supabase-style schema conventions.

## Local development

### Backend

1. Install Python dependencies and backend tooling.
2. Set a local database URL:
   ```bash
   export DATABASE_URL="sqlite:///./dev.db"
   ```
3. Start the API server:
   ```bash
   cd apps/backend
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

### Mobile

1. Install Flutter and required platform tooling.
2. From `apps/mobile`, install packages:
   ```bash
   flutter pub get
   ```
3. Run the app on an emulator or device:
   ```bash
   flutter run
   ```

## Notes

- The mobile app is configured to call the local backend at `http://10.0.2.2:8000/api/v1` by default.
- Use the `X-Profile-Id` header for backend requests; the current Flutter client sends a fixed test profile.
- The repo includes `supabase` configuration for the data model, but backend migrations are not automated inside the app yet.
