variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alb_arn_suffix" {
  description = "Application Load Balancer ARN suffix used by CloudWatch metrics."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target Group ARN suffix used by CloudWatch metrics."
  type        = string
}

variable "autoscaling_group_name" {
  type = string
}

variable "database_identifier" {
  type = string
}
