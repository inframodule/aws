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

module "alb" {
  source = "../.."

  name                  = var.name
  vpc_id                = var.vpc_id
  subnet_ids            = var.public_subnet_ids
  internal              = false
  allow_internet_facing = true
  certificate_arn       = var.certificate_arn

  ingress_ipv4_cidrs               = var.allowed_ipv4_cidrs
  egress_target_security_group_ids = [var.target_security_group_id]

  target_port = var.target_port
  targets = {
    for id in var.target_instance_ids : id => {
      id = id
    }
  }

  health_check = {
    path = var.health_check_path
  }

  web_acl_arn = var.web_acl_arn
  access_logs = var.access_log_bucket == null ? null : {
    bucket = var.access_log_bucket
    prefix = "alb/${var.name}"
  }

  tags = var.tags
}
