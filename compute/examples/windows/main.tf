terraform {
  required_version = ">= 1.5.0"

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

module "compute" {
  source = "../.."

  name_prefix                      = var.name_prefix
  instance_count                   = var.instance_count
  ami_id                           = var.ami_id
  instance_type                    = var.instance_type
  subnet_ids                       = var.subnet_ids
  vpc_id                           = var.vpc_id
  allowed_cidr_blocks              = var.allowed_cidr_blocks
  associate_public_ip_address      = var.associate_public_ip_address
  allow_public_ip                  = var.allow_public_ip
  imds_http_tokens                 = var.imds_http_tokens
  imds_http_endpoint               = var.imds_http_endpoint
  imds_http_put_response_hop_limit = var.imds_http_put_response_hop_limit
  imds_instance_metadata_tags      = var.imds_instance_metadata_tags
  imds_http_protocol_ipv6          = var.imds_http_protocol_ipv6
  root_block_device                = var.root_block_device
  ebs_block_device                 = var.ebs_block_device
  require_volume_encryption        = var.require_volume_encryption
  kms_key_id                       = var.kms_key_id
  enable_ssh                       = var.enable_ssh
  enable_rdp                       = var.enable_rdp
  ssh_allowed_cidr_blocks          = var.ssh_allowed_cidr_blocks
  rdp_allowed_cidr_blocks          = var.rdp_allowed_cidr_blocks
  tags                             = var.tags
}
