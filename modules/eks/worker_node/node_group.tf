
resource "aws_eks_node_group" "node_group" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_group_iam.arn
  version         = var.kubernetes_version
  ami_type        = "AL2_x86_64"
  subnet_ids      = var.private_subnet_ids
  labels = {
     Environment: "dev"
  }
  instance_types = var.instance_types
  capacity_type = var.capacity_type

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group-AmazonEC2ContainerRegistryFullAccess,
    aws_iam_role_policy_attachment.node_group-AmazonRoute53FullAccess,
    aws_iam_role_policy_attachment.node_group-AmazonEBSCSIDriverPolicy
  ]

  tags = {
    Name = "${var.tag}-eks-nodegroup"
  }
}

##-----------------------------------------
##           IAM ROLE for Worker Nodes
##-----------------------------------------------
resource "aws_iam_role" "eks_node_group_iam" {
  name = var.worker_node_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = {
    Name = "${var.tag}-eks-nodegroup-iam-role"
  }
}


##----------------------------------------------
##           POLICY ATTTACHMENT
##----------------------------------------------
resource "aws_iam_role_policy_attachment" "node_group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_iam.name
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_iam.name
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEC2ContainerRegistryFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.eks_node_group_iam.name
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonRoute53FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = aws_iam_role.eks_node_group_iam.name
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_node_group_iam.name
}