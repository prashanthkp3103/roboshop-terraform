 variable "name" {}
 variable "instance_type" {}
 variable "allow_port" {}
 variable "allow_sg_cidr" {}
 variable "subnet_ids" {}
 variable "vpc_id" {}
 variable "env" {}
 variable "bastion_node" {}
# variable "capacity" {
#   default = {}
# }
# variable "asg" {}
 variable "vault_token" {}
 variable "zone_id" {}
# #as we're using same app module code for db as well and db doesnt required Lb hence we are passing null value and as DB module expects value for db module as we used app module code
# variable "internal" {
#   default = null
# }
#
# #empty list
# variable "lb_subnet_ids" {
#   default = []
# }
# variable "allow_lb_sg_cidr" {
#   default = []
# }