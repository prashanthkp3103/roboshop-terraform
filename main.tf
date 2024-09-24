module "vpc" {
  source = "./modules/vpc"
  cidr = var.vpc["cidr"]  #this comes from dev main.tfvars variables vpc cidr
  env = var.env
  #Referring to map variable
  public_subnets = var.vpc["public_subnets"]
  web_subnets = var.vpc["web_subnets"]
  app_subnets = var.vpc["app_subnets"]
  db_subnets = var.vpc["db_subnets"]
  availability_zones = var.vpc["availability_zones"]
  default_vpc_id  = var.vpc["default_vpc_id"]
  default_vpc_rt  = var.vpc["default_vpc_rt"]
  default_vpc_cidr = var.vpc["default_vpc_cidr"]


}

module "apps" {
  depends_on = [module.db, module.vpc]
  source = "./modules/asg"

  for_each      = var.apps  #this comes from dev main.tfvars
  #In the below code each.key is catalogue(for name)
 # apps = {
 #   catalogue = {
 #     instance_type = ""
  #  }
  #}
  #it is coming from main.tfvars in env-dev
  name          = each.key  #this comes from dev main.tfvars apps
  instance_type = each.value["instance_type"]
  allow_port    = each.value["allow_port"]
  allow_sg_cidr = each.value["allow_sg_cidr"]
  #below value comes from vpc module outputs
  #subnet      = module.vpc.subnets["web"][0]
  subnet_ids    = module.vpc.subnets[each.value["subnet_ref"]]
  capacity = each.value["capacity"]
  #below value comes from vpc module outputs
  vpc_id        = module.vpc.vpc_id
  env           = var.env
  bastion_node  = var.bastion_node
  asg           = true
  vault_token   = var.vault_token
  zone_id = var.zone_id
  #below property for lb
  internal      = each.value["lb_internal"]
  lb_subnet_ids = module.vpc.subnets[each.value["lb_subnet_ref"]]
  allow_lb_sg_cidr = each.value["allow_lb_sg_cidr"]
  acm_http_arn      = each.value["acm_http_arn"]

}

#refering to vpc module output
output "web" {
  value = module.vpc.subnets["web"]

}

module "db" {
  depends_on = [module.vpc]
  source = "./modules/ec2"

  for_each = var.db #this comes from dev main.tfvars
  name = each.key  #this comes from dev main.tfvars db
  instance_type = each.value["instance_type"]
  allow_port = each.value["allow_port"]
  allow_sg_cidr = each.value["allow_sg_cidr"]
  #below value comes from vpc module outputs
  #subnet      = module.vpc.subnets["web"][0]
  subnet_ids      = module.vpc.subnets[each.value["subnet_ref"]]
  #below value comes from vpc module outputs
  vpc_id    = module.vpc.vpc_id
  env = var.env
  bastion_node = var.bastion_node
  vault_token = var.vault_token
  zone_id     = var.zone_id
}

