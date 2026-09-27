variable "name_prefix" {
  description = "Prefix used for CloudOpsTracker resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "source_instance_id" {
  description = "Verified single EC2 instance used to create the golden AMI."
  type        = string
}
