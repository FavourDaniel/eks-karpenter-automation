
output "endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "identity" {
  value = aws_eks_cluster.eks_cluster.identity
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.id
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}