#string
env = "dev"

#list
#workstation private ip, 32 meaning 1 machine
bastion_node = ["172.31.16.106/32"]

zone_id       = "Z0668859214N41P8Y7GLH"




#this is map variable
vpc = {
  cidr = "10.10.0.0/16"
  public_subnets = ["10.10.0.0/24", "10.10.1.0/24"]
  web_subnets = ["10.10.2.0/24", "10.10.3.0/24"]
  app_subnets = ["10.10.4.0/24", "10.10.5.0/24"]
  db_subnets = ["10.10.6.0/24", "10.10.7.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
  default_vpc_id  = "vpc-0c0ac8ab11b12d50d"
  default_vpc_rt  = "rtb-00808cdef03afd1da"
  default_vpc_cidr = "172.31.0.0/16"

}

apps = {
  frontend = {
    subnet_ref  = "web"
    instance_type = "t3.small"
    allow_port  = 80
    #below allow_sg_cidr is list property in ec2 map variable
    ##allowing only public subnets
    allow_sg_cidr =  ["10.10.0.0/24", "10.10.1.0/24"] #public subnets
    allow_lb_sg_cidr = ["0.0.0.0/0"]
    #below capacity is map property
    capacity      = {
      desired     = 1
      max = 1
      min = 1
    }
    #this property is for lb (whether it is internal(meaning intranet) or internet=false(meaning it is internet)
    lb_internal   = false
    #below public property is output of vpc subnets "public" refer to vpc outputs public it will be subnet ids
    #and Lb to create under public subnet
    lb_subnet_ref     = "public"
    acm_http_arn  = "arn:aws:acm:us-east-1:261401039448:certificate/174aed8f-1258-49f5-a8ea-5a6a7be63e3f"

  }

  #
  catalogue = {
    subnet_ref  = "app"
    instance_type = "t3.small"
    allow_port  = 8080
    #below allow_sg_cidr is list property in ec2 map variable
    ##allowing only app subnets #reason for allowing multiple subnet is for communication lb to asg
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #application subnets should accessible by these #subnets
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #Lb subnets should accessible by these #web subnets
    #below capacity is map property
    capacity      = {
      desired     = 1
      max = 1
      min = 1
    }
    lb_internal   = true
    #below app property is output of vpc subnets "app" refer to vpc outputs app it will be subnet ids
    #and Lb to create under app subnet
    lb_subnet_ref     = "app"
    acm_http_arn      = null

  }

  cart = {
    subnet_ref  = "app"
    instance_type = "t3.small"
    allow_port  = 8080
    #below allow_sg_cidr is list property in ec2 map variable
    ##allowing only app subnets
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #application should accessible by these #
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #Lb should accessible by these subnets
    #below capacity is map property
    capacity      = {
      desired     = 1
      max = 1
      min = 1
    }
    lb_internal   = true
    #below app property is output of vpc subnets "app" refer to vpc outputs app it will be subnet ids
    #and Lb to create under app subnet
    lb_subnet_ref     = "app"
    acm_http_arn      = null

  }

  user = {
    subnet_ref  = "app"
    instance_type = "t3.small"
    allow_port  = 8080
    #below allow_sg_cidr is list property in ec2 map variable
    ##allowing only app subnets
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #application should accessible by these #
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #Lb should accessible by these #web
    #below capacity is map property
    capacity      = {
      desired     = 1
      max = 1
      min = 1
    }
    lb_internal   = true
    #below app property is output of vpc subnets "app" refer to vpc outputs app it will be subnet ids
    #and Lb to create under app subnet
    lb_subnet_ref     = "app"
    acm_http_arn      = null

  }

  shipping = {
    subnet_ref  = "app"
    instance_type = "t3.small"
    allow_port  = 8080
    #below allow_sg_cidr is list property in ec2 map variable
    ##allowing only app subnets
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #application should accessible by these #
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #Lb should accessible by these #web
    #below capacity is map property
    capacity      = {
      desired     = 1
      max = 1
      min = 1
    }
    lb_internal   = true
    #below app property is output of vpc subnets "app" refer to vpc outputs app it will be subnet ids
    #and Lb to create under app subnet
    lb_subnet_ref     = "app"
    acm_http_arn      = null

  }

  payment = {
    subnet_ref  = "app"
    instance_type = "t3.small"
    allow_port  = 8080
    #below allow_sg_cidr is list property in ec2 map variable
    ##allowing only app subnets
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #application should accessible by these #
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #Lb should accessible by these #web
    #below capacity is map property
    capacity      = {
      desired     = 1
      max = 1
      min = 1
    }
    lb_internal   = true
    #below app property is output of vpc subnets "app" refer to vpc outputs app it will be subnet ids
    #and Lb to create under app subnet
    lb_subnet_ref     = "app"
    acm_http_arn      = null

  }

  dispatch = {
    subnet_ref  = "app"
    instance_type = "t3.small"
    allow_port  = 8080
    #below allow_sg_cidr is list property in ec2 map variable
    ##allowing only app subnets
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #application should accessible by these #
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #Lb should accessible by these #web
    #below capacity is map property
    capacity      = {
      desired     = 1
      max = 1
      min = 1
    }
    lb_internal   = true
    #below app property is output of vpc subnets "app" refer to vpc outputs app it will be subnet ids
    #and Lb to create under app subnet
    lb_subnet_ref     = "app"
    acm_http_arn      = null

  }

}

db = {
  mongo = {
    subnet_ref  = "db"
    instance_type = "t3.small"
    allow_port  = 27017
    #allowing only app subnets
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"]
  }
  mysql = {
    subnet_ref  = "db"
    instance_type = "t3.small"
    allow_port  = 3306
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"]

  }
  rabbitmq = {
    subnet_ref  = "db"
    instance_type = "t3.small"
    allow_port  = 5672
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"]
  }

  redis = {
    subnet_ref  = "db"
    instance_type = "t3.small"
    allow_port  = 6379
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"]
  }

}





