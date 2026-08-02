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
  vpc_cidr           = "10.20.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  public_subnet_cidrs   = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs  = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
  isolated_subnet_cidrs = ["10.20.20.0/24", "10.20.21.0/24", "10.20.22.0/24"]

  create_internet_gateway               = true
  nat_gateway_mode                      = "per_az"
  public_subnet_map_public_ip_on_launch = false
  enable_flow_logs                      = true
  gateway_endpoints                     = ["s3", "dynamodb"]
  flow_log_kms_key_id                   = var.flow_log_kms_key_id

  tags = var.tags
}
