# AquaTrack Backend

FastAPI backend cho ứng dụng theo dõi hydration AquaTrack.

## Features

- 🔐 **Authentication**: JWT-based user authentication
- 🗄️ **Database**: PostgreSQL với SQLAlchemy ORM
- 📊 **Analytics**: Stats và insights về hydration
- 🤖 **AI Coach**: Context-aware coaching với OpenAI/Anthropic
- 🎮 **Gamification**: Level system và achievements
- 📱 **API**: RESTful API cho Flutter app

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Setup Environment

```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Setup Database

```bash
# Install PostgreSQL and create database
createdb aquatrack_db
```

### 4. Run Development Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API sẽ chạy tại: http://localhost:8000

- **Docs**: http://localhost:8000/docs
- **Health**: http://localhost:8000/health

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Đăng ký user mới
- `POST /api/v1/auth/login` - Đăng nhập
- `POST /api/v1/auth/refresh` - Refresh token

### Intake Logging
- `POST /api/v1/intake/log` - Log water intake
- `GET /api/v1/intake/today` - Today's intake summary
- `GET /api/v1/intake/history` - Intake history

### Stats & Analytics
- `GET /api/v1/stats/dashboard` - Dashboard summary
- `GET /api/v1/stats/weekly` - Weekly statistics
- `GET /api/v1/stats/trends` - Hydration trends

### AI Coach
- `POST /api/v1/coach/chat` - Chat với AQUA AI
- `GET /api/v1/coach/suggestions` - Daily suggestions

### Levels & Achievements
- `GET /api/v1/levels/current` - Current level info
- `GET /api/v1/levels/achievements` - User achievements
- `POST /api/v1/levels/claim` - Claim achievement

## Development

### Project Structure

```
app/
├── main.py              # FastAPI app instance
├── core/                # Core settings
│   ├── config.py        # Environment configuration
│   ├── database.py      # Database connection
│   └── security.py      # Authentication utilities
├── models/              # SQLAlchemy models
├── schemas/             # Pydantic schemas
├── crud/                # Database operations
├── api/v1/              # API endpoints
└── services/            # Business logic
```

### Running Tests

```bash
pytest
```

### Database Migrations

```bash
# Generate migration
alembic revision --autogenerate -m "Add new table"

# Run migration
alembic upgrade head
```

## Environment Variables

Xem `.env.example` để biết full list configuration options.

## Tech Stack

- **FastAPI**: Modern Python web framework
- **PostgreSQL**: Primary database
- **SQLAlchemy**: ORM
- **Alembic**: Database migrations
- **Pydantic**: Data validation
- **JWT**: Authentication
- **OpenAI/Anthropic**: AI integration