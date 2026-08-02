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

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  normalized_log_prefix = trim(var.log_prefix, "/")
  alb_log_path = local.normalized_log_prefix == "" ? (
    "AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ) : (
    "${local.normalized_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
  )
}

data "aws_iam_policy_document" "alb_log_delivery" {
  statement {
    sid     = "AllowAlbLogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.bucket_name}/${local.alb_log_path}"
    ]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
  }
}

module "log_bucket" {
  source = "../.."

  bucket_name   = var.bucket_name
  sse_algorithm = "AES256"
  additional_policy_documents = [
    data.aws_iam_policy_document.alb_log_delivery.json
  ]

  lifecycle_rules = [{
    id                                     = "alb-log-retention"
    expiration_days                        = var.log_retention_days
    noncurrent_version_expiration_days     = 30
    abort_incomplete_multipart_upload_days = 7
  }]

  tags = var.tags
}

module "alb" {
  source = "../../../alb"

  name                  = var.alb_name
  vpc_id                = var.vpc_id
  subnet_ids            = var.public_subnet_ids
  internal              = false
  allow_internet_facing = true
  certificate_arn       = var.certificate_arn

  ingress_ipv4_cidrs               = var.allowed_ipv4_cidrs
  egress_target_security_group_ids = [var.target_security_group_id]
  target_port                      = var.target_port

  access_logs = {
    bucket = module.log_bucket.bucket_id
    prefix = local.normalized_log_prefix
  }

  tags = var.tags

  depends_on = [module.log_bucket]
}
