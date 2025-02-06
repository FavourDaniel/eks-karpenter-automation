# Automate AWS EKS cluster setup with Karpenter, while utilizing Graviton and Spot instances

## Overview

This repository provides Terraform code to deploy an Amazon EKS cluster on AWS using the latest available version. The cluster is configured with Karpenter for dynamic autoscaling and supports both x86 and ARM64 (Graviton) instance types, including Spot instances for cost optimization.

### Features
- **Amazon EKS:** Creates an EKS cluster in an existing VPC.
- **Karpenter Integration:** Deploys Karpenter to handle node provisioning dynamically.
- **Multi-Architecture Support:** Allows scheduling workloads on both x86 and ARM64 nodes.
- **Spot Instance Utilization:** Optimizes costs by leveraging AWS Spot instances.

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
- An AWS Account
- AWS CLI configured with necessary IAM permissions
- An existing AWS VPC
- Terraform installed
- kubectl to interact with your cluster


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

- `vpc_id`: ID of the existing VPC.

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
- The existing VPC must have appropriate subnets and routing.
- Karpenter provisions nodes dynamically; use `nodeSelector` or `affinity` rules where needed.
- A service-linked role must exist for AWS to allow Spot instance creation.