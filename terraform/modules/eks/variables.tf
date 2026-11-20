variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas utilizadas pelo EKS"
  type        = map(string)
}