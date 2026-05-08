variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "nikhil-test"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment type (prod/stage/dev)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
  default     = "vpc-123456"
}

variable "cluster_security_group_id" {
  description = "Security group ID for ECS cluster instances"
  type        = string
  default     = "sg-1234546"
}

variable "on_demand_instance_type" {
  description = "Instance type for ECS cluster EC2 instances"
  type        = string
  default     = "t3.medium"
}

variable "on_demand_min_size" {
  description = "Minimum number of EC2 instances in the cluster"
  type        = number
  default     = 1
}

variable "on_demand_max_size" {
  description = "Maximum number of EC2 instances in the cluster"
  type        = number
  default     = 10
}

variable "on_demand_desired_capacity" {
  description = "Desired number of EC2 instances in the cluster"
  type        = number
  default     = 1
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}
