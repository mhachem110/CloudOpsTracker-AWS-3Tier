variable "aws_region" {
  description = "AWS region used by the CloudOpsTracker project."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for non-IAM AWS resources."
  type        = string
}

variable "iam_name_prefix" {
  description = "Prefix used for IAM resources."
  type        = string
}

variable "github_oidc_repo_segment" {
  description = "Immutable GitHub OIDC repository segment: owner@owner_id/repo@repo_id."
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket used for Terraform remote state."
  type        = string
}
