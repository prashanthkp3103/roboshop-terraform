resource "aws_security_group" "allow_tls" {
  name        = "${var.name}-${var.env}"
  description = "${var.name}-${var.env}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.bastion_node
  }

  ingress {
    from_port   = var.allow_port
    to_port     = var.allow_port
    protocol    = "TCP"
    #below condition is frontend will public access and allow sg_cidr as well
    cidr_blocks = var.allow_sg_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-${var.env}"
  }
}

#instances are for database components and creates based var.asg condition
#creates multiple instances based asg variable true or false
resource "aws_instance" "main" {
  #count = var.asg ? 0 : 1  #if var.asg is false then 0(create) else 1(dont create)
  ami           = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  #var.subnet_ids[0] = meaning first one from the list
  subnet_id = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data   = base64encode(templatefile("${path.module}/userdata.sh", {
    env       = var.env
    role_name       = var.name
    vault_token   = var.vault_token

  }))

  tags = {
    Name = "${var.name}-${var.env}"
  }
}

#creates multiple records based asg variable true or false
resource "aws_route53_record" "instance" {
  #count = var.asg ? 0 : 1  #if var.asg creation is false then 0(create) else 1(dont create) - o false -1 true
  zone_id = var.zone_id
  name    = "${var.name}.${var.env}"
  type    = "A"
  ttl     = 10
  records = [aws_instance.main.private_ip]
  #records = [aws_instance.main.*.private_ip[count.index]]
  #records = [aws_instance.main.private_ip]
}





