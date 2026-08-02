output "bucket_id" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Region-specific bucket domain name."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the bucket region."
  value       = aws_s3_bucket.this.hosted_zone_id
}

output "region" {
  description = "AWS region containing the bucket."
  value       = aws_s3_bucket.this.region
}

output "versioning_enabled" {
  description = "Whether object versioning is enabled."
  value       = var.versioning_enabled
}

output "sse_algorithm" {
  description = "Configured default server-side encryption algorithm."
  value       = var.sse_algorithm
}

output "kms_key_arn" {
  description = "Configured KMS key ARN, or null when not supplied."
  value       = var.kms_key_arn
}

output "object_lock_enabled" {
  description = "Whether Object Lock is enabled."
  value       = var.object_lock_enabled
}
