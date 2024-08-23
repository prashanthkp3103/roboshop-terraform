resource "aws_vpc" "main" {
  cidr_block = var.cidr


  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_subnet" "web" {
  count = length(var.web_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.web_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "web-subnets-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "app" {
  count = length(var.app_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "app-subnets-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "db" {
  count = length(var.db_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "db-subnets-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "public-subnets-${split("-", var.availability_zones[count.index])[2]}"
  }
}

#Route table
resource "aws_route_table" "public" {
  count = length(var.public_subnets)
  vpc_id = aws_vpc.main.id

#below route is to have igw
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
#below route is for peering
  route {
    cidr_block = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }


  tags = {
    Name = "public-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_route_table" "web" {
  count = length(var.web_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.*.id[count.index]
  }

  #below route is for peering
  route {
    cidr_block = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }


  tags = {
    Name = "web-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_route_table" "app" {
  count = length(var.app_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.*.id[count.index]
  }

  #below route is for peering
  route {
    cidr_block = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }


  tags = {
    Name = "app-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_route_table" "db" {
  count = length(var.db_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.*.id[count.index]
  }

  #below route is for peering
  route {
    cidr_block = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }


  tags = {
    Name = "db-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

#route table association for subnets

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.*.id[count.index]
}

resource "aws_route_table_association" "web" {
  count = length(var.web_subnets)
  subnet_id      = aws_subnet.web.*.id[count.index]
  route_table_id = aws_route_table.web.*.id[count.index]
}


resource "aws_route_table_association" "app" {
  count = length(var.app_subnets)
  subnet_id      = aws_subnet.app.*.id[count.index]
  route_table_id = aws_route_table.app.*.id[count.index]
}

resource "aws_route_table_association" "db" {
  count = length(var.db_subnets)
  subnet_id      = aws_subnet.db.*.id[count.index]
  route_table_id = aws_route_table.db.*.id[count.index]
}

#internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

#NAT gateway for public subnet,NAT requires PIP hence eip

resource "aws_eip" "ngw-ip" {
  count   = length(var.availability_zones)
  domain   = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.ngw-ip.*.id[count.index]
  subnet_id     = aws_subnet.public.*.id[count.index]

  tags = {
    Name = "NAT-GW--${split("-", var.availability_zones[count.index])[2]}"
  }

}

#vpc peering from workstation to roboshop as we want to have bastion from workstation
resource "aws_vpc_peering_connection" "peering" {
  #peer_owner_id = var.peer_owner_id #this is my account and this is optional
  peer_vpc_id   = aws_vpc.main.id # target
  vpc_id        = var.default_vpc_id #request vpc
  auto_accept = true

  tags = {
    Name = "Default-vpc-to-Dev-vpc"

  }
}

#Adding route to default vpc route table for dev vpc tunnling
resource "aws_route" "r" {
  route_table_id            = var.default_vpc_rt
  destination_cidr_block    = var.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}
