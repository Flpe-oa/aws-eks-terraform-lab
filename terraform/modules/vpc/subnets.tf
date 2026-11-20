# Definição das Availability Zones e dos blocos de rede
locals {
  subnet_slots = {
    a = {
      az     = var.availability_zones.a
      netnum = 1
    }
    b = {
      az     = var.availability_zones.b
      netnum = 2
    }
  }

  public_subnets = {
    for key, slot in local.subnet_slots : "public-${key}" => {
      az   = slot.az
      cidr = cidrsubnet(var.vpc_cidr, 8, slot.netnum)
    }
  }

  private_subnets = {
    for key, slot in local.subnet_slots : "private-${key}" => {
      az   = slot.az
      cidr = cidrsubnet(var.vpc_cidr, 8, slot.netnum + 10)
    }
  }
}

# Subnets públicas
resource "aws_subnet" "eks_public" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.eks_vpc.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${each.key}"

    "kubernetes.io/role/elb" = "1"
  }
}

# Subnets privadas
resource "aws_subnet" "eks_private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.eks_vpc.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${each.key}"

    "kubernetes.io/role/internal-elb" = "1"
  }
}