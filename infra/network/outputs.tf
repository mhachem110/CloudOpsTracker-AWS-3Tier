output "vpc_id" {
  value = module.network.vpc_id
}

output "vpc_cidr" {
  value = module.network.vpc_cidr
}

output "availability_zones" {
  value = module.network.availability_zones
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

output "nat_gateway_ids" {
  value = module.network.nat_gateway_ids
}

output "alb_security_group_id" {
  value = module.network.alb_security_group_id
}

output "app_security_group_id" {
  value = module.network.app_security_group_id
}

output "database_security_group_id" {
  value = module.network.database_security_group_id
}
