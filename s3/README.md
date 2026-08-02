# AWS Secure S3 Bucket Module

Version: **1.0.0**

Terraform module for private, versioned Amazon S3 buckets with explicit encryption, transport-security policies, lifecycle controls, optional Object Lock, CORS, server-access logging, and composable bucket policies.

## Security defaults

- Enables all four S3 Block Public Access settings without an opt-out.
- Uses `BucketOwnerEnforced` ownership and disables ACLs.
- Enables object versioning.
- Configures explicit SSE-S3 encryption.
- Denies non-TLS requests and TLS versions below 1.2 for non-service principals.
- Prevents Terraform from deleting non-empty buckets.
- Creates no public website configuration.
- Adds no automatic object expiration or destructive lifecycle rules.

AWS recommends blocking public access, disabling ACLs for modern workloads, and retaining server-side encryption. See the [Amazon S3 security best practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html).

## Basic usage

The following complete configuration creates a private, versioned, SSE-S3 encrypted bucket. The lifecycle rule only cleans up abandoned multipart uploads; it does not expire objects.

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "bucket" {
  source = "git::https://github.com/inframodule/aws.git//s3?ref=s3-v1.0.0"

  bucket_name = "replace-with-a-globally-unique-name"

  lifecycle_rules = [{
    id                                     = "abort-incomplete-uploads"
    abort_incomplete_multipart_upload_days = 7
  }]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

output "bucket_arn" {
  value = module.bucket.bucket_arn
}
```

Run it with:

```shell
terraform init
terraform plan
terraform apply
```

## KMS-encrypted bucket

Use a customer-managed key when the workload needs independent key policy, rotation, or audit controls:

```hcl
module "kms_bucket" {
  source = "git::https://github.com/inframodule/aws.git//s3?ref=s3-v1.0.0"

  bucket_name        = "application-data-123456789012"
  sse_algorithm      = "aws:kms"
  kms_key_arn        = aws_kms_key.application.arn
  bucket_key_enabled = true

  lifecycle_rules = [{
    id                                     = "archive-and-retain"
    abort_incomplete_multipart_upload_days = 7
    noncurrent_version_expiration_days     = 365
    transitions = [{
      days          = 90
      storage_class = "GLACIER_IR"
    }]
  }]
}
```

`aws:kms:dsse` is also supported. S3 Bucket Keys are enabled only for `aws:kms`; the module disables them for SSE-S3 and DSSE-KMS.

## ALB access-log bucket

Application Load Balancer access logs require an S3 bucket in the same Region, SSE-S3 encryption, and permission for the ELB log-delivery service. AWS documents SSE-S3 as the only supported encryption option for ALB access logs. See [Enable ALB access logs](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html).

```hcl
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  alb_log_bucket = "alb-logs-123456789012"
  alb_log_prefix = "alb/application"
}

data "aws_iam_policy_document" "alb_log_delivery" {
  statement {
    sid     = "AllowAlbLogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.alb_log_bucket}/${local.alb_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
  }
}

module "alb_logs" {
  source = "git::https://github.com/inframodule/aws.git//s3?ref=s3-v1.0.0"

  bucket_name  = local.alb_log_bucket
  sse_algorithm = "AES256"
  additional_policy_documents = [
    data.aws_iam_policy_document.alb_log_delivery.json
  ]

  lifecycle_rules = [{
    id                                     = "alb-log-retention"
    expiration_days                        = 365
    noncurrent_version_expiration_days     = 30
    abort_incomplete_multipart_upload_days = 7
  }]
}

module "alb" {
  source = "git::https://github.com/inframodule/aws.git//alb?ref=alb-v1.0.0"

  # Other required ALB inputs omitted for brevity.

  access_logs = {
    bucket = module.alb_logs.bucket_id
    prefix = local.alb_log_prefix
  }

  depends_on = [module.alb_logs]
}
```

The account ID in the object path prevents unrelated accounts from using the policy to deliver logs. Do not include `AWSLogs` in the configured ALB prefix; AWS adds that path automatically.

## Object Lock

Object Lock must be enabled when the bucket is created and requires versioning. Compliance retention can prevent object deletion even by the root user until retention expires, so review the retention period carefully.

```hcl
module "records" {
  source = "git::https://github.com/inframodule/aws.git//s3?ref=s3-v1.0.0"

  bucket_prefix      = "compliance-records-"
  object_lock_enabled = true
  object_lock_default_retention = {
    mode  = "COMPLIANCE"
    years = 7
  }
}
```

## Additional policies

The module always owns the bucket policy so it can enforce transport security. Add workload permissions using `additional_policy_documents`; Terraform merges them with the required deny statements. The transport-security statements are applied as final overrides and cannot be replaced by reusing their statement IDs.

```hcl
module "bucket" {
  # Required inputs omitted.

  additional_policy_documents = [
    data.aws_iam_policy_document.application_access.json
  ]
}
```

## Inputs

| Input | Default | Description |
|---|---:|---|
| `bucket_name` | `null` | Globally unique explicit bucket name |
| `bucket_prefix` | `null` | Prefix for an AWS-generated unique name |
| `force_destroy` | `false` | Permits deletion of a non-empty bucket |
| `versioning_enabled` | `true` | Enables object versioning |
| `sse_algorithm` | `AES256` | `AES256`, `aws:kms`, or `aws:kms:dsse` |
| `kms_key_arn` | `null` | Optional customer-managed KMS key ARN |
| `bucket_key_enabled` | `true` | Enables S3 Bucket Keys for SSE-KMS |
| `minimum_tls_version` | `1.2` | Minimum client TLS version |
| `additional_policy_documents` | `[]` | JSON policies merged with transport protections |
| `lifecycle_rules` | `[]` | Object and version transitions, expirations, and multipart cleanup |
| `cors_rules` | `[]` | Browser CORS rules |
| `logging` | `null` | Existing destination for S3 server-access logs |
| `object_lock_enabled` | `false` | Enables Object Lock at bucket creation |
| `object_lock_default_retention` | `null` | Governance or compliance retention settings |
| `tags` | `{}` | Additional resource tags |

Exactly one of `bucket_name` or `bucket_prefix` is required. Lifecycle expiration is never enabled unless explicitly declared.

## Outputs

| Output | Description |
|---|---|
| `bucket_id` | Bucket name |
| `bucket_arn` | Bucket ARN |
| `bucket_domain_name` | Global bucket domain name |
| `bucket_regional_domain_name` | Region-specific bucket domain name |
| `hosted_zone_id` | Route 53 hosted zone ID |
| `region` | Bucket region |
| `versioning_enabled` | Configured versioning status |
| `sse_algorithm` | Configured encryption algorithm |
| `kms_key_arn` | Configured KMS key ARN or `null` |
| `object_lock_enabled` | Configured Object Lock status |

## Examples

- `examples/basic`: private versioned SSE-S3 bucket.
- `examples/kms`: customer-managed KMS encryption and archival lifecycle.
- `examples/alb-access-logs`: ALB log-delivery policy and integration with the ALB module.

## Testing

```shell
terraform fmt -check -recursive
terraform -chdir=s3 init -backend=false
terraform -chdir=s3 validate
terraform -chdir=s3 test
```

The native tests use a mocked AWS provider and create no infrastructure.

## Versioning

The module version is recorded in `VERSION` and resource tags. Release it with a scoped Git tag such as `s3-v1.0.0`, then reference that immutable tag from callers.
