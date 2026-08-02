output "dns_name" {
  description = "Internal DNS name of the Application Load Balancer."
  value       = module.alb.dns_name
}

output "security_group_id" {
  description = "Managed load balancer security group ID."
  value       = module.alb.security_group_id
}

output "target_group_arn" {
  description = "Target group ARN."
  value       = module.alb.target_group_arn
}
