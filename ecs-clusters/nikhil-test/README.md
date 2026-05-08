# nikhil-test - ECS Cluster

Terraform configuration for deploying an AWS ECS cluster using pre-built modules.

## Overview

- **Cluster Name**: `nikhil-test`
- **Region**: `us-east-1`
- **Environment**: `dev`
- **Instance Type**: `t3.medium`
- **Min Size**: 1
- **Max Size**: 10
- **Desired Capacity**: 1
- **Container Insights**: true

## Architecture

This configuration uses the `ecs-cluster` module which creates:

- **ECS Cluster** with EC2 capacity provider
- **Auto Scaling Group** for EC2 instances
- **IAM Roles and Policies** for ECS instances
- **CloudWatch Log Group** for cluster logs
- **Capacity Provider** with managed scaling

## Prerequisites

### 1. AWS Account Setup
- Active AWS account with appropriate permissions
- AWS CLI installed and configured

### 2. Existing Infrastructure
You need the following existing resources:
- **VPC ID**: `vpc-07a2436391cb04af5`
- **Security Group ID**: `sg-0e3a8301268c0514f`
- **Private Subnets**: Tagged with `Name = "*-priv*"` in your VPC
- **Service-Linked Role**: `AWSServiceRoleForAutoScaling` must exist

### 3. Tools
- Terraform >= 1.0
- AWS credentials configured with permissions for:
  - ECS (cluster, capacity providers)
  - EC2 (Auto Scaling Groups, Launch Templates)
  - IAM (roles, policies, instance profiles)
  - CloudWatch Logs

## Deployment Steps

### 1. Clone the Repository
```bash
git clone <repository-url>
cd <repository-name>
```

### 2. Configure AWS Credentials
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

Or use AWS CLI profiles:
```bash
aws configure --profile backstage
export AWS_PROFILE=backstage
```

### 3. Initialize Terraform
```bash
terraform init
```

This will download the required providers and initialize the backend.

### 4. Review the Plan
```bash
terraform plan
```

Review the resources that will be created.

### 5. Apply the Configuration
```bash
terraform apply
```

Type `yes` when prompted to create the resources.

### 6. Verify Deployment
```bash
# Get cluster information
aws ecs describe-clusters --clusters nikhil-test --region us-east-1

# List container instances
aws ecs list-container-instances --cluster nikhil-test --region us-east-1
```

## Outputs

After successful deployment, Terraform will output:

- `cluster_id`: ECS cluster ID
- `cluster_arn`: ECS cluster ARN
- `cluster_name`: ECS cluster name
- `capacity_provider_name`: Name of the capacity provider
- `on_demand_asg_name`: Auto Scaling Group name
- `region`: AWS region
- `environment`: Environment name

View outputs:
```bash
terraform output
```

## Module Configuration

The cluster uses the following module configuration:

- **Source**: `../../modules/ecs-cluster`
- **Instance Type**: t3.medium
- **AMI**: Amazon Linux 2023 ECS Optimized (ARM64)
- **Scaling**: Managed by ECS Capacity Provider
- **Monitoring**: CloudWatch Container Insights enabled

## Customization

### Modify Instance Type
Edit `variables.tf` and change the `on_demand_instance_type` default value.

### Adjust Scaling Parameters
Edit `main.tf` and modify the module parameters:
- `on_demand_min_size`
- `on_demand_max_size`
- `on_demand_desired_capacity`
- `minimum_scaling_step_size`
- `maximum_scaling_step_size`
- `target_capacity`

### Change Log Retention
Edit `main.tf` and modify `log_retention_period` (default: 14 days).

## Deploying Services

Once the cluster is created, you can deploy ECS services using the `ecs-service` module.

Example:
```hcl
module "my_service" {
  source = "../../modules/ecs-service"
  
  cluster_name            = module.ecs_cluster.cluster_name
  cluster_id              = module.ecs_cluster.cluster_id
  capacity_provider_name  = module.ecs_cluster.capacity_provider_name
  service_name            = "my-service"
  # ... other service configuration
}
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Warning**: This will permanently delete the ECS cluster and all associated resources.

## Troubleshooting

### Issue: Service-Linked Role Not Found
**Error**: `Error: no matching IAM Role found`

**Solution**: Create the service-linked role:
```bash
aws iam create-service-linked-role --aws-service-name autoscaling.amazonaws.com
```

### Issue: No Private Subnets Found
**Error**: `Error: no matching subnet found`

**Solution**: Ensure your VPC has subnets tagged with `Name = "*-priv*"`.

### Issue: Security Group Invalid
**Error**: `InvalidGroup.NotFound`

**Solution**: Verify the security group ID exists in the specified VPC:
```bash
aws ec2 describe-security-groups --group-ids sg-0e3a8301268c0514f
```

## Support

For issues or questions:
1. Check the [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
2. Review the module README at `../../modules/ecs-cluster/README.md`
3. Contact your platform team

## References

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [ECS Capacity Providers](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
