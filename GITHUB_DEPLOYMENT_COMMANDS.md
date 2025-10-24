# GitHub Deployment Commands - eSIM Manager System

## Repository Setup and Initial Push

### 1. Initialize Git Repository
```bash
# Navigate to project directory
cd c:\Users\igsim\OneDrive\Documents\GitHub\esim-enterprise-management

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Production-ready eSIM Manager System

- GSMA SGP.22/SGP.32 compliant implementation
- Complete security framework with PKI and HSM support
- PostgreSQL database with comprehensive schema
- FastAPI REST API with authentication
- Docker containerization and Kubernetes deployment
- CI/CD pipeline with security scanning
- Comprehensive monitoring and logging
- Myanmar carrier integration (MPT, ATOM, U9, MYTEL)
- Production deployment guides and compliance documentation"
```

### 2. Create GitHub Repository
```bash
# Create repository on GitHub (via CLI or web interface)
gh repo create esim-enterprise-management --public --description "Production-ready GSMA-compliant eSIM/eUICC management platform for Myanmar carriers"

# Or create via web interface at https://github.com/new
```

### 3. Connect Local Repository to GitHub
```bash
# Add remote origin
git remote add origin https://github.com/YOUR_USERNAME/esim-enterprise-management.git

# Verify remote
git remote -v

# Push to GitHub
git push -u origin main
```

## Branch Strategy Setup

### 4. Create Development Branches
```bash
# Create and switch to develop branch
git checkout -b develop
git push -u origin develop

# Create feature branch structure
git checkout -b feature/gsma-compliance
git push -u origin feature/gsma-compliance

git checkout -b feature/security-enhancements  
git push -u origin feature/security-enhancements

git checkout -b feature/myanmar-carriers
git push -u origin feature/myanmar-carriers

# Return to main branch
git checkout main
```

### 5. Set Branch Protection Rules
```bash
# Via GitHub CLI
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["quality-checks","tests","security-scan"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":2,"dismiss_stale_reviews":true}' \
  --field restrictions=null

# Or configure via GitHub web interface:
# Settings > Branches > Add rule for 'main'
```

## Environment Setup

### 6. Configure GitHub Secrets
```bash
# Add secrets via GitHub CLI
gh secret set DATABASE_URL --body "postgresql://user:pass@localhost:5432/esim_db"
gh secret set REDIS_URL --body "redis://localhost:6379/0"  
gh secret set JWT_SECRET --body "$(openssl rand -base64 64)"
gh secret set ENCRYPTION_KEY --body "$(openssl rand -base64 32)"
gh secret set DOCKER_USERNAME --body "your_docker_username"
gh secret set DOCKER_PASSWORD --body "your_docker_password"
gh secret set SLACK_WEBHOOK --body "https://hooks.slack.com/services/..."

# Or add via GitHub web interface:
# Settings > Secrets and variables > Actions > New repository secret
```

### 7. Configure GitHub Environments
```bash
# Create staging environment
gh api repos/:owner/:repo/environments/staging --method PUT

# Create production environment with protection rules
gh api repos/:owner/:repo/environments/production --method PUT \
  --field protection_rules='[{"type":"required_reviewers","reviewers":[{"type":"User","id":123}]}]'
```

## Deployment Commands

### 8. Manual Deployment Trigger
```bash
# Trigger deployment workflow manually
gh workflow run "eSIM Manager CI/CD Pipeline" --ref main

# Check workflow status
gh run list --workflow="eSIM Manager CI/CD Pipeline"

# View workflow logs
gh run view --log
```

### 9. Release Management
```bash
# Create a new release
git tag -a v1.0.0 -m "Production release v1.0.0

Features:
- Complete GSMA SGP.22/SGP.32 implementation
- Production-ready security framework
- Myanmar carrier integration
- Comprehensive monitoring and logging
- Full compliance documentation"

# Push tags
git push origin --tags

# Create GitHub release
gh release create v1.0.0 \
  --title "eSIM Manager v1.0.0 - Production Release" \
  --notes "Production-ready release with full GSMA compliance and Myanmar carrier support" \
  --prerelease=false
```

### 10. Container Registry Setup
```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Build and push Docker image
docker build -t ghcr.io/YOUR_USERNAME/esim-enterprise-management:latest .
docker push ghcr.io/YOUR_USERNAME/esim-enterprise-management:latest

# Tag specific version
docker tag ghcr.io/YOUR_USERNAME/esim-enterprise-management:latest ghcr.io/YOUR_USERNAME/esim-enterprise-management:v1.0.0
docker push ghcr.io/YOUR_USERNAME/esim-enterprise-management:v1.0.0
```

## Monitoring and Maintenance

### 11. Monitor Deployments
```bash
# Check deployment status
gh api repos/:owner/:repo/deployments

# View deployment logs
gh api repos/:owner/:repo/deployments/:deployment_id/statuses

# Monitor workflow runs
gh run list --limit 10

# View specific run details
gh run view RUN_ID
```

### 12. Issue and PR Management
```bash
# Create issue template
gh issue create --title "Bug Report Template" --body-file .github/ISSUE_TEMPLATE/bug_report.md

# List open issues
gh issue list --state open

# Create pull request
gh pr create --title "Feature: Enhanced Security Framework" --body "Implements advanced security features for production deployment"

# Review pull request
gh pr review PR_NUMBER --approve --body "LGTM! Security implementation looks solid."

# Merge pull request
gh pr merge PR_NUMBER --squash
```

## Backup and Recovery

### 13. Repository Backup
```bash
# Clone repository with all branches and history
git clone --mirror https://github.com/YOUR_USERNAME/esim-enterprise-management.git esim-backup.git

# Create backup archive
tar -czf esim-enterprise-management-backup-$(date +%Y%m%d).tar.gz esim-backup.git/

# Upload to secure storage
aws s3 cp esim-enterprise-management-backup-$(date +%Y%m%d).tar.gz s3://your-backup-bucket/
```

### 14. Disaster Recovery
```bash
# Restore from backup
tar -xzf esim-enterprise-management-backup-YYYYMMDD.tar.gz
cd esim-backup.git
git clone . ../esim-enterprise-management-restored
cd ../esim-enterprise-management-restored

# Push to new repository if needed
git remote set-url origin https://github.com/YOUR_USERNAME/esim-enterprise-management-new.git
git push --all origin
git push --tags origin
```

## Security and Compliance

### 15. Security Scanning
```bash
# Run security scan locally
docker run --rm -v $(pwd):/app securecodewarrior/github-action-add-sarif:latest

# Check for secrets in repository
git secrets --scan

# Audit dependencies
npm audit  # for Node.js dependencies
safety check  # for Python dependencies
```

### 16. Compliance Verification
```bash
# Generate compliance report
python scripts/generate_compliance_report.py

# Validate GSMA compliance
python scripts/validate_gsma_compliance.py

# Check security compliance
python scripts/security_compliance_check.py
```

## Automation Scripts

### 17. Automated Deployment Script
```bash
#!/bin/bash
# deploy.sh - Automated deployment script

set -e

echo "Starting automated deployment..."

# Check if on main branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "main" ]; then
    echo "Error: Must be on main branch for deployment"
    exit 1
fi

# Run tests
echo "Running tests..."
pytest tests/ -v

# Build Docker image
echo "Building Docker image..."
docker build -t esim-manager:latest .

# Run security scan
echo "Running security scan..."
trivy image esim-manager:latest

# Deploy to staging
echo "Deploying to staging..."
kubectl apply -f k8s/staging/ --namespace=esim-staging

# Wait for deployment
kubectl rollout status deployment/esim-api --namespace=esim-staging

# Run smoke tests
echo "Running smoke tests..."
python tests/smoke_tests.py --environment=staging

# Deploy to production (with approval)
read -p "Deploy to production? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying to production..."
    kubectl apply -f k8s/production/ --namespace=esim-production
    kubectl rollout status deployment/esim-api --namespace=esim-production
    echo "Production deployment complete!"
fi
```

### 18. Repository Maintenance
```bash
#!/bin/bash
# maintenance.sh - Repository maintenance script

# Update dependencies
pip-compile requirements.in
npm update

# Clean up old branches
git remote prune origin
git branch --merged main | grep -v main | xargs -n 1 git branch -d

# Update documentation
python scripts/generate_api_docs.py
python scripts/update_readme.py

# Commit updates
git add .
git commit -m "chore: Update dependencies and documentation"
git push origin main

echo "Repository maintenance complete!"
```

## Quick Reference Commands

### Essential Git Commands
```bash
# Check status
git status

# Add changes
git add .

# Commit changes
git commit -m "feat: Add new feature"

# Push changes
git push origin main

# Pull latest changes
git pull origin main

# Create and switch branch
git checkout -b feature/new-feature

# Merge branch
git checkout main
git merge feature/new-feature

# Delete branch
git branch -d feature/new-feature
```

### GitHub CLI Quick Commands
```bash
# View repository info
gh repo view

# Create issue
gh issue create

# Create pull request
gh pr create

# View workflow runs
gh run list

# Clone repository
gh repo clone YOUR_USERNAME/esim-enterprise-management
```

This comprehensive guide provides all necessary commands for deploying and maintaining the eSIM Manager System on GitHub with proper CI/CD, security, and compliance procedures.