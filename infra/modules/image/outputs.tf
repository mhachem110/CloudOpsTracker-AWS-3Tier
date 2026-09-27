output "ami_id" {
  description = "Golden application AMI ID."
  value       = aws_ami_from_instance.this.id
}

output "ami_arn" {
  description = "Golden application AMI ARN."
  value       = aws_ami_from_instance.this.arn
}
