output "terraform_state_bucket" {
  description = "S3 bucket containing Terraform remote state."
  value       = aws_s3_bucket.tfstate.bucket
}

output "deployment_role_arns" {
  description = "GitHub Actions deployment role ARN for each environment."
  value = {
    for environment, role in aws_iam_role.deploy :
    environment => role.arn
  }
}
