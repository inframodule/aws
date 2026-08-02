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

  identifier    = var.identifier
  vpc_id        = var.vpc_id
  subnet_ids    = var.private_subnet_ids
  database_name = "application"

  allowed_security_group_ids = [var.application_security_group_id]

  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  backup_retention_period = 14

  tags = var.tags
}
