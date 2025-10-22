# eSIM Manager System

Production-ready GSMA SGP.22/SGP.32 compliant eSIM/eUICC management platform for Myanmar carriers.

## Overview

This system provides comprehensive eSIM profile lifecycle management with full GSMA compliance, supporting MPT, ATOM, U9, and MYTEL carriers in Myanmar.

## Features

### GSMA Compliance
- SGP.22 (Consumer) specification implementation
- SGP.32 (M2M) specification support
- SM-DP+ server integration
- SM-DS discovery service
- LPA communication protocols
- eUICC certificate management

### Security
- End-to-end encryption (TLS 1.3, AES-256)
- PKI infrastructure with HSM support
- Digital signature validation
- Secure channel establishment (SCP03/SCP11)
- JWT authentication with MFA

### Core Operations
- Profile download and installation
- Profile enable/disable/delete
- eUICC information management
- Notification handling
- Audit logging

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Dashboard │    │   REST API      │    │   Core Engine   │
│                 │◄──►│                 │◄──►│                 │
│   React/Vue.js  │    │   FastAPI       │    │   Python/Async  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │   Message Queue │    │   Database      │
│                 │    │                 │    │                 │
│   Nginx/HAProxy │    │   Redis/Celery  │    │   PostgreSQL    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Python 3.11+
- PostgreSQL 15+
- Redis 7+

### Installation

1. Clone repository:
```bash
git clone https://github.com/your-org/esim-manager.git
cd esim-manager
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Start services:
```bash
docker-compose up -d
```

4. Initialize database:
```bash
docker-compose exec esim-api python -m alembic upgrade head
```

5. Access the system:
- API: http://localhost:8000
- Documentation: http://localhost:8000/docs
- Monitoring: http://localhost:3000

## API Endpoints

### Profile Management
```
POST /api/v1/profiles/download    # Download eSIM profile
POST /api/v1/profiles/enable      # Enable profile
POST /api/v1/profiles/disable     # Disable profile
DELETE /api/v1/profiles/delete    # Delete profile
```

### eUICC Management
```
GET /api/v1/euicc/{eid}/info      # Get eUICC information
GET /api/v1/profiles              # List profiles
```

### Authentication
```
POST /api/v1/auth/login           # User authentication
POST /api/v1/auth/refresh         # Token refresh
```

## Configuration

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/esim_db

# Redis
REDIS_URL=redis://localhost:6379/0

# Security
JWT_SECRET=your-secret-key
ENCRYPTION_KEY=your-encryption-key

# GSMA Settings
SMDP_SERVER_URL=https://smdp.example.com
SMDS_SERVER_URL=https://smds.example.com
```

### Myanmar Carriers
```yaml
carriers:
  MPT:
    mcc: "414"
    mnc: "01"
    smdp_address: "smdp.mpt.com.mm"
  ATOM:
    mcc: "414" 
    mnc: "06"
    smdp_address: "smdp.atom.com.mm"
  U9:
    mcc: "414"
    mnc: "07"
    smdp_address: "smdp.u9.com.mm"
  MYTEL:
    mcc: "414"
    mnc: "09"
    smdp_address: "smdp.mytel.com.mm"
```

## Development

### Setup Development Environment
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Install pre-commit hooks
pre-commit install

# Run tests
pytest tests/

# Start development server
uvicorn src.api.rest_api:app --reload
```

### Code Quality
```bash
# Format code
black src/ tests/
isort src/ tests/

# Lint code
flake8 src/ tests/
mypy src/

# Security scan
bandit -r src/
```

## Deployment

### Production Deployment
```bash
# Build production image
docker build -t esim-manager:latest .

# Deploy with Kubernetes
kubectl apply -f k8s/

# Or deploy with Docker Compose
docker-compose -f docker-compose.prod.yml up -d
```

### Monitoring
- Prometheus metrics: http://localhost:9090
- Grafana dashboards: http://localhost:3000
- Application logs: `docker-compose logs -f esim-api`

## Security

### Compliance Standards
- GSMA RSP specifications
- ISO/IEC 27001
- GDPR compliance
- Myanmar telecommunications regulations

### Security Features
- TLS 1.3 encryption
- Certificate pinning
- Rate limiting
- Input validation
- SQL injection prevention
- XSS protection

## Testing

### Test Categories
```bash
# Unit tests
pytest tests/unit/

# Integration tests  
pytest tests/integration/

# Load tests
k6 run tests/performance/load-test.js

# Security tests
pytest tests/security/
```

### Test Coverage
- Minimum 90% code coverage
- All API endpoints tested
- Security scenarios covered
- Performance benchmarks

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards
- Follow PEP 8 style guide
- Add type hints
- Write comprehensive tests
- Update documentation
- Security review required

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/your-org/esim-manager/issues)
- Email: admin@mdm.esim.com.mm
- Slack: #esim-support

## Roadmap

### Phase 1 (Current)
- [x] Core eSIM operations
- [x] GSMA SGP.22 compliance
- [x] Myanmar carrier support
- [x] Security implementation

### Phase 2 (Q2 2024)
- [ ] Web dashboard
- [ ] Advanced monitoring
- [ ] Multi-tenant support
- [ ] API rate limiting

### Phase 3 (Q3 2024)
- [ ] Mobile applications
- [ ] Advanced analytics
- [ ] Machine learning insights
- [ ] International expansion

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.