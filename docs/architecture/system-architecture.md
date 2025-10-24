# eSIM Business Manager Portal - System Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Microsoft Intune Cloud                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Device Mgmt   │  │   App Mgmt      │  │  Compliance     │ │
│  │   Graph API     │  │   Graph API     │  │  Policies       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                        ┌───────┴───────┐
                        │  Graph API    │
                        │  Integration  │
                        └───────┬───────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                 eSIM Business Manager Portal                    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    Frontend Layer                           │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │   Admin     │  │  IT Staff   │  │     End User        │ │ │
│  │  │  Dashboard  │  │  Dashboard  │  │     Portal          │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                │                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                   API Gateway                               │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │ Auth/RBAC   │  │ Rate Limit  │  │   API Routing       │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                │                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 Business Logic Layer                        │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │   Profile   │  │  Device     │  │    Activation       │ │ │
│  │  │  Service    │  │  Service    │  │    Service          │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │  Migration  │  │ Reporting   │  │    Audit            │ │ │
│  │  │  Service    │  │  Service    │  │    Service          │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                │                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 Data Access Layer                           │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │ Repository  │  │   Cache     │  │   File Storage      │ │ │
│  │  │  Pattern    │  │  (Redis)    │  │   (Azure Blob)      │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Database Layer                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   PostgreSQL    │  │   Audit Logs    │  │   File Metadata │ │
│  │   Primary DB    │  │   (Separate)    │  │   (NoSQL)       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│              Myanmar Telecom Operators                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │     MPT     │  │    ATOM     │  │     U9      │  │  MYTEL  │ │
│  │   (414-01)  │  │   (414-06)  │  │   (414-07)  │  │(414-09) │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Frontend
- **Framework**: React.js 18+ with TypeScript
- **UI Library**: Material-UI v5 with Myanmar localization
- **State Management**: Redux Toolkit with RTK Query
- **PWA**: Service Worker for offline capabilities

### Backend
- **Runtime**: Node.js 18+ with Express.js
- **Language**: TypeScript for type safety
- **API**: RESTful with OpenAPI 3.0 documentation
- **Authentication**: JWT with Azure AD integration

### Database
- **Primary**: PostgreSQL 14+ for transactional data
- **Cache**: Redis 6+ for session and API caching
- **Audit**: Separate audit database for compliance
- **Files**: Azure Blob Storage for documents

### Infrastructure
- **Cloud**: Azure App Service with auto-scaling
- **CDN**: Azure CDN for global content delivery
- **Monitoring**: Application Insights for telemetry
- **Security**: Azure Key Vault for secrets management