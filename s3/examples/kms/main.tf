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
  region = var.aws_region
}

module "bucket" {
  source = "../.."

  bucket_name        = var.bucket_name
  sse_algorithm      = "aws:kms"
  kms_key_arn        = var.kms_key_arn
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

  tags = var.tags
}
