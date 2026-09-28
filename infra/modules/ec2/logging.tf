resource "aws_cloudwatch_log_group" "application" {
  count             = var.enable_application_logs ? 1 : 0
  name              = "/${var.name_prefix}/${var.environment}/application"
  retention_in_days = 14
}
