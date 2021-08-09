resource "aws_vpc" "Geniusee_EKS" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}-${var.env}"
    Environment = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Geniusee_EKS.id

  tags = {
    Name = "For_Geniusee"
  }
}

resource "aws_route_table" "IGW" {
  vpc_id = aws_vpc.Geniusee_EKS.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "For_IGW"
  }
}

resource "aws_main_route_table_association" "IGW" {
  vpc_id         = aws_vpc.Geniusee_EKS.id
  route_table_id = aws_route_table.IGW.id

}

locals {
  subnet = flatten([
      for public_eks, config in var.subnet_map: [
        {
          cidr_block        = config.cidr_block
          availability_zone = config.availability_zone
          name              = config.name
        }
    ]
  ])
}

resource "aws_subnet" "public" {
  for_each                = var.subnet_map
  availability_zone       = each.value["availability_zone"]
  vpc_id                  = aws_vpc.Geniusee_EKS.id
  cidr_block              = each.value["cidr_block"]
  map_public_ip_on_launch = true


  tags = {
    #Name = "Public ${var.name}-${var.env}"
    Name                              = each.value["name"]
    "kubernetes.io/role/elb" = 1
  }
}

locals {
  subnet_private = flatten([
  for private_eks, config in var.subnet_map_pr: [
    {
      cidr_block        = config.cidr_block
      availability_zone = config.availability_zone
      name              = config.name
      associated_public_subnet = config.associated_public_subnet
    }
  ]
  ])
}

resource "aws_subnet" "private" {
  for_each          = var.subnet_map_pr
  availability_zone = each.value["availability_zone"]
  vpc_id            = aws_vpc.Geniusee_EKS.id
  cidr_block        = each.value["cidr_block"]

  tags = {
    Name                              = each.value["name"]
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_eip" "nat" {
  for_each          = var.subnet_map
  vpc = true

  tags = {
    Environment = "core"
    Name = "eip-${each.value["name"]}"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  for_each = var.subnet_map

  allocation_id = aws_eip.nat[each.value["name"]].id
  subnet_id     = aws_subnet.public[each.value["name"]].id

  tags = {
    Environment = "core"
    Name        = "nat-${each.value["name"]}"
  }
}

resource "aws_route_table" "private" {
  for_each = var.subnet_map

  vpc_id = aws_vpc.Geniusee_EKS.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw[each.value["name"]].id
  }

  tags = {
    Environment = "core"
    Name        = "rt-${each.value["name"]}"
  }
}

resource "aws_route_table_association" "private" {

  for_each = var.subnet_map_pr

  subnet_id      = aws_subnet.private[each.value["name"]].id
  route_table_id = aws_route_table.private[each.value["associated_public_subnet"]].id
}

resource "aws_security_group" "For_EKS" {
  name = "EKS/ControlPlaneSecurityGroup"
  description = "For_LB"
  vpc_id = aws_vpc.Geniusee_EKS.id
  ingress {
    description = "For_App_Traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "For_EKS"
  }
}