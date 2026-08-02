output "log_bucket_id" {
  description = "Name of the ALB access-log bucket."
  value       = module.log_bucket.bucket_id
}

output "alb_dns_name" {
  description = "DNS name of the example Application Load Balancer."
  value       = module.alb.dns_name
}
