resource "aws_autoscaling_policy" "cpu" {
  count = var.cpu_target_value == null ? 0 : 1

  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value     = var.cpu_target_value
    disable_scale_in = var.disable_scale_in

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}

resource "aws_autoscaling_policy" "alb_request_count" {
  count = var.alb_request_count_target_value == null ? 0 : 1

  name                   = "${var.name}-alb-requests-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value     = var.alb_request_count_target_value
    disable_scale_in = var.disable_scale_in

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_resource_label
    }
  }
}
