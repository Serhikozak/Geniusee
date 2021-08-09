variable "AWS_REGION" {
  type    = string
  default = "eu-central-1"
}

# VPC INFO
variable "vpc_name" {
  default = "Terravpc"
}

variable "vpc_cidr" {
  default = "10.10.10.0/24"
}

variable "subnet_map" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))

  default = {
    "public_eks_2" = {
      cidr_block        = "10.10.10.32/27"
      availability_zone = "eu-central-1b"
      name              = "public_eks_2"

    },
    "public_eks_1" = {
      cidr_block        = "10.10.10.0/27"
      availability_zone = "eu-central-1a"
      name              = "public_eks_1"

    }
  }
}

variable "subnet_map_pr" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
    associated_public_subnet = string
  }))

  default = {
    "private_eks_2" = {
      cidr_block        = "10.10.10.96/27"
      availability_zone = "eu-central-1b"
      name              = "private_eks_2"
      associated_public_subnet = "public_eks_2"

    },
    "private_eks_1" = {
      cidr_block        = "10.10.10.64/27"
      availability_zone = "eu-central-1a"
      name              = "private_eks_1"
      associated_public_subnet = "public_eks_1"
    }
  }
}

variable "name" {
  default = "Geniusee"
}


variable "env" {
  default = "stage"
}

variable "eks_cluster_name" {
  default = "EKS_cluster"
}

variable "domain" {
  default = "es-for-eks"
}
