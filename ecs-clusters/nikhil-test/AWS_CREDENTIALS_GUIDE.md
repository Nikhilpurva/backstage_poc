# AWS Credentials Configuration Guide

## Overview

This guide explains how AWS credentials are configured for different deployment methods.

## Deployment Methods & Credentials

### 1. GitHub Actions (Automated Deployment)

GitHub Actions **does not use AWS profiles**. Instead, it uses:

#### Option A: OIDC (Recommended - No Long-Lived Credentials)

**Setup:**
1. Create IAM OIDC provider for GitHub
2. Create IAM role with trust policy for GitHub Actions
3. Add role ARN to GitHub repository secrets

**GitHub Secret Required:**
- `AWS_ROLE_ARN` = `arn:aws:iam::123456789012:role/github-actions-terraform`

**How it works:**
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: 
    aws-region: 
```

GitHub Actions gets temporary credentials by assuming the IAM role.

#### Option B: Access Keys (Simpler but Less Secure)

**GitHub Secrets Required:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**How it works:**
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: 
    aws-secret-access-key: 
    aws-region: 
```

### 2. Local Deployment (Makefile)

For local deployment, the Makefile uses **AWS CLI profiles**.

#### Configuration

The AWS profile is configured in the Backstage template form:
- **Field**: "AWS Profile (for local deployment)"
- **Default**: `toldev` (set during template creation)
- **Can be overridden** at runtime

#### Usage Examples

**Using the configured profile:**
```bash
# Uses the profile specified in the template
make init
make plan ENV=dev
make apply ENV=dev
```

**Override the profile:**
```bash
# Use a different profile
make apply ENV=dev AWS_PROFILE=toldev

# Or export it
export AWS_PROFILE=toldev
make apply ENV=dev
```

**Using environment variables instead:**
```bash
# Skip profiles, use direct credentials
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_DEFAULT_REGION=us-east-1

make apply ENV=dev
```

## AWS Profile Setup

### Check Existing Profiles

```bash
# List configured profiles
cat ~/.aws/credentials

# Or
aws configure list-profiles
```

### Configure a New Profile

```bash
# Interactive configuration
aws configure --profile toldev

# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region
# - Output format (json)
```

### Profile Files

Profiles are stored in:
- **Credentials**: `~/.aws/credentials`
- **Config**: `~/.aws/config`

Example `~/.aws/credentials`:
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[toldev]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

Example `~/.aws/config`:
```ini
[default]
region = us-east-1
output = json

[profile toldev]
region = us-east-1
output = json
```

## Terraform State Backend Credentials

The S3 backend for Terraform state uses a **separate profile** configuration:

### Configuration

- **Profile**: `TFSTATE_PROFILE` (defaults to `toldev`)
- **Region**: `TFSTATE_REGION` (defaults to `us-east-1`)
- **Bucket**: `TFSTATE_BUCKET` (defaults to `backstage-terraform-state`)

### Override Backend Profile

```bash
# Use different profile for state backend
make apply ENV=dev TFSTATE_PROFILE=ti-security
```

This is useful when:
- State bucket is in a different AWS account
- You have a dedicated security account for state storage
- Different teams manage infrastructure vs. state

## Common Scenarios

### Scenario 1: Same Account for Everything

**Configuration:**
- AWS Profile: `default`
- State Profile: `default` (automatic)

**Usage:**
```bash
aws configure  # Configure default profile
make apply ENV=dev
```

### Scenario 2: Different Accounts (Like Your marketplace-web Setup)

**Configuration:**
- AWS Profile: `toldev` (for deploying resources)
- State Profile: `ti-security` (for state storage)

**Usage:**
```bash
# Configure both profiles
aws configure --profile toldev
aws configure --profile ti-security

# Deploy
make apply ENV=dev AWS_PROFILE=toldev TFSTATE_PROFILE=ti-security
```

Or set in Makefile:
```makefile
AWS_PROFILE ?= toldev
TFSTATE_PROFILE ?= ti-security
```

### Scenario 3: GitHub Actions with OIDC

**Setup:**
1. Create OIDC provider in AWS
2. Create IAM role: `github-actions-terraform`
3. Add role ARN to GitHub secrets
4. Push code to main branch
5. GitHub Actions automatically deploys

**No local credentials needed** for automated deployment!

### Scenario 4: Multiple Environments

**Development:**
```bash
make apply ENV=dev AWS_PROFILE=dev-profile
```

**Staging:**
```bash
make apply ENV=stage AWS_PROFILE=stage-profile
```

**Production:**
```bash
make apply ENV=prod AWS_PROFILE=prod-profile
```

## Troubleshooting

### Error: "Unable to locate credentials"

**Solution:**
```bash
# Check if profile exists
aws configure list-profiles

# Configure the profile
aws configure --profile toldev

# Or use environment variables
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
```

### Error: "Access Denied" for S3 Backend

**Solution:**
```bash
# Check state profile has S3 permissions
aws s3 ls s3://backstage-terraform-state --profile toldev

# Verify DynamoDB access
aws dynamodb describe-table \
  --table-name backstage-terraform-locks \
  --profile toldev
```

### Error: "Profile not found" in GitHub Actions

**Cause:** GitHub Actions doesn't use profiles, it uses secrets.

**Solution:** Configure GitHub secrets instead:
- Go to repository Settings → Secrets and variables → Actions
- Add `AWS_ROLE_ARN` or access key secrets

### Different Profiles for Different Regions

```bash
# Profile for us-east-1
[profile us-east-1-profile]
region = us-east-1

# Profile for us-west-2
[profile us-west-2-profile]
region = us-west-2
```

## Security Best Practices

1. **Use OIDC for GitHub Actions** - No long-lived credentials
2. **Rotate access keys regularly** - Every 90 days
3. **Use separate accounts** - Dev/Stage/Prod isolation
4. **Least privilege IAM policies** - Only required permissions
5. **Enable MFA** - For production accounts
6. **Use AWS Organizations** - Centralized management
7. **Audit with CloudTrail** - Track all API calls

## Quick Reference

| Deployment Method | Credential Type | Configuration Location |
|-------------------|-----------------|------------------------|
| GitHub Actions (OIDC) | IAM Role | GitHub Secrets: `AWS_ROLE_ARN` |
| GitHub Actions (Keys) | Access Keys | GitHub Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| Local (Makefile) | AWS Profile | `~/.aws/credentials` + `~/.aws/config` |
| Local (Env Vars) | Environment Variables | `export AWS_ACCESS_KEY_ID=...` |
| Terraform State | AWS Profile | Makefile: `TFSTATE_PROFILE` |

## Example: Complete Setup

### 1. Configure AWS Profiles

```bash
# Main deployment profile
aws configure --profile toldev
# Enter your credentials for deploying ECS clusters

# State backend profile (if different)
aws configure --profile ti-security
# Enter credentials for accessing state bucket
```

### 2. Create State Backend

```bash
export AWS_PROFILE=toldev
make create-backend
```

### 3. Deploy Locally

```bash
make init
make plan ENV=dev
make apply ENV=dev
```

### 4. Setup GitHub Actions (Optional)

```bash
# Create OIDC provider and role (one-time)
# Then add to GitHub secrets:
# AWS_ROLE_ARN = arn:aws:iam::123456789012:role/github-actions-terraform

# Push to trigger deployment
git push origin main
```

## Support

For issues with:
- **AWS Profiles**: Run `aws configure help`
- **GitHub Actions**: Check workflow logs in Actions tab
- **Terraform**: See `README.md` and `DEPLOYMENT.md`
