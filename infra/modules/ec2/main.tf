data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.iam_name_prefix}-app-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = "${var.iam_name_prefix}-app-${var.environment}"
    Role = "application"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "database_secret" {
  statement {
    sid    = "ReadRDSManagedSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]

    resources = [var.database_secret_arn]
  }
}

resource "aws_iam_role_policy" "database_secret" {
  name   = "read-rds-managed-secret"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.database_secret.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.iam_name_prefix}-app-${var.environment}"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.this.name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region            = var.aws_region
    database_host         = var.database_host
    database_secret_arn   = var.database_secret_arn
    application_repo_url  = var.application_repo_url
    application_git_ref   = var.application_git_ref
    application_log_group = try(aws_cloudwatch_log_group.application[0].name, "")
    data_protection_path  = "/${var.name_prefix}/${var.environment}/data-protection"
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 16
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name    = "${var.name_prefix}-${var.environment}-app-single"
    Tier    = "application"
    Mode    = "image-source"
    Release = var.application_git_ref
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_iam_role_policy.database_secret,
    aws_iam_role_policy.data_protection
  ]
}
