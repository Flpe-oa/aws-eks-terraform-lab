#Cluster EKS
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = values(var.private_subnet_ids)

    endpoint_private_access = true
    endpoint_public_access  = true

    public_access_cidrs = ["189.79.18.141/32"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster
  ]
}