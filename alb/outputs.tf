output "load_balancer_id" {
  description = "ID of the Application Load Balancer."
  value       = aws_lb.this.id
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "load_balancer_arn_suffix" {
  description = "ARN suffix used by CloudWatch metrics."
  value       = aws_lb.this.arn_suffix
}

output "dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer."
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ID of the managed security group, or null when disabled."
  value       = try(aws_security_group.this[0].id, null)
}

output "security_group_ids" {
  description = "All security group IDs associated with the load balancer."
  value       = local.effective_security_group_ids
}

output "target_group_arn" {
  description = "ARN of the target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix used by CloudWatch metrics."
  value       = aws_lb_target_group.this.arn_suffix
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener."
  value       = aws_lb_listener.https.arn
}

output "http_redirect_listener_arn" {
  description = "ARN of the HTTP redirect listener, or null when disabled."
  value       = try(aws_lb_listener.http_redirect[0].arn, null)
}
