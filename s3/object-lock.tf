resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.object_lock_default_retention == null ? 0 : 1

  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode  = var.object_lock_default_retention.mode
      days  = try(var.object_lock_default_retention.days, null)
      years = try(var.object_lock_default_retention.years, null)
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}
