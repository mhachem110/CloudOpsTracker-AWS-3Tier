output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "app_private_subnet_ids" {
  value = module.network.app_private_subnet_ids
}

output "db_private_subnet_ids" {
  value = module.network.db_private_subnet_ids
}

output "app_security_group_id" {
  value = module.network.app_security_group_id
}

output "database_security_group_id" {
  value = module.network.database_security_group_id
}

output "database_identifier" {
  value = module.database.db_instance_identifier
}

output "database_address" {
  value = module.database.db_address
}

output "database_endpoint" {
  value = module.database.db_endpoint
}

output "database_port" {
  value = module.database.db_port
}

output "database_master_secret_arn" {
  value     = module.database.master_user_secret_arn
  sensitive = true
}
