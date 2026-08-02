mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "secure_defaults" {
  command = plan

  variables {
    bucket_name = "secure-module-test-123456789012"
  }

  assert {
    condition     = !aws_s3_bucket.this.force_destroy
    error_message = "The bucket must not allow force destruction by default."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "All S3 public-access block settings must be enabled."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled with BucketOwnerEnforced ownership."
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Enabled"
    error_message = "Versioning must be enabled by default."
  }

  assert {
    condition = (
      one(aws_s3_bucket_server_side_encryption_configuration.this.rule)
      .apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    )
    error_message = "SSE-S3 must be the default encryption algorithm."
  }

}

run "kms_lifecycle_cors_and_logging" {
  command = plan

  variables {
    bucket_name        = "kms-module-test-123456789012"
    sse_algorithm      = "aws:kms"
    kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/11111111-1111-1111-1111-111111111111"
    bucket_key_enabled = true
    logging = {
      target_bucket = "central-access-logs-123456789012"
      target_prefix = "s3/kms-module-test/"
    }
    cors_rules = [{
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://app.example.com"]
      max_age_seconds = 3600
    }]
    lifecycle_rules = [{
      id                                     = "retention"
      abort_incomplete_multipart_upload_days = 7
      noncurrent_version_expiration_days     = 90
      transitions = [{
        days          = 30
        storage_class = "STANDARD_IA"
      }]
    }]
  }

  assert {
    condition = (
      one(aws_s3_bucket_server_side_encryption_configuration.this.rule)
      .apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms" &&
      one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled
    )
    error_message = "KMS encryption and S3 Bucket Keys must be configured."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this) == 1
    error_message = "A lifecycle configuration must be created when rules are supplied."
  }

  assert {
    condition     = length(aws_s3_bucket_cors_configuration.this) == 1
    error_message = "A CORS configuration must be created when rules are supplied."
  }

  assert {
    condition     = length(aws_s3_bucket_logging.this) == 1
    error_message = "Server-access logging must be configured when requested."
  }
}

run "object_lock" {
  command = plan

  variables {
    bucket_prefix       = "locked-records-"
    sse_algorithm       = "aws:kms:dsse"
    kms_key_arn         = "arn:aws:kms:us-east-1:123456789012:key/22222222-2222-2222-2222-222222222222"
    object_lock_enabled = true
    object_lock_default_retention = {
      mode  = "COMPLIANCE"
      years = 7
    }
  }

  assert {
    condition     = aws_s3_bucket.this.object_lock_enabled
    error_message = "Object Lock must be enabled on the bucket at creation."
  }

  assert {
    condition     = length(aws_s3_bucket_object_lock_configuration.this) == 1
    error_message = "Default Object Lock retention must be configured."
  }

  assert {
    condition     = !one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled
    error_message = "S3 Bucket Keys must be disabled for DSSE-KMS."
  }
}

run "reject_object_lock_without_versioning" {
  command = plan

  variables {
    bucket_name         = "invalid-lock-test-123456789012"
    versioning_enabled  = false
    object_lock_enabled = true
  }

  expect_failures = [check.object_lock_configuration]
}
