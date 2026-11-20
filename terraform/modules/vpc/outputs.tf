# VPC ID
output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.eks_vpc.id
}

# Public Subnet IDs
output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value = {
    for key, subnet in aws_subnet.eks_public : key => subnet.id
  }
}

# Private Subnet IDs
output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value = {
    for key, subnet in aws_subnet.eks_private : key => subnet.id
  }
}
