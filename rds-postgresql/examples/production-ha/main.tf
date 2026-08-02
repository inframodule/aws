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

module "postgresql" {
  source = "../.."

  identifier     = var.identifier
  vpc_id         = var.vpc_id
  subnet_ids     = var.private_subnet_ids
  database_name  = "application"
  instance_class = "db.r7g.large"
  multi_az       = true

  allowed_security_group_ids = var.application_security_group_ids

  allocated_storage               = 100
  max_allocated_storage           = 500
  backup_retention_period         = 35
  kms_key_id                      = var.database_kms_key_id
  master_user_secret_kms_key_id   = var.secret_kms_key_id
  performance_insights_kms_key_id = var.database_kms_key_id
  cloudwatch_log_kms_key_id       = var.logs_kms_key_arn
  cloudwatch_log_retention_days   = 365

  tags = var.tags
}
