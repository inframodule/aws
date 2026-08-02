resource "aws_autoscaling_group" "this" {
  name_prefix = "${var.name}-"

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  health_check_type         = local.effective_health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_instance_warmup   = var.default_instance_warmup

  capacity_rebalance      = var.capacity_rebalance
  protect_from_scale_in   = var.protect_from_scale_in
  termination_policies    = var.termination_policies
  enabled_metrics         = var.enabled_metrics
  metrics_granularity     = "1Minute"
  service_linked_role_arn = var.service_linked_role_arn

  dynamic "launch_template" {
    for_each = var.mixed_instances_policy == null ? [1] : []
    content {
      id      = aws_launch_template.this.id
      version = tostring(aws_launch_template.this.latest_version)
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.mixed_instances_policy == null ? [] : [var.mixed_instances_policy]
    content {
      instances_distribution {
        on_demand_allocation_strategy            = mixed_instances_policy.value.on_demand_allocation_strategy
        on_demand_base_capacity                  = mixed_instances_policy.value.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = mixed_instances_policy.value.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = mixed_instances_policy.value.spot_allocation_strategy
        spot_instance_pools = mixed_instances_policy.value.spot_allocation_strategy == "lowest-price" ? try(
          mixed_instances_policy.value.spot_instance_pools,
          null
        ) : null
        spot_max_price = try(mixed_instances_policy.value.spot_max_price, null)
      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.this.id
          version            = tostring(aws_launch_template.this.latest_version)
        }

        dynamic "override" {
          for_each = mixed_instances_policy.value.overrides
          content {
            instance_type     = override.value.instance_type
            weighted_capacity = try(override.value.weighted_capacity, null)
          }
        }
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.enable_instance_refresh ? [var.instance_refresh] : []
    content {
      strategy = "Rolling"
      triggers = tolist(instance_refresh.value.triggers)

      preferences {
        auto_rollback                = instance_refresh.value.auto_rollback
        instance_warmup              = local.effective_instance_refresh_warmup
        min_healthy_percentage       = instance_refresh.value.min_healthy_percentage
        max_healthy_percentage       = instance_refresh.value.max_healthy_percentage
        scale_in_protected_instances = instance_refresh.value.scale_in_protected_instances
        skip_matching                = instance_refresh.value.skip_matching
        standby_instances            = instance_refresh.value.standby_instances
      }
    }
  }

  dynamic "tag" {
    for_each = local.instance_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
