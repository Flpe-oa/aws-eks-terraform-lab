variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "availability_zones" {
  type = object({
    a = string
    b = string
  })
}
