variable "name_prefix" {
  description = "Prefix used for non-IAM CloudOpsTracker resources."
  type        = string
}

variable "iam_name_prefix" {
  description = "Prefix used for CloudOpsTracker IAM resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by the single application server."
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Private application subnet for the single EC2 instance."
  type        = string
}

variable "security_group_id" {
  description = "Application security group ID."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "database_host" {
  description = "RDS SQL Server DNS hostname."
  type        = string
}

variable "database_secret_arn" {
  description = "RDS-managed Secrets Manager secret ARN."
  type        = string
}

variable "application_repo_url" {
  description = "Git repository cloned by the training EC2 bootstrap."
  type        = string
}

variable "application_git_ref" {
  description = "Git branch/ref cloned by the training EC2 bootstrap."
  type        = string
}
