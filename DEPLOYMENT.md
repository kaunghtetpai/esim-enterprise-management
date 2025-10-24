# Deployment Guide

## Prerequisites

1. Node.js 18+ installed
2. PostgreSQL 14+ database
3. Azure account for Intune integration
4. GitHub account

## Local Development Setup

### 1. Clone Repository
```bash
git clone https://github.com/kaunghtetpai/esim-enterprise-management.git
cd esim-enterprise-management
```

### 2. Install Dependencies
```bash
npm run install:all
```

### 3. Database Setup
```bash
# Create PostgreSQL database
createdb esim_portal

# Run database schema
psql -d esim_portal -f database/intune-schema.sql
```

### 4. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# - Database connection string
# - Azure AD credentials
# - JWT secret
# - Myanmar carrier API keys
```

### 5. Start Development Servers
```bash
# Terminal 1: Backend
npm run dev:backend

# Terminal 2: Frontend
npm run dev:frontend
```

## Production Deployment

### 1. Build Application
```bash
npm run build
```

### 2. Azure App Service Deployment
```bash
# Install Azure CLI
npm install -g @azure/cli

# Login to Azure
az login

# Create resource group
az group create --name esim-portal-rg --location "Southeast Asia"

# Create App Service plan
az appservice plan create --name esim-portal-plan --resource-group esim-portal-rg --sku P1V3

# Create web app
az webapp create --resource-group esim-portal-rg --plan esim-portal-plan --name esim-portal-app --runtime "NODE|18-lts"

# Deploy application
az webapp deployment source config-zip --resource-group esim-portal-rg --name esim-portal-app --src dist.zip
```

### 3. Database Deployment
```bash
# Create Azure Database for PostgreSQL
az postgres server create --resource-group esim-portal-rg --name esim-portal-db --location "Southeast Asia" --admin-user adminuser --admin-password SecurePassword123! --sku-name GP_Gen5_2

# Configure firewall
az postgres server firewall-rule create --resource-group esim-portal-rg --server esim-portal-db --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Run database schema
psql -h esim-portal-db.postgres.database.azure.com -U adminuser@esim-portal-db -d postgres -f database/intune-schema.sql
```

### 4. Environment Variables
```bash
# Set production environment variables
az webapp config appsettings set --resource-group esim-portal-rg --name esim-portal-app --settings \
  NODE_ENV=production \
  DATABASE_URL="postgresql://adminuser@esim-portal-db:SecurePassword123!@esim-portal-db.postgres.database.azure.com:5432/postgres?ssl=true" \
  JWT_SECRET="your-production-jwt-secret" \
  AZURE_CLIENT_ID="your-azure-client-id" \
  AZURE_CLIENT_SECRET="your-azure-client-secret" \
  AZURE_TENANT_ID="your-azure-tenant-id"
```

## GitHub Actions CI/CD

The repository includes automated CI/CD pipeline that:
1. Runs tests on every push
2. Builds application for production
3. Deploys to Azure on main branch updates
4. Performs security scans

## Health Checks

After deployment, verify:
- Health endpoint: `https://your-app.azurewebsites.net/health`
- Database connectivity
- API functionality
- Frontend loading

## Monitoring

Set up monitoring with:
- Azure Application Insights
- Database performance monitoring
- Error tracking and alerting
- User analytics

## Security Checklist

- [ ] HTTPS enabled
- [ ] Security headers configured
- [ ] Database encryption enabled
- [ ] API rate limiting active
- [ ] Authentication working
- [ ] Audit logging functional
- [ ] Backup strategy implemented

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check connection string format
   - Verify firewall rules
   - Confirm SSL settings

2. **Authentication Errors**
   - Validate Azure AD configuration
   - Check client ID and secret
   - Verify redirect URLs

3. **Build Failures**
   - Check Node.js version compatibility
   - Verify all dependencies installed
   - Review TypeScript compilation errors

### Support

For deployment issues:
1. Check application logs in Azure portal
2. Review GitHub Actions workflow logs
3. Verify environment variable configuration
4. Test database connectivity