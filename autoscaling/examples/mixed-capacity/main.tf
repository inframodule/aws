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
  instance_type = "m6i.large"
  subnet_ids    = var.private_subnet_ids

  min_size         = 2
  desired_capacity = 3
  max_size         = 8

  vpc_id                            = var.vpc_id
  application_port                  = var.application_port
  ingress_source_security_group_ids = var.source_security_group_ids
  egress_ipv4_cidrs                 = ["0.0.0.0/0"]
  egress_from_port                  = 443
  egress_to_port                    = 443

  mixed_instances_policy = {
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 25
    spot_allocation_strategy                 = "price-capacity-optimized"
    overrides = [
      { instance_type = "m6i.large" },
      { instance_type = "m6a.large" },
      { instance_type = "m5.large" }
    ]
  }

  capacity_rebalance = true
  cpu_target_value   = 60

  tags = var.tags
}
