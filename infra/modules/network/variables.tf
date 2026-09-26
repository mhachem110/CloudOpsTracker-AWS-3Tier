variable "name_prefix" {
  description = "Prefix used for CloudOpsTracker AWS resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
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
  description = "When true, deploy one NAT Gateway per AZ. When false, use a single NAT Gateway in AZ A."
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Port exposed by Nginx on the application EC2 instances."
  type        = number
  default     = 80
}

variable "database_port" {
  description = "Microsoft SQL Server port used by the application tier."
  type        = number
  default     = 1433
}
