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
  name = "${var.name}-${var.env}"
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
}

# resource "aws_autoscaling_group" "example" {
#   availability_zones = ["us-east-1a"]
#   desired_capacity   = 1
#   max_size           = 1
#   min_size           = 1
#
#   mixed_instances_policy {
#     launch_template {
#       launch_template_specification {
#         launch_template_id = aws_launch_template.example.id
#       }
#
#       override {
#         instance_type     = "c4.large"
#         weighted_capacity = "3"
#       }
#
#       override {
#         instance_type     = "c3.large"
#         weighted_capacity = "2"
#       }
#     }
#   }
# }