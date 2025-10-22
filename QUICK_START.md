# eSIM Enterprise Management - Quick Start Guide

## Prerequisites
- Node.js 18+
- PostgreSQL 12+
- Git

## Setup Instructions

### 1. Clone Repository
```bash
git clone https://github.com/kaunghtetpai/esim-enterprise-management.git
cd esim-enterprise-management
```

### 2. Install Dependencies
```bash
npm run install:all
```

### 3. Configure Environment
```bash
cp .env.example .env
```

Edit `.env` file with your configuration:
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/epm_db

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key

# Carrier APIs
MPT_API_KEY=your-mpt-api-key
ATOM_API_KEY=your-atom-api-key
U9_API_KEY=your-u9-api-key
MYTEL_API_KEY=your-mytel-api-key
```

### 4. Setup Database
```bash
# Create database
createdb epm_db

# Run migrations
psql -d epm_db -f database/schema.sql
```

### 5. Start Development Servers
```bash
# Start backend (Terminal 1)
npm run dev:backend

# Start frontend (Terminal 2)
npm run dev:frontend
```

### 6. Access Application
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/health

## Default Login
- Username: admin
- Password: admin123

## Available Scripts
- `npm run dev:frontend` - Start React development server
- `npm run dev:backend` - Start Node.js API server
- `npm run build` - Build for production
- `npm test` - Run test suite
- `npm run install:all` - Install all dependencies

## Project Structure
```
esim-enterprise-management/
├── frontend/          # React.js PWA
├── backend/           # Node.js API
├── database/          # Database schema
├── azure-pipelines/   # CI/CD pipelines
└── docs/             # Documentation
```

## Troubleshooting
- Ensure PostgreSQL is running
- Check port 3000 and 8000 are available
- Verify environment variables are set correctly