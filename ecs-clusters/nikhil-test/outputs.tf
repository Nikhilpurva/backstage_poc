output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.cluster_name
}

output "capacity_provider_name" {
  description = "Name of the capacity provider"
  value       = module.ecs_cluster.capacity_provider_name
}

output "on_demand_asg_name" {
  description = "Name of the on-demand autoscaling group"
  value       = module.ecs_cluster.on_demand_asg_name
}

output "region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
