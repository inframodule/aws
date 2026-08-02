resource "aws_launch_template" "this" {
  name_prefix            = "${substr(var.name, 0, 64)}-"
  description            = "Launch template for ${var.name} Auto Scaling group."
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = var.user_data == null ? null : base64encode(var.user_data)
  ebs_optimized          = var.ebs_optimized
  update_default_version = true

  instance_initiated_shutdown_behavior = "terminate"

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name == null ? [] : [var.iam_instance_profile_name]
    content {
      name = iam_instance_profile.value
    }
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  metadata_options {
    http_endpoint               = var.imds_http_endpoint
    http_tokens                 = var.imds_http_tokens
    http_put_response_hop_limit = var.imds_http_put_response_hop_limit
    instance_metadata_tags      = var.imds_instance_metadata_tags
    http_protocol_ipv6          = var.imds_http_protocol_ipv6
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = true
    device_index                = 0
    security_groups             = local.effective_security_group_ids
  }

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size           = var.root_block_device.volume_size
      volume_type           = var.root_block_device.volume_type
      encrypted             = var.root_block_device.encrypted
      delete_on_termination = var.root_block_device.delete_on_termination
      iops                  = contains(["gp3", "io1", "io2"], var.root_block_device.volume_type) ? var.root_block_device.iops : null
      throughput            = var.root_block_device.volume_type == "gp3" ? var.root_block_device.throughput : null
      kms_key_id            = var.kms_key_id
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.ebs_block_devices
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        encrypted             = block_device_mappings.value.encrypted
        delete_on_termination = block_device_mappings.value.delete_on_termination
        iops = contains(
          ["gp3", "io1", "io2"],
          block_device_mappings.value.volume_type
        ) ? try(block_device_mappings.value.iops, null) : null
        throughput = block_device_mappings.value.volume_type == "gp3" ? try(
          block_device_mappings.value.throughput,
          null
        ) : null
        kms_key_id = var.kms_key_id
      }
    }
  }

  dynamic "tag_specifications" {
    for_each = toset(["instance", "volume", "network-interface"])
    content {
      resource_type = tag_specifications.value
      tags          = local.instance_tags
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-launch-template"
  })
}
