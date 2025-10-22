# eSIM & Device Management Portal (ePM)

Production-ready web application for managing eSIM profiles, activation codes, subscriptions, campaigns, devices, and notifications for Myanmar carriers.

## Project Overview

**Platform**: 100% Web Application / Windows PWA  
**Source Control**: GitHub  
**CI/CD**: Azure DevOps  
**Supported Operators**: MPT, ATOM, U9, MYTEL  

## Architecture

```
Frontend (React.js PWA)
├── Profile Management
├── Campaign Management  
├── AC Management
├── Device Management
├── Notifications & Reporting
└── Security & Authentication

Backend API (Node.js/FastAPI)
├── Carrier Integration Layer
├── Business Logic Services
├── Database Access Layer
└── Authentication & Authorization

Database (Azure SQL/PostgreSQL)
├── Profiles & Subscriptions
├── Activation Codes
├── Devices & Campaigns
└── Audit Logs
```

## Features

### Profile Management
- Add Profile / Add Profile by UPP (User Provisioning Portal)
- Generate AC (Single / Batch / By UPP)
- Query Batch AC generation results
- Upload profile secret
- Delete profile
- Query profile details, logs, and status
- Notifications for profile updates or errors
- Update profile parameters / Update profile by UPP
- Signature management for profile validation

### Campaign Management
- Add / Delete / Unlock campaign profiles
- Query campaign profile resources
- Profile recycle management (set recycle time, notifications)
- ES2+ interface integration for carrier-specific operations

### AC (Activation Code) Management
- Single and batch AC generation
- Allocate AC to profiles
- Check AC status
- Download AC from operator
- Query AC list and batch task results
- Revoke or confirm AC usage

### Subscription & Profile Configuration
- Create configuration templates (Quick Generation / Recommended)
- Assign subscription plans to profiles
- Generate AC for new or existing profiles
- Monitor profile status (active, inactive, pending, failed)
- Delete or recycle expired profiles

### Device Management
- Batch import devices
- Query device list and details
- Switch profile on devices
- Delete or deactivate device
- Bootstrap list for initial provisioning
- Troubleshoot device connectivity (download failure, network issues)

### Notifications & Reporting
- Send notifications for profile and device events
- Recycle notifications
- Download orders, confirm/cancel orders
- Query batch task results
- Audit logs for all operations

### Security & Teamwork
- Role-based access control: Admin, Operator, Viewer
- Track actions by team members
- Secure authentication (OAuth2 / JWT)
- Input validation, HTTPS/TLS, audit logging

## Quick Start

### Prerequisites
- Node.js 18+
- Azure CLI
- Git

### Installation

1. Clone repository:
```bash
git clone https://github.com/your-org/esim-device-management-portal.git
cd esim-device-management-portal
```

2. Install dependencies:
```bash
# Frontend
cd frontend
npm install

# Backend
cd ../backend
npm install
```

3. Configure environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Start development servers:
```bash
# Backend
npm run dev

# Frontend (new terminal)
cd frontend
npm start
```

5. Access the application:
- Web App: http://localhost:3000
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## Project Structure

```
esim-device-management-portal/
├── frontend/                    # React.js PWA
│   ├── public/
│   │   ├── manifest.json       # PWA manifest
│   │   └── sw.js              # Service worker
│   ├── src/
│   │   ├── components/        # Reusable components
│   │   ├── pages/            # Page components
│   │   ├── services/         # API services
│   │   ├── store/           # State management
│   │   └── utils/           # Utilities
│   ├── package.json
│   └── webpack.config.js
├── backend/                    # Node.js/FastAPI backend
│   ├── src/
│   │   ├── controllers/      # API controllers
│   │   ├── services/        # Business logic
│   │   ├── models/          # Data models
│   │   ├── middleware/      # Express middleware
│   │   └── integrations/    # Carrier APIs
│   ├── tests/
│   ├── package.json
│   └── server.js
├── database/
│   ├── migrations/          # Database migrations
│   ├── seeds/              # Test data
│   └── schema.sql          # Database schema
├── azure-pipelines/
│   ├── build.yml           # Build pipeline
│   ├── deploy.yml          # Deployment pipeline
│   └── test.yml            # Test pipeline
├── docs/
│   ├── api/                # API documentation
│   ├── user-guide/         # User documentation
│   └── architecture/       # Technical docs
├── .env.example
├── docker-compose.yml
├── Dockerfile
└── README.md
```

## API Endpoints

### Profile Management
```
POST /api/v1/profiles              # Create profile
GET /api/v1/profiles               # List profiles
GET /api/v1/profiles/{id}          # Get profile details
PUT /api/v1/profiles/{id}          # Update profile
DELETE /api/v1/profiles/{id}       # Delete profile
POST /api/v1/profiles/batch        # Batch operations
```

### Activation Code Management
```
POST /api/v1/activation-codes      # Generate AC
GET /api/v1/activation-codes       # List ACs
GET /api/v1/activation-codes/{id}  # Get AC details
PUT /api/v1/activation-codes/{id}  # Update AC status
DELETE /api/v1/activation-codes/{id} # Revoke AC
```

### Device Management
```
POST /api/v1/devices               # Register device
GET /api/v1/devices                # List devices
GET /api/v1/devices/{id}           # Get device details
PUT /api/v1/devices/{id}           # Update device
DELETE /api/v1/devices/{id}        # Remove device
POST /api/v1/devices/batch-import  # Batch import
```

### Campaign Management
```
POST /api/v1/campaigns             # Create campaign
GET /api/v1/campaigns              # List campaigns
GET /api/v1/campaigns/{id}         # Get campaign details
PUT /api/v1/campaigns/{id}         # Update campaign
DELETE /api/v1/campaigns/{id}      # Delete campaign
```

## Configuration

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/epm_db

# Redis
REDIS_URL=redis://localhost:6379/0

# Authentication
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=24h

# Carrier APIs
MPT_API_URL=https://api.mpt.com.mm
MPT_API_KEY=your-mpt-api-key
ATOM_API_URL=https://api.atom.com.mm
ATOM_API_KEY=your-atom-api-key
U9_API_URL=https://api.u9.com.mm
U9_API_KEY=your-u9-api-key
MYTEL_API_URL=https://api.mytel.com.mm
MYTEL_API_KEY=your-mytel-api-key

# Azure
AZURE_STORAGE_CONNECTION_STRING=your-storage-connection
AZURE_SERVICE_BUS_CONNECTION_STRING=your-servicebus-connection
```

### Myanmar Carriers Configuration
```yaml
carriers:
  MPT:
    name: "Myanmar Posts and Telecommunications"
    mcc: "414"
    mnc: "01"
    api_endpoint: "https://api.mpt.com.mm"
    supported_features: ["profile_management", "ac_generation", "device_management"]
  
  ATOM:
    name: "Atom Myanmar"
    mcc: "414"
    mnc: "06"
    api_endpoint: "https://api.atom.com.mm"
    supported_features: ["profile_management", "ac_generation", "device_management"]
  
  U9:
    name: "U9 Networks"
    mcc: "414"
    mnc: "07"
    api_endpoint: "https://api.u9.com.mm"
    supported_features: ["profile_management", "ac_generation", "device_management"]
  
  MYTEL:
    name: "MyTel Myanmar"
    mcc: "414"
    mnc: "09"
    api_endpoint: "https://api.mytel.com.mm"
    supported_features: ["profile_management", "ac_generation", "device_management"]
```

## Development

### Setup Development Environment
```bash
# Install dependencies
npm install

# Start development servers
npm run dev:backend &
npm run dev:frontend

# Run tests
npm test

# Build for production
npm run build
```

### Code Quality
```bash
# Lint code
npm run lint

# Format code
npm run format

# Type checking
npm run type-check

# Security audit
npm audit
```

## Deployment

### Azure App Service Deployment
```bash
# Build production bundle
npm run build

# Deploy to Azure
az webapp deployment source config-zip \
  --resource-group epm-rg \
  --name epm-app \
  --src dist.zip
```

### Docker Deployment
```bash
# Build Docker image
docker build -t epm-portal:latest .

# Run container
docker run -p 3000:3000 -p 8000:8000 epm-portal:latest
```

### PWA Installation
1. Open the web app in Chrome/Edge
2. Click "Install" button in address bar
3. App will be installed as native Windows application

## Testing

### Test Categories
```bash
# Unit tests
npm run test:unit

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# API tests
npm run test:api
```

### Test Coverage
- Minimum 80% code coverage
- All API endpoints tested
- Critical user flows covered
- Carrier integration mocked

## Security

### Authentication & Authorization
- JWT-based authentication
- Role-based access control (RBAC)
- Multi-factor authentication (MFA) support
- Session management

### Data Protection
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- CSRF protection
- Data encryption at rest and in transit

### Audit & Compliance
- Comprehensive audit logging
- User activity tracking
- Compliance reporting
- Data retention policies

## Monitoring

### Application Monitoring
- Azure Application Insights
- Performance metrics
- Error tracking
- User analytics

### Infrastructure Monitoring
- Azure Monitor
- Resource utilization
- Availability monitoring
- Alert management

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards
- Follow ESLint configuration
- Use TypeScript for type safety
- Write comprehensive tests
- Update documentation
- Follow semantic versioning

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/your-org/esim-device-management-portal/issues)
- Email: support@epm.com.mm

## Roadmap

### Phase 1 (Current)
- [x] Core profile management
- [x] Basic AC generation
- [x] Device registration
- [x] Myanmar carrier integration

### Phase 2 (Q2 2024)
- [ ] Advanced campaign management
- [ ] Bulk operations
- [ ] Real-time notifications
- [ ] Enhanced reporting

### Phase 3 (Q3 2024)
- [ ] Multi-tenant support
- [ ] Advanced analytics
- [ ] Mobile companion app
- [ ] International expansion

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.