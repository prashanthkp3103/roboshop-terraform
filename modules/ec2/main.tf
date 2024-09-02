resource "aws_security_group" "allow_tls" {
  name        = "${var.name}-${var.env}"
  description = "${var.name}-${var.env}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_node
  }

  ingress {
    from_port   = var.allow_port
    to_port     = var.allow_port
    protocol    = "tcp"
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

resource "aws_security_group" "lb" {
  #this lb should be created when asg is created
  count = var.asg ? 0 : 1  #if var.asg is false then 0(create) else 1(dont create)
  name        = "${var.name}-${var.env}-alb-sg"
  description = "${var.name}-${var.env}-alb-sg  "
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allow_sg_cidr
  }
  tags = {
    Name = "${var.name}-${var.env}-alb-sg"
  }
}

resource "aws_launch_template" "main" {
  count   = var.asg ? 1 : 0  #if var.asg is true then 1(create) else 0(dont create)
  name = "${var.name}-${var.env}"
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data   = base64encode(templatefile("${path.module}/userdata.sh", {
    env       = var.env
    role_name       = var.name
    vault_token   = var.vault_token

  }))

  tags = {
    Name  = "${var.name}-${var.env}"
  }
}



resource "aws_autoscaling_group" "main" {
  count   = var.asg ? 1 : 0  #if var.asg is true then 1(create) else 0(dont create)
  name = "${var.name}-${var.env}-asg"
  desired_capacity   = var.capacity["desired"]
  max_size           = var.capacity["max"]
  min_size           = var.capacity["min"]
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    #aws_launch_template.main.*.id[0] = meaning first one from the list
    id      = aws_launch_template.main.*.id[0]
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.name}-${var.env}"
  }
}

#instance are for database components and creates based var.asg condition
resource "aws_instance" "main" {
  count = var.asg ? 0 : 1  #if var.asg is false then 0(create) else 1(dont create)
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

resource "aws_route53_record" "www" {
  count = var.asg ? 0 : 1  #if var.asg is false then 0(create) else 1(dont create)
  zone_id = var.zone_id
  name    = "${var.name}.${var.env}"
  type    = "A"
  ttl     = 10
  records = [aws_instance.main.*.private_ip[count.index]]
}


resource "aws_lb" "lb" {
  #this lb should be created when asg is created
  count = var.asg ? 0 : 1  #if var.asg is false then 0(create) else 1(dont create)
  name               = "${var.name}-${var.env}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.*.id[count.index]]
  subnets            = var.subnet_ids

  #enable_deletion_protection = true

#   access_logs {
#     bucket  = aws_s3_bucket.lb_logs.id
#     prefix  = "test-lb"
#     enabled = true
#   }

  tags = {
    Environment = "${var.name}-${var.env}-alb-sg"
  }
}