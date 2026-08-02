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

  bucket_name = var.bucket_name

  lifecycle_rules = [{
    id                                     = "abort-incomplete-uploads"
    abort_incomplete_multipart_upload_days = 7
  }]

  tags = var.tags
}
