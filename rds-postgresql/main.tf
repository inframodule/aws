resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.identifier}-"
  description = "Private subnets for ${var.identifier}."
  subnet_ids  = var.subnet_ids
  tags        = local.module_tags
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  port           = var.port
  db_name        = var.database_name
  username       = var.master_username

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id
  iops                  = var.iops
  storage_throughput    = var.storage_throughput

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = local.effective_security_group_ids
  publicly_accessible    = false
  multi_az               = var.multi_az
  network_type           = "IPV4"

  parameter_group_name = local.effective_parameter_group

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = true
  delete_automated_backups  = var.delete_automated_backups
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
  ca_cert_identifier          = var.ca_cert_identifier

  tags = local.module_tags

  depends_on = [aws_cloudwatch_log_group.this]

  lifecycle {
    precondition {
      condition     = var.create_security_group ? var.vpc_id != null && trimspace(var.vpc_id) != "" : length(var.security_group_ids) > 0
      error_message = "Set vpc_id for the managed security group, or provide security_group_ids when managed creation is disabled."
    }

    precondition {
      condition     = var.create_parameter_group || (var.parameter_group_name != null && trimspace(var.parameter_group_name) != "")
      error_message = "parameter_group_name is required when create_parameter_group is false."
    }

    precondition {
      condition     = var.deletion_protection || var.allow_deletion_protection_disable
      error_message = "Disabling deletion protection requires allow_deletion_protection_disable = true."
    }

    precondition {
      condition     = !var.skip_final_snapshot || var.allow_skip_final_snapshot
      error_message = "Skipping the final snapshot requires allow_skip_final_snapshot = true."
    }

    precondition {
      condition     = var.max_allocated_storage == 0 || var.max_allocated_storage >= var.allocated_storage
      error_message = "max_allocated_storage must be zero or at least allocated_storage."
    }

    precondition {
      condition     = var.monitoring_interval == 0 || (var.monitoring_role_arn != null && trimspace(var.monitoring_role_arn) != "")
      error_message = "monitoring_role_arn is required when Enhanced Monitoring is enabled."
    }
  }
}
