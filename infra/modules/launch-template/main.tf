resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-${var.environment}-app-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  update_default_version = true

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

  # The AMI already contains Nginx + the published .NET applications.
  # Runtime user-data only refreshes environment-specific DB values and
  # restarts the services when future ASG instances are launched.
  user_data = base64encode(templatefile("${path.module}/runtime_user_data.sh.tftpl", {
    aws_region           = var.aws_region
    database_host        = var.database_host
    database_secret_arn  = var.database_secret_arn
    data_protection_path = "/${var.name_prefix}/${var.environment}/data-protection"
  }))

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = "gp3"
      volume_size           = 16
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name_prefix}-${var.environment}-app-asg"
      Tier = "application"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${var.name_prefix}-${var.environment}-app-volume"
    }
  }

  tags = {
    Name = "${var.name_prefix}-${var.environment}-app-lt"
  }
}
