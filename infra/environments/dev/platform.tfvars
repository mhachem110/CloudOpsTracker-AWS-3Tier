environment = "dev"
vpc_cidr    = "10.20.0.0/16"

high_availability_nat = false

database_instance_class          = "db.t3.micro"
database_allocated_storage       = 20
database_backup_retention_period = 1

# Training project: live environments are short-lived.
database_deletion_protection = false
database_skip_final_snapshot = true

ec2_instance_type = "t3.small"

application_repo_url = "https://github.com/mhachem110/CloudOpsTracker-AWS-3Tier.git"
application_git_ref  = "dev"
