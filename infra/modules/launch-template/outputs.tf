output "id" {
  description = "Launch Template ID."
  value       = aws_launch_template.this.id
}

output "latest_version" {
  description = "Latest Launch Template version."
  value       = aws_launch_template.this.latest_version
}
