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

module "autoscaling" {
  source = "../.."

  name          = var.name
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_ids    = var.private_subnet_ids

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_id             = var.vpc_id
  application_port   = var.application_port
  ingress_ipv4_cidrs = [var.vpc_cidr]
  egress_ipv4_cidrs  = ["0.0.0.0/0"]
  egress_from_port   = 443
  egress_to_port     = 443

  iam_instance_profile_name = var.iam_instance_profile_name
  user_data                 = var.user_data

  cpu_target_value = 60

  tags = var.tags
}
