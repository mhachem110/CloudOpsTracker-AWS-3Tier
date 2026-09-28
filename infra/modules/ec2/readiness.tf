resource "aws_ssm_document" "readiness" {
  name          = "${var.name_prefix}-${var.environment}-image-readiness"
  document_type = "Command"
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Verify cloud-init, migrated database, Web and API before imaging"
    parameters = {
      Release = { type = "String", allowedPattern = "^[0-9a-f]{40}$" }
    }
    mainSteps = [{
      action = "aws:runShellScript"
      name   = "VerifyImage"
      inputs = {
        timeoutSeconds = "900"
        runCommand = [
          "set -eu",
          "cloud-init status --wait",
          "test \"$(cat /opt/cloudopstracker/release-sha)\" = '{{ Release }}'",
          "test -f /opt/cloudopstracker/bootstrap-ready",
          "curl --fail --silent --max-time 10 http://127.0.0.1:5001/health/ready >/dev/null",
          "curl --fail --silent --max-time 10 http://127.0.0.1/health/ready >/dev/null"
        ]
      }
    }]
  })
}

resource "aws_ssm_association" "readiness" {
  name                             = aws_ssm_document.readiness.name
  document_version                 = aws_ssm_document.readiness.latest_version
  association_name                 = "${var.name_prefix}-${var.environment}-image-readiness-${aws_instance.this.id}"
  wait_for_success_timeout_seconds = 1200
  parameters                       = { Release = var.application_git_ref }
  lifecycle {
    replace_triggered_by = [aws_instance.this]
  }
  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "data_protection" {
  statement {
    actions   = ["ssm:GetParametersByPath", "ssm:PutParameter"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.name_prefix}/${var.environment}/data-protection/*"]
  }
  statement {
    sid           = "PreventCrossEnvironmentParameterReads"
    effect        = "Deny"
    actions       = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    not_resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.name_prefix}/${var.environment}/*"]
  }
  statement {
    actions   = ["kms:Encrypt", "kms:Decrypt"]
    resources = ["arn:${data.aws_partition.current.partition}:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values   = ["arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.name_prefix}/${var.environment}/data-protection/*"]
    }
  }
}
resource "aws_iam_role_policy" "data_protection" {
  name   = "environment-data-protection"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.data_protection.json
}
