provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
      Stack       = "network"
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
