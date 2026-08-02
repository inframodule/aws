resource "aws_db_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name_prefix = "${var.identifier}-"
  family      = var.parameter_group_family
  description = "Secure PostgreSQL parameters for ${var.identifier}."

  dynamic "parameter" {
    for_each = local.effective_parameters
    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.module_tags

  lifecycle {
    create_before_destroy = true
  }
}
