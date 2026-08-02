resource "aws_cloudwatch_log_group" "this" {
  for_each = var.enabled_cloudwatch_logs_exports

  name              = "/aws/rds/instance/${var.identifier}/${each.value}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.cloudwatch_log_kms_key_id

  tags = local.module_tags
}
