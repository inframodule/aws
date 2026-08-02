locals {
  module_tags = merge(var.tags, {
    Module        = "rds-postgresql"
    ModuleVersion = "1.0.0"
  })

  secure_parameters = {
    "rds.force_ssl" = {
      value        = "1"
      apply_method = "pending-reboot"
    }
    "log_connections" = {
      value        = "1"
      apply_method = "immediate"
    }
    "log_disconnections" = {
      value        = "1"
      apply_method = "immediate"
    }
    "log_min_duration_statement" = {
      value        = "1000"
      apply_method = "immediate"
    }
  }

  effective_parameters         = merge(var.parameters, local.secure_parameters)
  managed_security_group_ids   = var.create_security_group ? [aws_security_group.this[0].id] : []
  effective_security_group_ids = concat(var.security_group_ids, local.managed_security_group_ids)
  effective_parameter_group    = var.create_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  final_snapshot_identifier    = var.skip_final_snapshot ? null : coalesce(var.final_snapshot_identifier, "${var.identifier}-final")
}
