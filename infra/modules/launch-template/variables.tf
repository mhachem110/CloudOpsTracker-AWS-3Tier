variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "ami_id" {
  description = "Golden CloudOpsTracker AMI ID."
  type        = string
}

variable "instance_type" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "database_host" {
  type = string
}

variable "database_secret_arn" {
  type = string
}
