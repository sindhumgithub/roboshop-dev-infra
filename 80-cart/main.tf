module "cart" {
  source = "D:\\DevOpsShiva\\terraform-roboshop-project\\terraform-aws-services"
  project_name   = var.project_name
  environment    = var.environment
  instance_type = var.instance_type
  service_name   = var.service_name
  ssh_user         = "ec2-user"
  ssh_password     = "DevOps321"
  script_source_path = "cart.sh"
  health_check_interval = var.health_check_interval
  priority = 30
  domain_name = var.domain_name
}


