# Elastic IP para o NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "eks_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.eks_public["public-a"].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [
    aws_route.public_internet_access
  ]
}