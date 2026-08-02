output "endpoint" {
  value = module.postgresql.endpoint
}

output "master_user_secret_arn" {
  value = module.postgresql.master_user_secret_arn
}

output "security_group_id" {
  value = module.postgresql.security_group_id
}
