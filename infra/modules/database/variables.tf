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

variable "db_subnet_ids" {
  description = "Private database subnet IDs used by the RDS DB subnet group."
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_ids) >= 2
    error_message = "At least two database subnets are required."
  }
}

variable "database_security_group_id" {
  description = "Security group ID that allows SQL Server traffic from the application tier."
  type        = string
}

variable "instance_class" {
  description = "RDS SQL Server DB instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial RDS storage size in GiB."
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Protect the RDS instance from accidental deletion."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final DB snapshot when the instance is destroyed. Intended for ephemeral training environments."
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  type    = string
  default = null
}
