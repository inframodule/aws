locals {
  managed_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : []
  effective_security_group_ids = concat(
    local.managed_security_group_ids,
    tolist(var.security_group_ids)
  )

  effective_health_check_type = coalesce(
    var.health_check_type,
    length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  )

  effective_instance_refresh_warmup = coalesce(
    try(var.instance_refresh.instance_warmup, null),
    var.default_instance_warmup
  )

  instance_tags = merge(var.tags, {
    Name          = var.name
    Module        = "autoscaling"
    ModuleVersion = "1.0.0"
  })

  common_tags = merge(var.tags, {
    Module        = "autoscaling"
    ModuleVersion = "1.0.0"
  })
}

check "capacity_bounds" {
  assert {
    condition = (
      var.min_size <= var.desired_capacity &&
      var.desired_capacity <= var.max_size
    )
    error_message = "Capacity must satisfy min_size <= desired_capacity <= max_size."
  }
}

check "security_group_configuration" {
  assert {
    condition = var.create_security_group ? (
      var.vpc_id != null &&
      length(var.ingress_ipv4_cidrs) + length(var.ingress_ipv6_cidrs) + length(var.ingress_source_security_group_ids) > 0 &&
      length(var.egress_ipv4_cidrs) + length(var.egress_ipv6_cidrs) + length(var.egress_destination_security_group_ids) > 0
    ) : length(var.security_group_ids) > 0
    error_message = "A managed security group requires vpc_id plus ingress and egress destinations; otherwise security_group_ids must be supplied."
  }
}

check "egress_port_range" {
  assert {
    condition     = var.egress_from_port <= var.egress_to_port
    error_message = "egress_from_port must be less than or equal to egress_to_port."
  }
}

check "public_ip_guardrail" {
  assert {
    condition     = !var.associate_public_ip_address || var.allow_public_ip
    error_message = "allow_public_ip must be true before public IPv4 assignment is enabled."
  }
}

check "volume_encryption" {
  assert {
    condition = (
      (!var.require_volume_encryption || var.root_block_device.encrypted) &&
      (!var.require_volume_encryption || alltrue([for device in var.ebs_block_devices : device.encrypted])) &&
      (var.kms_key_id == null || var.root_block_device.encrypted) &&
      (var.kms_key_id == null || alltrue([for device in var.ebs_block_devices : device.encrypted]))
    )
    error_message = "All EBS volumes must be encrypted when require_volume_encryption is true or kms_key_id is supplied."
  }
}

check "request_count_scaling" {
  assert {
    condition = var.alb_request_count_target_value == null || (
      var.alb_resource_label != null &&
      length(trimspace(var.alb_resource_label)) > 0
    )
    error_message = "alb_resource_label is required when ALB request-count target tracking is enabled."
  }
}
