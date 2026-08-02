output "autoscaling_group_name" {
  description = "Name of the example Auto Scaling group."
  value       = module.autoscaling.autoscaling_group_name
}

output "launch_template_id" {
  description = "Launch template ID."
  value       = module.autoscaling.launch_template_id
}

output "security_group_id" {
  description = "Managed instance security group ID."
  value       = module.autoscaling.security_group_id
}
