output "autoscaling_group_id" {
  description = "Auto Scaling group ID."
  value       = aws_autoscaling_group.this.id
}

output "autoscaling_group_name" {
  description = "Auto Scaling group name."
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling group ARN."
  value       = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  description = "Launch template ID."
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "Launch template ARN."
  value       = aws_launch_template.this.arn
}

output "launch_template_latest_version" {
  description = "Latest launch template version used by the group."
  value       = aws_launch_template.this.latest_version
}

output "security_group_id" {
  description = "Managed instance security group ID, or null when disabled."
  value       = try(aws_security_group.this[0].id, null)
}

output "security_group_ids" {
  description = "All security group IDs attached to group instances."
  value       = local.effective_security_group_ids
}

output "cpu_scaling_policy_arn" {
  description = "CPU target-tracking policy ARN, or null when disabled."
  value       = try(aws_autoscaling_policy.cpu[0].arn, null)
}

output "alb_request_count_scaling_policy_arn" {
  description = "ALB request-count target-tracking policy ARN, or null when disabled."
  value       = try(aws_autoscaling_policy.alb_request_count[0].arn, null)
}
