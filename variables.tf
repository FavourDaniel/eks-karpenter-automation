variable "cidr_block" {
  type = string
}

variable "instance_tenancy" {
  type = string
}

variable "enable_dns_hostnames" {
  type = bool
}

variable "tag" {
  type = string
}

variable "region" {
  type = string
}

variable "az_count" {
  type = number
}

variable "cluster_name" {
  type = string
}

variable "cluster_role_name" {
  type = string
}

variable "node_group_name" {
  type = string
}

variable "instance_types" {
  type = list(string)
}

variable "capacity_type" {
  type = string
}

variable "desired_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "max_unavailable" {
  type = number
}

variable "min_size" {
  type = number
}

variable "worker_node_iam_role_name" {
  type = string
}

variable "addons" {
  type = list(map(string))
}

variable "cluster_version" {
  type = string
}

variable "karpenter_version" {
  type        = string
  description = "karpenter helm chart version"
}
