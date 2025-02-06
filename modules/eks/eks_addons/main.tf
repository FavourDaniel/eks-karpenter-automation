
resource "aws_eks_addon" "eks_addons" {
  cluster_name                = var.cluster_name
  addon_name                  = var.addon_name
  addon_version               = var.addon_version
  # used to retain the config changes applied to the add-on
  resolve_conflicts_on_update = "PRESERVE"
}