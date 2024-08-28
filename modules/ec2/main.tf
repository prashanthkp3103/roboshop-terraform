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

resource "aws_launch_template" "main" {
  count   = var.asg ? 1 : 0  #if var.asg is true then 1(create) else 0(dont create)
  name = "${var.name}-${var.env}"
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_tls.id]

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
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.name}-${var.env}"
  }
}