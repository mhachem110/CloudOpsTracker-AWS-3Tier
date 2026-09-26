variable "aws_region" {
  description = "AWS region used by CloudOpsTracker."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for CloudOpsTracker AWS resource names."
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
