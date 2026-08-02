output "autoscaling_group_name" {
  description = "Name of the mixed-capacity Auto Scaling group."
  value       = module.autoscaling.autoscaling_group_name
}

output "launch_template_id" {
  description = "Launch template ID."
  value       = module.autoscaling.launch_template_id
}
