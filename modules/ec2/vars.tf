variable "name" {}
variable "instance_type" {}
variable "allow_port" {}
variable "allow_sg_cidr" {}
variable "subnet_ids" {}
variable "vpc_id" {}
variable "env" {}
variable "bastion_node" {}
variable "capacity" {
  default = {}
}
variable "asg" {}