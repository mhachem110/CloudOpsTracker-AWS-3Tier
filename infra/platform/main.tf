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

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
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
  instance_class             = var.database_instance_class
  allocated_storage          = var.database_allocated_storage
  backup_retention_period    = var.database_backup_retention_period
  deletion_protection        = var.database_deletion_protection
  skip_final_snapshot        = var.database_skip_final_snapshot
}

module "ec2" {
  source = "../modules/ec2"

  name_prefix       = var.name_prefix
  iam_name_prefix   = var.iam_name_prefix
  environment       = var.environment
  ami_id            = data.aws_ssm_parameter.al2023_ami.value
  instance_type     = var.ec2_instance_type
  subnet_id         = module.network.app_private_subnet_ids["a"]
  security_group_id = module.network.app_security_group_id

  aws_region          = var.aws_region
  database_host       = module.database.db_address
  database_secret_arn = nonsensitive(module.database.master_user_secret_arn)

  application_repo_url = var.application_repo_url
  application_git_ref  = var.application_git_ref
}

module "image" {
  source = "../modules/image"

  name_prefix        = var.name_prefix
  environment        = var.environment
  source_instance_id = module.ec2.instance_id
}

module "launch_template" {
  source = "../modules/launch-template"

  name_prefix           = var.name_prefix
  environment           = var.environment
  ami_id                = module.image.ami_id
  instance_type         = var.ec2_instance_type
  security_group_id     = module.network.app_security_group_id
  instance_profile_name = module.ec2.instance_profile_name

  aws_region          = var.aws_region
  database_host       = module.database.db_address
  database_secret_arn = nonsensitive(module.database.master_user_secret_arn)
}

module "alb" {
  source = "../modules/alb"

  name_prefix       = var.name_prefix
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = values(module.network.public_subnet_ids)
  security_group_id = module.network.alb_security_group_id
  target_port       = 80
  health_check_path = "/healthz"
}

module "autoscaling" {
  source = "../modules/autoscaling"

  name_prefix             = var.name_prefix
  environment             = var.environment
  launch_template_id      = module.launch_template.id
  launch_template_version = tostring(module.launch_template.latest_version)
  subnet_ids              = values(module.network.app_private_subnet_ids)
  target_group_arn        = module.alb.target_group_arn

  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size
}
