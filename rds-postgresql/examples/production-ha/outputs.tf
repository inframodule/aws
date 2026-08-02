output "endpoint" {
  value = module.postgresql.endpoint
}

output "master_user_secret_arn" {
  value = module.postgresql.master_user_secret_arn
}

output "resource_id" {
  value = module.postgresql.resource_id
}
