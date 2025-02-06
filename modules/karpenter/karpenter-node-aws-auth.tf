
# Retrieve existing IAM role, user, and account mappings from the aws-auth ConfigMap
locals {
  existing_roles    = try(yamldecode(data.kubernetes_config_map.aws_auth_existing.data["mapRoles"]), [])
  existing_users    = try(yamldecode(data.kubernetes_config_map.aws_auth_existing.data["mapUsers"]), [])
  existing_accounts = try(yamldecode(data.kubernetes_config_map.aws_auth_existing.data["mapAccounts"]), [])
}


# Update the aws-auth ConfigMap to allow Karpenter worker nodes to join the cluster
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"                  # Name of the authentication ConfigMap used by EKS
    namespace = "kube-system"               # Namespace where authentication configurations are stored
  }

  data = {
    # Add the Karpenter IAM role to the list of existing roles so nodes can authenticate
    mapRoles = jsonencode(
      concat(
        local.existing_roles,   # Preserve existing IAM role mappings
        [
          {
            # IAM role for Karpenter nodes
            "rolearn"  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.karpenter_node_role.name}",
            "username" = "system:node:{{EC2PrivateDNSName}}",
            "groups"   = ["system:bootstrappers", "system:nodes"]
          }
        ]
      )
    )

    # Preserve the list of existing IAM users mapped to the cluster
    mapUsers = jsonencode(local.existing_users)

    # Preserve the list of existing IAM accounts mapped to the cluster
    mapAccounts = jsonencode(local.existing_accounts)
  }

  force = true
  
  lifecycle {
    ignore_changes = [
      data
    ]
  }
}