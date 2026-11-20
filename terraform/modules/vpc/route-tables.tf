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

# Associação das Subnets Públicas
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.eks_public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Associação das Subnets Privadas
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.eks_private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Rota de internet das Subnets Públicas
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}

# Rota de internet das Subnets Privadas via NAT
resource "aws_route" "private_internet_access" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks_nat.id
}