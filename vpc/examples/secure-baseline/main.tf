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

module "vpc" {
  source = "../.."

  name               = var.name
  vpc_cidr           = "10.10.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]

  private_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
  isolated_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

  create_internet_gateway = false
  nat_gateway_mode        = "none"
  enable_flow_logs        = true
  gateway_endpoints       = ["s3"]
  flow_log_kms_key_id     = var.flow_log_kms_key_id

  tags = var.tags
}
