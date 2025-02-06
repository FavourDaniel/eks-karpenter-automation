

resource "aws_security_group" "karpenter_nodes" {
  name        = "karpenter-nodes-${var.cluster_name}"
  description = "Security group for Karpenter-managed worker nodes in EKS cluster ${var.cluster_name}"
  vpc_id      = var.vpc_id

  tags = {
    Name                                        = "karpenter-nodes-${var.cluster_name}"
    "karpenter.sh/discovery"                    = var.cluster_name
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "purpose"                                   = "karpenter-node-security"
  }
}


# Allow required ports for node-to-node communication (kubelet, CNI, etc)
resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other for pod networking and cluster services"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.karpenter_nodes.id
  source_security_group_id = aws_security_group.karpenter_nodes.id
  type                     = "ingress"
}


# Allow required ports from the worker nodes to the control plane
resource "aws_security_group_rule" "nodes_to_control_plane" {
  description              = "Allow worker nodes to communicate with control plane API"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = var.cluster_security_group_id
  source_security_group_id = aws_security_group.karpenter_nodes.id
  type                     = "ingress"
}


# Allow required ports from control plane to nodes
resource "aws_security_group_rule" "control_plane_to_nodes" {
  description              = "Allow control plane to communicate with worker nodes (kubelet and pod logs)"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.karpenter_nodes.id
  source_security_group_id = var.cluster_security_group_id
  type                     = "ingress"
}

# Allow limited outbound internet access for essential services
resource "aws_security_group_rule" "nodes_outbound" {
  description       = "Allow nodes outbound access to essential services"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.karpenter_nodes.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
