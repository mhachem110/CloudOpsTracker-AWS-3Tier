output "db_instance_identifier" {
  description = "RDS SQL Server DB instance identifier."
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "RDS SQL Server DB instance ARN."
  value       = aws_db_instance.this.arn
}

output "db_address" {
  description = "RDS SQL Server DNS address."
  value       = aws_db_instance.this.address
}

output "db_endpoint" {
  description = "RDS SQL Server endpoint including port."
  value       = aws_db_instance.this.endpoint
}

output "db_port" {
  description = "RDS SQL Server port."
  value       = aws_db_instance.this.port
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master credentials."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
  sensitive   = true
}
