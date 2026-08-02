locals {
  effective_bucket_key_enabled = var.sse_algorithm == "aws:kms" ? var.bucket_key_enabled : false

  common_tags = merge(var.tags, {
    Module        = "s3"
    ModuleVersion = "1.0.0"
  })
}

check "bucket_naming" {
  assert {
    condition     = (var.bucket_name == null) != (var.bucket_prefix == null)
    error_message = "Exactly one of bucket_name or bucket_prefix must be supplied."
  }
}

check "kms_configuration" {
  assert {
    condition     = var.kms_key_arn == null || contains(["aws:kms", "aws:kms:dsse"], var.sse_algorithm)
    error_message = "kms_key_arn can be supplied only with aws:kms or aws:kms:dsse encryption."
  }
}

check "object_lock_configuration" {
  assert {
    condition = (
      (!var.object_lock_enabled || var.versioning_enabled) &&
      (var.object_lock_default_retention == null || var.object_lock_enabled)
    )
    error_message = "Object Lock requires versioning, and default retention requires object_lock_enabled."
  }
}

check "noncurrent_lifecycle_requires_versioning" {
  assert {
    condition = var.versioning_enabled || alltrue([
      for rule in var.lifecycle_rules : (
        try(rule.noncurrent_version_expiration_days, null) == null &&
        length(rule.noncurrent_version_transitions) == 0
      )
    ])
    error_message = "Noncurrent-version lifecycle settings require versioning_enabled."
  }
}
