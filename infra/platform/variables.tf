variable "aws_region" {
  description = "AWS region used by CloudOpsTracker."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for CloudOpsTracker non-IAM AWS resource names."
  type        = string
}

variable "iam_name_prefix" {
  description = "Prefix used for CloudOpsTracker IAM resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "uat", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, uat, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the environment VPC."
  type        = string
}

variable "high_availability_nat" {
  description = "Create one NAT Gateway per AZ when true; otherwise create one NAT Gateway total."
  type        = bool
  default     = false
}

variable "database_instance_class" {
  description = "RDS SQL Server DB instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "database_allocated_storage" {
  description = "Initial RDS SQL Server storage in GiB."
  type        = number
  default     = 20
}

variable "database_backup_retention_period" {
  description = "Number of days to retain automated RDS backups."
  type        = number
  default     = 1
}

variable "database_deletion_protection" {
  description = "Protect the RDS instance from accidental deletion."
  type        = bool
  default     = false
}

variable "database_skip_final_snapshot" {
  description = "Skip the final RDS snapshot when destroying the training environment."
  type        = bool
  default     = true
}

variable "ec2_instance_type" {
  description = "Instance type used for the application EC2 server."
  type        = string
  default     = "t3.small"
}

variable "application_repo_url" {
  description = "Git repository used by the EC2 bootstrap."
  type        = string
}

variable "application_git_ref" {
  description = "Git branch/ref used by the EC2 bootstrap."
  type        = string
}


variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 3
}
