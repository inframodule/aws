locals {
  selected_subnets = [
    for index in range(var.instance_count) :
    element(var.subnet_ids, index % length(var.subnet_ids))
  ]
  effective_security_group_ids = concat(
    var.security_group_ids,
    var.create_security_group ? [aws_security_group.this[0].id] : []
  )
  ssh_cidr_blocks = var.ssh_allowed_cidr_blocks != null ? var.ssh_allowed_cidr_blocks : var.allowed_cidr_blocks
  rdp_cidr_blocks = var.rdp_allowed_cidr_blocks != null ? var.rdp_allowed_cidr_blocks : var.allowed_cidr_blocks
  ingress_rules = concat(
    var.enable_ssh ? [{
      description = "SSH access."
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidrs       = local.ssh_cidr_blocks
    }] : [],
    var.enable_rdp ? [{
      description = "RDP access."
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidrs       = local.rdp_cidr_blocks
    }] : []
  )
}

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name_prefix = var.name_prefix == null ? "ec2-" : "${var.name_prefix}-"
  description = "Security group for EC2 instances."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidrs
    }
  }

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    var.name_prefix == null ? {} : {
      Name = "${var.name_prefix}-sg"
    }
  )
}

resource "aws_instance" "this" {
  count = var.instance_count

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = local.selected_subnets[count.index]
  vpc_security_group_ids      = length(local.effective_security_group_ids) > 0 ? local.effective_security_group_ids : null
  key_name                    = var.key_name
  iam_instance_profile        = var.iam_instance_profile
  user_data                   = var.user_data
  associate_public_ip_address = var.associate_public_ip_address

  metadata_options {
    http_endpoint               = var.imds_http_endpoint
    http_tokens                 = var.imds_http_tokens
    http_put_response_hop_limit = var.imds_http_put_response_hop_limit
    instance_metadata_tags      = var.imds_instance_metadata_tags
    http_protocol_ipv6          = var.imds_http_protocol_ipv6
  }

  dynamic "root_block_device" {
    for_each = var.root_block_device == null ? [] : [var.root_block_device]
    content {
      volume_size           = root_block_device.value.volume_size
      volume_type           = root_block_device.value.volume_type
      encrypted             = root_block_device.value.encrypted
      delete_on_termination = root_block_device.value.delete_on_termination
      iops                  = try(root_block_device.value.iops, null)
      throughput            = try(root_block_device.value.throughput, null)
      kms_key_id            = var.kms_key_id
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.volume_size
      volume_type           = ebs_block_device.value.volume_type
      encrypted             = ebs_block_device.value.encrypted
      delete_on_termination = ebs_block_device.value.delete_on_termination
      iops                  = try(ebs_block_device.value.iops, null)
      throughput            = try(ebs_block_device.value.throughput, null)
      kms_key_id            = var.kms_key_id
    }
  }

  tags = merge(
    var.tags,
    var.name_prefix == null ? {} : {
      Name = format("%s-%02d", var.name_prefix, count.index + 1)
    }
  )
}
