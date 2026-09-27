variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "target_port" { type = number default = 80 }
variable "health_check_path" { type = string default = "/healthz" }
