
addons = [{
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.2-eksbuild.2"
  },
  
  {
    addon_name    = "aws-ebs-csi-driver"
    addon_version = "v1.36.0-eksbuild.1"
  }
]
cidr_block                = "10.0.0.0/16"
instance_tenancy          = "default"
enable_dns_hostnames      = true
tag                       = "opsfleet"
region                    = "eu-west-1"
az_count                  = 2
cluster_name              = "opsfleet-cluster"
cluster_role_name         = "opsfleet-cluster-IAM-role"
cluster_version           = "1.32"
node_group_name           = "opsfleet-worker-nodes"
instance_types            = ["t3.medium"]
capacity_type             = "ON_DEMAND"
desired_size              = 2
max_size                  = 3
min_size                  = 1
max_unavailable           = 1
worker_node_iam_role_name = "opsfleet-worker-node-IAM-role"
karpenter_version         = "1.2.0"