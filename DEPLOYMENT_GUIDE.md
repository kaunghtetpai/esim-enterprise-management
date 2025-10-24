# eSIM Manager System - Production Deployment Guide

## Pre-Deployment Checklist

### Infrastructure Requirements
- [ ] Kubernetes cluster (v1.25+) or Docker Swarm
- [ ] PostgreSQL 15+ database cluster
- [ ] Redis 7+ cluster for caching
- [ ] Load balancer (Nginx/HAProxy)
- [ ] SSL certificates (Let's Encrypt or commercial)
- [ ] HSM for cryptographic operations
- [ ] Monitoring stack (Prometheus/Grafana)

### Security Requirements
- [ ] Network segmentation configured
- [ ] Firewall rules implemented
- [ ] VPN access for administrators
- [ ] Certificate management system
- [ ] Backup and disaster recovery plan
- [ ] Security scanning completed

### Compliance Requirements
- [ ] GSMA certification obtained
- [ ] Myanmar telecom regulations reviewed
- [ ] Data protection policies implemented
- [ ] Audit logging configured
- [ ] Incident response procedures

## Step-by-Step Deployment

### 1. Environment Preparation

#### Create Production Environment File
```bash
# Create .env.production
cat > .env.production << EOF
# Database Configuration
DATABASE_URL=postgresql://esim_user:${SECURE_DB_PASSWORD}@db-cluster:5432/esim_production
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30

# Redis Configuration
REDIS_URL=redis://:${SECURE_REDIS_PASSWORD}@redis-cluster:6379/0
REDIS_POOL_SIZE=50

# Security Configuration
JWT_SECRET=${SECURE_JWT_SECRET}
ENCRYPTION_KEY=${SECURE_ENCRYPTION_KEY}
HSM_ENDPOINT=${HSM_SERVER_URL}
HSM_CREDENTIALS=${HSM_ACCESS_TOKEN}

# GSMA Configuration
SMDP_SERVER_URL=https://smdp.production.com
SMDS_SERVER_URL=https://smds.production.com
CA_CERTIFICATE_PATH=/app/certs/ca.pem
SERVER_CERTIFICATE_PATH=/app/certs/server.pem
SERVER_PRIVATE_KEY_PATH=/app/certs/server.key

# Monitoring
PROMETHEUS_ENABLED=true
GRAFANA_ENABLED=true
LOG_LEVEL=INFO
SENTRY_DSN=${SENTRY_DSN}

# Myanmar Carriers
MPT_SMDP_URL=https://smdp.mpt.com.mm
ATOM_SMDP_URL=https://smdp.atom.com.mm
U9_SMDP_URL=https://smdp.u9.com.mm
MYTEL_SMDP_URL=https://smdp.mytel.com.mm
EOF
```

#### Generate Secure Secrets
```bash
# Generate JWT secret
JWT_SECRET=$(openssl rand -base64 64)

# Generate encryption key
ENCRYPTION_KEY=$(openssl rand -base64 32)

# Generate database password
DB_PASSWORD=$(openssl rand -base64 32)

# Generate Redis password
REDIS_PASSWORD=$(openssl rand -base64 32)
```

### 2. Database Setup

#### Initialize Production Database
```sql
-- Connect as superuser
CREATE USER esim_user WITH PASSWORD '${SECURE_DB_PASSWORD}';
CREATE DATABASE esim_production OWNER esim_user;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE esim_production TO esim_user;

-- Connect to esim_production database
\c esim_production

-- Run schema creation
\i src/database/schema.sql

-- Create additional indexes for production
CREATE INDEX CONCURRENTLY idx_profile_operations_performance 
ON profile_operations(eid, operation_type, created_at);

CREATE INDEX CONCURRENTLY idx_notification_events_delivery 
ON notification_events(delivery_status, next_retry_at);

-- Enable query performance monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

#### Database Backup Configuration
```bash
# Create backup script
cat > /opt/esim/backup-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/esim/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="esim_backup_${TIMESTAMP}.sql"

# Create backup
pg_dump -h db-cluster -U esim_user -d esim_production > "${BACKUP_DIR}/${BACKUP_FILE}"

# Compress backup
gzip "${BACKUP_DIR}/${BACKUP_FILE}"

# Upload to S3 (optional)
aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}.gz" s3://esim-backups/

# Clean old backups (keep 30 days)
find ${BACKUP_DIR} -name "esim_backup_*.sql.gz" -mtime +30 -delete
EOF

chmod +x /opt/esim/backup-db.sh

# Add to crontab
echo "0 2 * * * /opt/esim/backup-db.sh" | crontab -
```

### 3. Kubernetes Deployment

#### Create Namespace and Secrets
```bash
# Create namespace
kubectl create namespace esim-production

# Create secrets
kubectl create secret generic esim-secrets \
  --from-literal=database-url="${DATABASE_URL}" \
  --from-literal=redis-url="${REDIS_URL}" \
  --from-literal=jwt-secret="${JWT_SECRET}" \
  --from-literal=encryption-key="${ENCRYPTION_KEY}" \
  -n esim-production

# Create TLS secret
kubectl create secret tls esim-tls \
  --cert=certs/server.crt \
  --key=certs/server.key \
  -n esim-production
```

#### Deploy Application
```yaml
# k8s/production/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: esim-api
  namespace: esim-production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: esim-api
  template:
    metadata:
      labels:
        app: esim-api
    spec:
      containers:
      - name: esim-api
        image: ghcr.io/your-org/esim-manager:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: esim-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: esim-secrets
              key: redis-url
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
# Apply deployment
kubectl apply -f k8s/production/
```

### 4. Load Balancer Configuration

#### Nginx Configuration
```nginx
# /etc/nginx/sites-available/esim-manager
upstream esim_backend {
    least_conn;
    server esim-api-1:8000 max_fails=3 fail_timeout=30s;
    server esim-api-2:8000 max_fails=3 fail_timeout=30s;
    server esim-api-3:8000 max_fails=3 fail_timeout=30s;
}

server {
    listen 443 ssl http2;
    server_name api.esim.com.mm;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;

    location / {
        proxy_pass http://esim_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://esim_backend;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name api.esim.com.mm;
    return 301 https://$server_name$request_uri;
}
```

### 5. Monitoring Setup

#### Prometheus Configuration
```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'esim-api'
    static_configs:
      - targets: ['esim-api:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

#### Grafana Dashboard
```json
{
  "dashboard": {
    "title": "eSIM Manager Production Dashboard",
    "panels": [
      {
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Profile Operations",
        "type": "graph", 
        "targets": [
          {
            "expr": "rate(esim_profile_operations_total[5m])",
            "legendFormat": "{{operation_type}}"
          }
        ]
      }
    ]
  }
}
```

### 6. Security Hardening

#### Network Security
```bash
# Firewall rules (iptables)
# Allow only necessary ports
iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # HTTPS
iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # SSH (from VPN only)
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT # PostgreSQL (internal only)
iptables -A INPUT -p tcp --dport 6379 -j ACCEPT # Redis (internal only)

# Drop all other traffic
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
```

#### Application Security
```bash
# Create security scanning script
cat > /opt/esim/security-scan.sh << 'EOF'
#!/bin/bash

# Container vulnerability scan
trivy image ghcr.io/your-org/esim-manager:latest

# Dependency vulnerability scan
safety check -r requirements.txt

# Code security scan
bandit -r src/

# Network security scan
nmap -sS -O target_server

# SSL/TLS configuration test
testssl.sh https://api.esim.com.mm
EOF
```

### 7. Backup and Disaster Recovery

#### Backup Strategy
```bash
# Create comprehensive backup script
cat > /opt/esim/full-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_ROOT="/opt/esim/backups/${BACKUP_DATE}"

mkdir -p ${BACKUP_ROOT}

# Database backup
pg_dump -h db-cluster -U esim_user esim_production > ${BACKUP_ROOT}/database.sql

# Redis backup
redis-cli --rdb ${BACKUP_ROOT}/redis.rdb

# Configuration backup
cp -r /opt/esim/config ${BACKUP_ROOT}/

# Certificate backup
cp -r /opt/esim/certs ${BACKUP_ROOT}/

# Compress and encrypt
tar -czf ${BACKUP_ROOT}.tar.gz ${BACKUP_ROOT}
gpg --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
    --s2k-digest-algo SHA512 --s2k-count 65536 --symmetric \
    --output ${BACKUP_ROOT}.tar.gz.gpg ${BACKUP_ROOT}.tar.gz

# Upload to secure storage
aws s3 cp ${BACKUP_ROOT}.tar.gz.gpg s3://esim-secure-backups/

# Cleanup
rm -rf ${BACKUP_ROOT} ${BACKUP_ROOT}.tar.gz
EOF
```

#### Disaster Recovery Plan
```bash
# Create disaster recovery script
cat > /opt/esim/disaster-recovery.sh << 'EOF'
#!/bin/bash

echo "Starting disaster recovery process..."

# 1. Restore database
echo "Restoring database..."
psql -h new-db-cluster -U esim_user -d esim_production < backup/database.sql

# 2. Restore Redis data
echo "Restoring Redis data..."
redis-cli --rdb backup/redis.rdb

# 3. Deploy application
echo "Deploying application..."
kubectl apply -f k8s/production/

# 4. Verify services
echo "Verifying services..."
kubectl get pods -n esim-production
curl -f https://api.esim.com.mm/health

echo "Disaster recovery completed"
EOF
```

### 8. Post-Deployment Verification

#### Health Checks
```bash
# API health check
curl -f https://api.esim.com.mm/health

# Database connectivity
psql -h db-cluster -U esim_user -d esim_production -c "SELECT 1;"

# Redis connectivity  
redis-cli -h redis-cluster ping

# Certificate validation
openssl s_client -connect api.esim.com.mm:443 -servername api.esim.com.mm

# Load test
k6 run --vus 100 --duration 5m tests/performance/load-test.js
```

#### Monitoring Verification
```bash
# Check Prometheus targets
curl http://prometheus:9090/api/v1/targets

# Check Grafana dashboards
curl -u admin:password http://grafana:3000/api/dashboards/home

# Verify alerting
curl http://alertmanager:9093/api/v1/alerts
```

## Maintenance Procedures

### Regular Maintenance Tasks
- [ ] Weekly security updates
- [ ] Monthly certificate renewal check
- [ ] Quarterly disaster recovery testing
- [ ] Annual security audit

### Performance Optimization
- [ ] Database query optimization
- [ ] Cache hit ratio monitoring
- [ ] Resource utilization analysis
- [ ] Capacity planning

### Compliance Monitoring
- [ ] GSMA compliance verification
- [ ] Audit log review
- [ ] Security incident response
- [ ] Regulatory compliance check

## Troubleshooting Guide

### Common Issues
1. **Database Connection Issues**
   - Check connection string
   - Verify network connectivity
   - Review firewall rules

2. **Certificate Expiration**
   - Monitor certificate expiry dates
   - Automate renewal process
   - Test certificate chain

3. **Performance Degradation**
   - Monitor resource usage
   - Check database performance
   - Review application logs

### Emergency Contacts
- **Technical Lead**: +95-xxx-xxx-xxxx
- **Database Admin**: +95-xxx-xxx-xxxx  
- **Security Team**: security@esim.com.mm
- **On-call Engineer**: oncall@esim.com.mm

This deployment guide ensures a secure, scalable, and compliant production deployment of the eSIM Manager System.