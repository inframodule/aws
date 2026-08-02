output "id" {
  description = "RDS DB instance ID."
  value       = aws_db_instance.this.id
}

output "arn" {
  description = "RDS DB instance ARN."
  value       = aws_db_instance.this.arn
}

output "resource_id" {
  description = "RDS resource ID used by monitoring integrations."
  value       = aws_db_instance.this.resource_id
}

output "address" {
  description = "Database hostname."
  value       = aws_db_instance.this.address
}

output "endpoint" {
  description = "Database endpoint including port."
  value       = aws_db_instance.this.endpoint
}

output "port" {
  description = "PostgreSQL port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master credentials."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}

output "security_group_id" {
  description = "Managed database security group ID, or null."
  value       = try(aws_security_group.this[0].id, null)
}

output "db_subnet_group_name" {
  description = "DB subnet group name."
  value       = aws_db_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Effective DB parameter group name."
  value       = local.effective_parameter_group
}
