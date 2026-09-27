provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
      Stack       = "platform"
      Owner       = "mahmoud"
    }
  }
}

module "network" {
  source = "../modules/network"

  name_prefix           = var.name_prefix
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  high_availability_nat = var.high_availability_nat
}

module "database" {
  source = "../modules/database"

  name_prefix                = var.name_prefix
  environment                = var.environment
  db_subnet_ids              = values(module.network.db_private_subnet_ids)
  database_security_group_id = module.network.database_security_group_id

  instance_class          = var.database_instance_class
  allocated_storage       = var.database_allocated_storage
  backup_retention_period = var.database_backup_retention_period
  deletion_protection     = var.database_deletion_protection
  skip_final_snapshot     = var.database_skip_final_snapshot
}
