# Quick Start Guide

## 🚀 Automated Deployment (Recommended)

This repository is configured for **automated Terraform deployment** via GitHub Actions.

### Prerequisites
- AWS credentials configured in GitHub repository secrets
- S3 backend created (see below)

### Deploy the Cluster

**Option 1: Automatic (if enabled during creation)**
- Deployment started automatically when repository was created
- Check [GitHub Actions](./../actions) for progress

**Option 2: Manual Trigger**
1. Go to [Actions](./../actions) tab
2. Select "Terraform ECS Cluster Deployment"
3. Click "Run workflow"
4. Choose action: **apply**
5. Click "Run workflow" button

⏱️ **Deployment time**: ~5-10 minutes

## 🛠️ Local Deployment with Makefile

### First-Time Setup

```bash
# 1. Clone this repository
git clone <repo-url>
cd <repo-name>

# 2. Configure AWS credentials
export AWS_PROFILE=your-profile
# OR
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx

# 3. Create S3 backend (one-time setup)
make create-backend

# 4. Initialize Terraform
make init
```

### Deploy

```bash
# Plan changes
make plan ENV=dev

# Apply changes
make apply ENV=dev

# View outputs
make output
```

### Destroy

```bash
make destroy ENV=dev
```

## 📋 Available Make Commands

```bash
make help                    # Show all commands
make init                    # Initialize Terraform
make plan ENV=<env>          # Plan changes
make apply ENV=<env>         # Apply changes
make destroy ENV=<env>       # Destroy resources
make output                  # Show outputs
make create-backend          # Create S3 backend
make show-workspace          # Show current workspace
```

## 🔧 Configuration

### Current Settings

- **Cluster**: `nikhil-test`
- **Region**: `us-east-1`
- **Environment**: `dev`
- **Instance Type**: `t3.medium`
- **Capacity**: 1-10 instances

### Modify Settings

Edit `environments/dev.tfvars`:

```hcl
on_demand_min_size = 2
on_demand_max_size = 20
on_demand_desired_capacity = 5
```

Then apply:
```bash
make apply ENV=dev
```

## 🔐 S3 Backend Setup

The Terraform state is stored in S3. Create the backend infrastructure:

```bash
# Using Makefile
make create-backend

# Or manually
aws s3api create-bucket \
  --bucket backstage-terraform-state \
  --region us-east-1

aws dynamodb create-table \
  --table-name backstage-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## 📊 Verify Deployment

```bash
# Check cluster
aws ecs describe-clusters --clusters nikhil-test

# List instances
aws ecs list-container-instances --cluster nikhil-test

# View Terraform outputs
make output
```

## 🐛 Troubleshooting

### Module Not Found
```bash
# Copy modules from main Backstage repo
cp -r /path/to/backstage/modules ./
```

### State Lock Error
```bash
# Wait 20 minutes or force unlock
terraform force-unlock <LOCK_ID>
```

### Backend Doesn't Exist
```bash
make create-backend
```

## 📚 Documentation

- **Full Guide**: See [README.md](./README.md)
- **Deployment Guide**: See [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Module Docs**: See `modules/ecs-cluster/README.md`

## 🎯 Next Steps

1. ✅ Deploy the cluster
2. ⬜ Deploy ECS services using `ecs-service` module
3. ⬜ Configure monitoring and alerts
4. ⬜ Set up application CI/CD

## 💡 Tips

- Use `make plan` before `make apply` to review changes
- Keep environment-specific settings in `environments/*.tfvars`
- Monitor costs in AWS Cost Explorer
- Enable Container Insights for better monitoring
- Use GitHub Actions for consistent deployments
