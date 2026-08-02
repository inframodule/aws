output "bucket_id" {
  description = "Name of the KMS-encrypted bucket."
  value       = module.bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the KMS-encrypted bucket."
  value       = module.bucket.bucket_arn
}
