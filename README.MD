# Cost-Optimized Kubernetes Platform on AWS (EKS + Karpenter)
Automated deployment of an Amazon EKS cluster with intelligent node provisioning using Karpenter, supporting Graviton (ARM64) and Spot Instances for cost-efficient, workload-driven scaling.

## Overview

This repository contains Terraform Infrastructure as Code used to provision a production-ready Amazon EKS environment on AWS.

The platform integrates Karpenter to enable dynamic node autoscaling based on real-time Kubernetes workload demands. It supports both x86 and ARM64 (AWS Graviton) compute architectures and leverages EC2 Spot Instances to optimize infrastructure cost while maintaining scalability and performance.

### Key Features
- **Amazon EKS Cluster Deployment:** 
  Provisions a fully managed Kubernetes cluster on AWS using Terraform, including the required infrastructure such as networking, IAM roles, and compute configuration.
- **Karpenter Integration:** 
  Installs and configures Karpenter to automatically provision and terminate EC2 worker nodes based on Kubernetes pod scheduling demands, enabling real-time cluster scaling.
- **Multi-Architecture Support:** 
  Supports both x86 and ARM64 (AWS Graviton) instance types, allowing workloads to be scheduled on the appropriate CPU architecture depending on container compatibility.
- **Spot Instance Utilization:** 
  Configures Karpenter to prioritize EC2 Spot Instances, enabling the cluster to use discounted spare AWS capacity for significant compute cost savings.
- **Dynamic Node Provisioning:**
  Automatically launches new nodes when workloads require additional resources and removes underutilized nodes to maintain efficient cluster utilization.

## Repository Structure
```
.
├── README.MD                
├── main.tf                  
├── modules/                 
│   ├── eks/                 
│   ├── karpenter/           
│   └── vpc/                 
├── workloads/               
│   ├── arm64-workload.yaml  
│   ├── x86-workload.yaml    
│   ├── ec2-node-class.yaml  
│   ├── node-pool.yaml       
├── terraform.tfvars         
├── provider.tf              
└── variables.tf 
```

## Prerequisites
- AWS Account
- AWS CLI configured with necessary IAM permissions
- Existing AWS VPC (one has been provided in this repo)
- Terraform installed
- kubectl installed


## Deployment Steps
1. Clone the Repository

```
git clone <repo-url>
cd <repo-name>
```

2. Initialize Terraform

```
terraform init
```

3. Review and modify `terraform.tfvars`. Ensure the correct values for:

- `region`: AWS region for deployment.

4. Generate and review the Terraform plan:

```
terraform plan
```
This will show the resources Terraform will create or modify.

5. Apply the Terraform Configuration

```
terraform apply -auto-approve
```
This provisions the EKS cluster along with Karpenter and necessary configurations.

6. Configure Kubectl
```
aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
```

## Deploying Workloads

Karpenter provisions nodes dynamically based on pod requirements.

1. Deploy an x86-based Workload

```
kubectl apply -f workloads/x86-workload.yaml
```

2. Deploy an ARM64 (Graviton) Workload

```
kubectl apply -f workloads/arm64-workload.yaml
```

3. Verify Pod Scheduling

```
kubectl get pods -o wide
```

You should see the pods scheduled on the appropriate node architectures.


## Monitoring Karpenter
1. Check Karpenter logs:

```
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

2. List running nodes:

```
kubectl get nodes -o wide
```

## Cleanup

To destroy the infrastructure:

```
terraform destroy -auto-approve
```

## Notes
- Ensure IAM roles and policies for Karpenter are properly configured.
- Karpenter provisions nodes dynamically; use `nodeSelector` or `affinity` rules where needed.
- A service-linked role must exist for AWS to allow Spot instance creation.
