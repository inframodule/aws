resource "aws_s3_bucket_logging" "this" {
  count = var.logging == null ? 0 : 1

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logging.target_bucket
  target_prefix = var.logging.target_prefix

  depends_on = [aws_s3_bucket_ownership_controls.this]
}
