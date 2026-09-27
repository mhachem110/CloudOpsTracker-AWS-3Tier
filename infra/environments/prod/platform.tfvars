environment = "prod"
vpc_cidr    = "10.50.0.0/16"

high_availability_nat = true

database_instance_class          = "db.t3.micro"
database_allocated_storage       = 20
database_backup_retention_period = 7

# Training project: actual applies are short-lived and manually destroyed.
database_deletion_protection = false
database_skip_final_snapshot = true
