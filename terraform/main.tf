module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr

  availability_zones = {
    a = "us-east-1a"
    b = "us-east-1b"
  }
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  private_subnet_ids = module.vpc.private_subnet_ids
}