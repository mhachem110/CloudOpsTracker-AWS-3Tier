resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-${var.environment}-db-subnets"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.name_prefix}-${var.environment}-db-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-${var.environment}-sql"

  engine         = "sqlserver-ex"
  license_model  = "license-included"
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  username                    = "cloudopsadmin"
  manage_master_user_password = true

  port                   = 1433
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period    = var.backup_retention_period
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  delete_automated_backups = true

  tags = {
    Name = "${var.name_prefix}-${var.environment}-sql"
    Tier = "database"
  }
}
