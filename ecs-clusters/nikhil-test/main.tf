terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      CreatedBy   = "Backstage"
      Environment = var.environment
      Cluster     = var.cluster_name
    }
  }
}

# Data source to get the service-linked role ARN
data "aws_iam_role" "autoscaling_service_linked_role" {
  name = "AWSServiceRoleForAutoScaling"
}

# ECS Cluster Module
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  cluster_name               = var.cluster_name
  vpc_id                     = var.vpc_id
  region                     = var.aws_region
  environment                = var.environment
  on_demand_instance_type    = var.on_demand_instance_type
  service_linked_role        = data.aws_iam_role.autoscaling_service_linked_role.arn
  cluster_security_group_id  = var.cluster_security_group_id
  
  # Capacity configuration
  on_demand_min_size         = var.on_demand_min_size
  on_demand_max_size         = var.on_demand_max_size
  on_demand_desired_capacity = var.on_demand_desired_capacity
  
  # Container Insights
  containerInsights = var.enable_container_insights ? "enabled" : "disabled"
  
  # CloudWatch logs retention
  log_retention_period = 14
  
  # Scaling configuration
  minimum_scaling_step_size = 1
  maximum_scaling_step_size = 20
  target_capacity          = 100
  
  tags = {
    Name = var.cluster_name
  }
}
