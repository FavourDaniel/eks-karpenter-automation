resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_iam.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

# Configures authentication and admin permissions for the EKS cluster setup
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]

  tags = {
    Name = "${var.tag}-eks-cluster"
  }
}


##----------------------------------
## IAM role - For AWS to manage resources 
##----------------------------------

resource "aws_iam_role" "eks_cluster_iam" {
  name               = var.cluster_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Name = "${var.tag}-eks-cluster-iam-role"
  }
}


resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_iam.name
}


resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_iam.name
}