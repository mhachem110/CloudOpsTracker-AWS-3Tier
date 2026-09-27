output "vpc_id" { value = module.network.vpc_id }
output "public_subnet_ids" { value = module.network.public_subnet_ids }
output "app_private_subnet_ids" { value = module.network.app_private_subnet_ids }
output "db_private_subnet_ids" { value = module.network.db_private_subnet_ids }
output "app_security_group_id" { value = module.network.app_security_group_id }
output "database_security_group_id" { value = module.network.database_security_group_id }
output "database_identifier" { value = module.database.db_instance_identifier }
output "database_address" { value = module.database.db_address }
output "database_endpoint" { value = module.database.db_endpoint }
output "database_port" { value = module.database.db_port }

output "database_master_secret_arn" {
  value     = module.database.master_user_secret_arn
  sensitive = true
}

output "single_ec2_instance_id" { value = module.ec2.instance_id }
output "single_ec2_private_ip" { value = module.ec2.private_ip }
output "application_instance_profile_name" { value = module.ec2.instance_profile_name }
output "app_ami_id" { value = module.image.ami_id }
output "launch_template_id" { value = module.launch_template.id }
output "launch_template_latest_version" { value = module.launch_template.latest_version }
output "alb_dns_name" { value = module.alb.dns_name }
output "alb_target_group_arn" { value = module.alb.target_group_arn }
output "autoscaling_group_name" { value = module.autoscaling.name }


output "application_domain_name" {
  value = var.application_domain_name
}

output "application_url" {
  value = "https://${var.application_domain_name}"
}

output "acm_certificate_arn" {
  value = module.certificate.certificate_arn
}

output "route53_record_fqdn" {
  value = module.dns.fqdn
}
