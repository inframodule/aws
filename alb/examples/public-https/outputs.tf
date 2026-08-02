output "dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = module.alb.dns_name
}

output "zone_id" {
  description = "Route 53 alias zone ID."
  value       = module.alb.zone_id
}

output "security_group_id" {
  description = "Managed load balancer security group ID."
  value       = module.alb.security_group_id
}
