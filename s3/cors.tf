resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      id              = try(cors_rule.value.id, null)
      allowed_headers = sort(tolist(cors_rule.value.allowed_headers))
      allowed_methods = sort(tolist(cors_rule.value.allowed_methods))
      allowed_origins = sort(tolist(cors_rule.value.allowed_origins))
      expose_headers  = sort(tolist(cors_rule.value.expose_headers))
      max_age_seconds = try(cors_rule.value.max_age_seconds, null)
    }
  }
}
