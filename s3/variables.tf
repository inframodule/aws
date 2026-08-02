variable "bucket_name" {
  description = "Globally unique bucket name. Exactly one of bucket_name or bucket_prefix must be supplied."
  type        = string
  default     = null

  validation {
    condition = var.bucket_name == null || (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name)) &&
      !strcontains(var.bucket_name, "..") &&
      !strcontains(var.bucket_name, ".-") &&
      !strcontains(var.bucket_name, "-.") &&
      !can(regex("^[0-9]{1,3}(?:\\.[0-9]{1,3}){3}$", var.bucket_name)) &&
      !startswith(var.bucket_name, "xn--") &&
      !startswith(var.bucket_name, "sthree-") &&
      !startswith(var.bucket_name, "amzn-s3-demo-") &&
      !endswith(var.bucket_name, "-s3alias") &&
      !endswith(var.bucket_name, "--ol-s3") &&
      !endswith(var.bucket_name, ".mrap") &&
      !endswith(var.bucket_name, "--x-s3") &&
      !endswith(var.bucket_name, "--table-s3")
    )
    error_message = "bucket_name must be a valid 3-63 character S3 bucket name and cannot be formatted as an IPv4 address."
  }
}

variable "bucket_prefix" {
  description = "Prefix from which AWS generates a globally unique bucket name. Exactly one of bucket_name or bucket_prefix must be supplied."
  type        = string
  default     = null

  validation {
    condition = var.bucket_prefix == null || (
      length(var.bucket_prefix) >= 1 &&
      length(var.bucket_prefix) <= 37 &&
      can(regex("^[a-z0-9][a-z0-9.-]*$", var.bucket_prefix)) &&
      !strcontains(var.bucket_prefix, "..") &&
      !strcontains(var.bucket_prefix, ".-") &&
      !strcontains(var.bucket_prefix, "-.") &&
      !startswith(var.bucket_prefix, "xn--") &&
      !startswith(var.bucket_prefix, "sthree-") &&
      !startswith(var.bucket_prefix, "amzn-s3-demo-")
    )
    error_message = "bucket_prefix must be 1-37 lowercase letters, numbers, periods, or hyphens and must begin with a letter or number."
  }
}

variable "force_destroy" {
  description = "Whether Terraform may delete a non-empty bucket."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether S3 object versioning is enabled."
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Default server-side encryption algorithm."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms", "aws:kms:dsse"], var.sse_algorithm)
    error_message = "sse_algorithm must be AES256, aws:kms, or aws:kms:dsse."
  }
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for SSE-KMS or DSSE-KMS encryption."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+$", var.kms_key_arn))
    error_message = "kms_key_arn must be null or a valid KMS key ARN."
  }
}

variable "bucket_key_enabled" {
  description = "Whether to use an S3 Bucket Key with SSE-KMS. Ignored for other encryption algorithms."
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version enforced by the bucket policy."
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.2", "1.3"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be 1.2 or 1.3."
  }
}

variable "additional_policy_documents" {
  description = "Additional IAM policy documents merged into the module-managed bucket policy."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for document in var.additional_policy_documents : can(jsondecode(document))])
    error_message = "Every additional_policy_documents entry must contain valid JSON."
  }
}

variable "lifecycle_rules" {
  description = "Bucket lifecycle rules. No object expiration is configured by default."
  type = list(object({
    id                                     = string
    enabled                                = optional(bool, true)
    prefix                                 = optional(string, "")
    expiration_days                        = optional(number)
    expired_object_delete_marker           = optional(bool)
    noncurrent_version_expiration_days     = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_version_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })), [])
  }))
  default = []

  validation {
    condition = (
      length(var.lifecycle_rules) == length(distinct([for rule in var.lifecycle_rules : rule.id])) &&
      alltrue([for rule in var.lifecycle_rules : (
        length(trimspace(rule.id)) > 0 &&
        !(try(rule.expiration_days, null) != null && try(rule.expired_object_delete_marker, false)) &&
        coalesce(try(rule.expiration_days, null), 1) > 0 &&
        coalesce(try(rule.noncurrent_version_expiration_days, null), 1) > 0 &&
        coalesce(try(rule.abort_incomplete_multipart_upload_days, null), 1) > 0 &&
        alltrue([for transition in rule.transitions : transition.days >= 0]) &&
        alltrue([for transition in rule.noncurrent_version_transitions : transition.noncurrent_days > 0])
      )])
    )
    error_message = "Lifecycle rule IDs must be unique and non-empty; expiration settings cannot conflict and all day counts must be valid."
  }
}

variable "cors_rules" {
  description = "CORS rules for browser-based access. No CORS configuration is created by default."
  type = list(object({
    id              = optional(string)
    allowed_headers = optional(set(string), [])
    allowed_methods = set(string)
    allowed_origins = set(string)
    expose_headers  = optional(set(string), [])
    max_age_seconds = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([for rule in var.cors_rules : (
      length(rule.allowed_methods) > 0 &&
      length(rule.allowed_origins) > 0 &&
      alltrue([for method in rule.allowed_methods : contains(["GET", "PUT", "POST", "DELETE", "HEAD"], method)]) &&
      coalesce(try(rule.max_age_seconds, null), 0) >= 0
    )])
    error_message = "Each CORS rule requires valid methods, at least one origin, and a non-negative max_age_seconds."
  }
}

variable "logging" {
  description = "Optional server-access logging configuration. The destination bucket must already exist."
  type = object({
    target_bucket = string
    target_prefix = optional(string, "")
  })
  default = null

  validation {
    condition     = var.logging == null || length(trimspace(var.logging.target_bucket)) > 0
    error_message = "logging.target_bucket must be non-empty when logging is configured."
  }
}

variable "object_lock_enabled" {
  description = "Whether Object Lock is enabled when the bucket is created. This cannot be disabled later."
  type        = bool
  default     = false
}

variable "object_lock_default_retention" {
  description = "Optional default Object Lock retention. Requires object_lock_enabled."
  type = object({
    mode  = string
    days  = optional(number)
    years = optional(number)
  })
  default = null

  validation {
    condition = var.object_lock_default_retention == null || (
      contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_default_retention.mode) &&
      ((try(var.object_lock_default_retention.days, null) != null) != (try(var.object_lock_default_retention.years, null) != null)) &&
      coalesce(try(var.object_lock_default_retention.days, null), 1) > 0 &&
      coalesce(try(var.object_lock_default_retention.years, null), 1) > 0
    )
    error_message = "Object Lock retention requires GOVERNANCE or COMPLIANCE mode and exactly one positive days or years value."
  }
}

variable "tags" {
  description = "Additional tags to apply to module resources."
  type        = map(string)
  default     = {}
}
