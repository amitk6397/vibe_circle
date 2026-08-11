# VibeCircle API

Production-structured FastAPI backend for the VibeCircle Expo application.

## Architecture

Each domain under `app/modules` owns its database model, DTOs, service rules, controller functions, and routes. Shared configuration, security, database access, errors, pagination, uploads, and model registration live under `app/core` and `app/common`.

Domains: auth, users, discovery, matching, chat, communities, feed, rooms, notifications, moderation, and uploads.

## Local setup

```powershell
cd "D:\React App\VibeCam-App\backend"
.\venv\Scripts\Activate.ps1
Copy-Item .env.example .env
alembic upgrade head
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Open `http://127.0.0.1:8000/docs` for Swagger and `http://127.0.0.1:8000/health` for health status.

## Database

The project is configured for MySQL through PyMySQL. Set:

```env
DATABASE_URL=mysql+pymysql://vibecircle:password@127.0.0.1:3306/vibecircle?charset=utf8mb4
```

SQLite remains the zero-configuration test fallback. Always replace `SECRET_KEY` in staging/production and run Alembic migrations before starting the API.

On startup, the API first connects to the MySQL server and checks the database named in
`DATABASE_URL`. If it does not exist, it creates it with `utf8mb4` encoding, then verifies the
database connection before creating tables. The configured MySQL user therefore needs
`CREATE DATABASE` permission for the first run; subsequent runs only require access to that database.

## Tests

```powershell
.\venv\Scripts\python.exe -m pytest -q
```

Uploads are authenticated, limited to 15 MB, MIME allow-listed, and stored locally in development. Replace the upload service with S3-compatible storage for production. WebSocket chat is available at `/api/v1/chat/ws/{conversation_id}?token=ACCESS_TOKEN`.

## Secure Agora calls

Set `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` only in the backend `.env`. The app requests
short-lived participant tokens from `/api/v1/calls/{call_id}/token`; the certificate is never
shipped to the client. Apply migrations before deployment with:

```powershell
.\venv\Scripts\python.exe -m alembic upgrade head
```
