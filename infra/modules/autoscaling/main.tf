resource "aws_autoscaling_group" "this" {
  name                      = "${var.name_prefix}-${var.environment}-app-asg"
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 180
  default_instance_warmup   = 120

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-${var.environment}-app-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "application"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true

    # Auto Scaling owns desired capacity after the ASG is created.
    # Prevent Terraform from fighting the scaling policy.
    ignore_changes = [
      desired_capacity
    ]
  }
}

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.name_prefix}-${var.environment}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}