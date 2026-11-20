# Subnets
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

# VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Nat Gateway
resource "aws_nat_gateway" "eks_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.eks_public["public-a"].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.eks_igw] # Depende do Internet Gateway para garantir que ele seja criado antes do Nat Gateway
}

# Elastic IP para o Nat Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip" # Nome do Elastic IP para o Nat Gateway
  }
}

# Subnets Public
resource "aws_subnet" "eks_public" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.eks_vpc.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${each.key}"

    "kubernetes.io/role/elb" = "1" # Essas tags ajudarão o AWS Load Balancer Controller a identificar as subnets adequadas para Load Balancers públicos e internos.
  }
}

# Subnets Private
resource "aws_subnet" "eks_private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.eks_vpc.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${each.key}"

    "kubernetes.io/role/elb" = "1" # Essas tags ajudarão o AWS Load Balancer Controller a identificar as subnets adequadas para Load Balancers públicos e internos.
  }
}

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Tables Privadas
resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.project_name}-${each.key}-rt"
  }
}

# Assosiação das Subnets Públicas à Route Table Pública
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.eks_public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Assosiação das Subnets Privadas à Route Table Privada
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.eks_private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

#Rota para acesso à Internet nas Subnets Públicas (Route Table Public)
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}

#Rota para acesso à Internet nas Subnets Privadas via Nat Gateway (Route Table Private)
resource "aws_route" "private_internet_access" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks_nat.id
}
