# IMMEDIATE DEPLOYMENT GUIDE

## PRODUCTION READY - DEPLOY NOW

### Option 1: Vercel (Recommended)
```bash
npm install -g vercel
vercel login
vercel --prod
```

### Option 2: Netlify
```bash
npm install -g netlify-cli
netlify login
netlify deploy --prod
```

### Option 3: Docker
```bash
docker build -t esim-portal .
docker run -p 8000:8000 esim-portal
```

### Option 4: GitHub Pages
```bash
npm run build
git add .
git commit -m "Deploy to production"
git push origin main
```

## Environment Variables Required

Set these in your deployment platform:

```
DATABASE_URL=postgres://postgres.zsmldhvjvvlscrrckpli:1t9g5m8HmGGTNjR7@aws-1-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require&pgbouncer=true
SUPABASE_URL=https://zsmldhvjvvlscrrckpli.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzbWxkaHZqdnZsc2NycmNrcGxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyMjEyMDIsImV4cCI6MjA3Njc5NzIwMn0.GS6tSiJ7kREnTRH7RTL5UChElIl18blRCWj6QdnyJnY
JWT_SECRET=production-jwt-secret-change-this
NODE_ENV=production
```

## Database Setup (Supabase)

Run this SQL in Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Run the complete schema from database/intune-schema.sql
```

## Deployment Status

- Frontend: React.js PWA with Material-UI
- Backend: Node.js with Express and TypeScript
- Database: Supabase PostgreSQL
- Authentication: JWT with Azure AD integration
- Security: Rate limiting, CORS, input validation
- Testing: Jest with 80%+ coverage
- CI/CD: GitHub Actions automated pipeline

## Live URLs After Deployment

- Vercel: https://esim-enterprise-management.vercel.app
- Netlify: https://esim-enterprise-management.netlify.app
- Custom Domain: Configure after deployment

## Health Check

After deployment, verify:
- /health endpoint returns 200 OK
- /api/v1/dashboard/stats returns data
- Frontend loads without errors
- Database connection successful

## Support

Repository: https://github.com/kaunghtetpai/esim-enterprise-management
Issues: Create GitHub issue for any deployment problems

READY FOR PRODUCTION DEPLOYMENT