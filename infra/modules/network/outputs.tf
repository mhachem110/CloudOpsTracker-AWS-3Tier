output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Availability zones used by this network."
  value       = local.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by AZ slot."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "app_private_subnet_ids" {
  description = "Private application subnet IDs keyed by AZ slot."
  value       = { for key, subnet in aws_subnet.app_private : key => subnet.id }
}

output "db_private_subnet_ids" {
  description = "Isolated database subnet IDs keyed by AZ slot."
  value       = { for key, subnet in aws_subnet.db_private : key => subnet.id }
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs keyed by AZ slot."
  value       = { for key, nat in aws_nat_gateway.this : key => nat.id }
}

output "alb_security_group_id" {
  description = "Security group ID reserved for the Application Load Balancer."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for application EC2 instances."
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "Security group ID for RDS SQL Server."
  value       = aws_security_group.database.id
}
