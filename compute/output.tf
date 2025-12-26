output "instance_ids" {
  description = "IDs of the created instances."
  value       = [for instance in aws_instance.this : instance.id]
}

output "instance_arns" {
  description = "ARNs of the created instances."
  value       = [for instance in aws_instance.this : instance.arn]
}

output "private_ips" {
  description = "Private IPs of the created instances."
  value       = [for instance in aws_instance.this : instance.private_ip]
}

output "public_ips" {
  description = "Public IPs of the created instances, if assigned."
  value       = [for instance in aws_instance.this : instance.public_ip]
}

output "security_group_id" {
  description = "ID of the security group created by this module (if enabled)."
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "public_dns" {
  description = "Public DNS names of the created instances, if assigned."
  value       = [for instance in aws_instance.this : instance.public_dns]
}

output "private_dns" {
  description = "Private DNS names of the created instances."
  value       = [for instance in aws_instance.this : instance.private_dns]
}

output "primary_network_interface_id" {
  description = "Primary network interface IDs for the created instances."
  value       = [for instance in aws_instance.this : instance.primary_network_interface_id]
}
