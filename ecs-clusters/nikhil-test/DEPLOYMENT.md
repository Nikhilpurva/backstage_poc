# Deployment Instructions

## Quick Start

This repository contains Terraform configuration to deploy an ECS cluster using pre-built modules.

### Prerequisites Checklist

- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Access to AWS account with required permissions
- [ ] VPC ID: `vpc-07a2436391cb04af5`
- [ ] Security Group ID: `sg-0e3a8301268c0514f`
- [ ] Private subnets exist in VPC (tagged with `Name = "*-priv*"`)
- [ ] Service-linked role `AWSServiceRoleForAutoScaling` exists

### Step 1: Setup Modules

The Terraform configuration references modules at `../../modules/ecs-cluster`. You have two options:

#### Option A: Copy Modules (Recommended for standalone repos)

Copy the modules directory from the main Backstage repository:

```bash
# From the Backstage repository root
cp -r modules ./path/to/this/repo/
```

Your directory structure should look like:
```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   └── ecs-cluster/
│       ├── main.tf
│       ├── variables.tf
│       ├── output.tf
│       └── user-data.sh
└── README.md
```

Then update `main.tf` to use local path:
```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"
  # ... rest of configuration
}
```

#### Option B: Git Submodule (For version control)

If modules are in a separate Git repository:

```bash
git submodule add <modules-repo-url> modules
git submodule update --init --recursive
```

### Step 2: Configure AWS Credentials

```bash
# Option 1: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 2: AWS CLI profile
aws configure --profile ecs-deployment
export AWS_PROFILE=ecs-deployment
```

### Step 3: Verify Prerequisites

```bash
# Check VPC exists
aws ec2 describe-vpcs --vpc-ids vpc-07a2436391cb04af5

# Check security group exists
aws ec2 describe-security-groups --group-ids sg-0e3a8301268c0514f

# Check for private subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-07a2436391cb04af5" "Name=tag:Name,Values=*-priv*"

# Check service-linked role (create if missing)
aws iam get-role --role-name AWSServiceRoleForAutoScaling || \
  aws iam create-service-linked-role --aws-service-name autoscaling.amazonaws.com
```

### Step 4: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 5: Review the Plan

```bash
terraform plan
```

Review the resources that will be created:
- ECS Cluster
- Auto Scaling Group
- Launch Template
- IAM Roles and Policies
- CloudWatch Log Group
- Capacity Provider

### Step 6: Deploy

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes approximately 5-10 minutes.

### Step 7: Verify Deployment

```bash
# Get cluster details
terraform output

# Check cluster status
aws ecs describe-clusters \
  --clusters nikhil-test \
  --region us-east-1

# List container instances
aws ecs list-container-instances \
  --cluster nikhil-test \
  --region us-east-1

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'nikhil-test')]"
```

## Configuration Details

### Current Configuration

```
Cluster Name:        nikhil-test
Region:              us-east-1
Environment:         dev
Instance Type:       t3.medium
Min Instances:       1
Max Instances:       10
Desired Instances:   1
Container Insights:  true
VPC ID:              vpc-07a2436391cb04af5
Security Group:      sg-0e3a8301268c0514f
```

### Modifying Configuration

To change cluster capacity after deployment:

```bash
# Edit variables.tf or create terraform.tfvars
cat > terraform.tfvars <<EOF
on_demand_min_size = 2
on_demand_max_size = 20
on_demand_desired_capacity = 5
EOF

# Apply changes
terraform apply
```

## Deploying Services

Once the cluster is running, deploy ECS services:

### Example Service Configuration

Create a new file `service.tf`:

```hcl
module "my_service" {
  source = "./modules/ecs-service"
  
  # Cluster configuration
  cluster_name           = module.ecs_cluster.cluster_name
  cluster_id             = module.ecs_cluster.cluster_id
  capacity_provider_name = module.ecs_cluster.capacity_provider_name
  
  # Service configuration
  service_name       = "my-application"
  vpc_id             = var.vpc_id
  environment        = var.environment
  container_port     = 8080
  
  # Task configuration
  task_definition_arn = aws_ecs_task_definition.my_app.arn
  desired_ecs_task    = "2"
  min_ecs_task        = "2"
  max_ecs_task        = 10
  
  # Networking
  private_subnet          = data.aws_subnets.private.ids
  nlb_security_group_id   = var.nlb_security_group_id
  
  # Scaling
  scaling_policy_cpu_target_value = 70
}
```

## Monitoring

### CloudWatch Logs

View cluster logs:
```bash
aws logs tail /ecs/nikhil-test-cluster-logs --follow
```

### Container Insights


Container Insights is enabled. View metrics in CloudWatch:
1. Go to CloudWatch Console
2. Navigate to Container Insights
3. Select cluster: `nikhil-test`


### Metrics to Monitor

- CPU Utilization
- Memory Utilization
- Running Tasks Count
- Pending Tasks Count
- Container Instance Count

## Scaling

The cluster uses ECS Capacity Providers for automatic scaling:

- **Target Capacity**: 100%
- **Min Step Size**: 1 instance
- **Max Step Size**: 20 instances

Scaling is triggered based on:
- Task placement requirements
- Resource availability (CPU/Memory)

## Troubleshooting

### Issue: No Container Instances

**Symptoms**: Cluster created but no EC2 instances appear

**Solutions**:
1. Check Auto Scaling Group:
   ```bash
   aws autoscaling describe-auto-scaling-groups \
     --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'nikhil-test')]"
   ```

2. Check Launch Template:
   ```bash
   aws ec2 describe-launch-templates \
     --filters "Name=tag:Name,Values=nikhil-test*"
   ```

3. Review CloudWatch logs for errors

### Issue: Tasks Not Starting

**Symptoms**: Tasks remain in PENDING state

**Solutions**:
1. Check resource availability:
   ```bash
   aws ecs describe-clusters --clusters nikhil-test \
     --include STATISTICS
   ```

2. Verify task definition resource requirements
3. Check IAM permissions for task execution role

### Issue: Terraform Module Not Found

**Error**: `Module not installed`

**Solution**: Ensure modules are available (see Step 1)

### Issue: Insufficient Permissions

**Error**: `UnauthorizedOperation` or `AccessDenied`

**Solution**: Verify IAM permissions include:
- `ecs:*`
- `ec2:*` (for ASG, Launch Templates)
- `autoscaling:*`
- `iam:PassRole`, `iam:CreateRole`, etc.
- `logs:*`

## Cleanup

To destroy all resources:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy
```

Type `yes` when prompted.

**Warning**: This permanently deletes:
- ECS Cluster
- Auto Scaling Group
- EC2 Instances
- CloudWatch Log Groups
- IAM Roles (if not used elsewhere)

## Cost Estimation

Approximate monthly costs for dev environment:

**EC2 Instances** (t3.medium):
- Running 1 instances 24/7
- Estimate: Check AWS Pricing Calculator

**Data Transfer**:
- Varies based on usage

**CloudWatch Logs**:
- Log ingestion and storage
- Estimate: $0.50-$5/month depending on volume


**Container Insights**:
- Additional CloudWatch metrics
- Estimate: $1-$10/month


Use [AWS Pricing Calculator](https://calculator.aws/) for accurate estimates.

## Support

- **Module Documentation**: See `modules/ecs-cluster/README.md`
- **AWS ECS Docs**: https://docs.aws.amazon.com/ecs/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/

## Next Steps

1. ✅ Deploy the cluster
2. ⬜ Create task definitions
3. ⬜ Deploy services using `ecs-service` module
4. ⬜ Configure load balancers
5. ⬜ Set up CI/CD pipelines
6. ⬜ Configure monitoring and alerts
