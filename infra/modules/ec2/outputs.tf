output "instance_id" {
  description = "Single EC2 application instance ID."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP address of the single EC2 instance."
  value       = aws_instance.this.private_ip
}

output "iam_role_name" {
  description = "IAM role used by the application EC2 instance."
  value       = aws_iam_role.this.name
}

output "instance_profile_name" {
  description = "IAM instance profile used by the application EC2 instance."
  value       = aws_iam_instance_profile.this.name
}
