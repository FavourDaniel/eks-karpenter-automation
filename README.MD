# Cost-Optimized Kubernetes Platform on AWS (EKS + Karpenter)
Automated deployment of an Amazon EKS cluster with intelligent node provisioning using Karpenter, supporting Graviton (ARM64) and Spot Instances for cost-efficient, workload-driven scaling.

## Overview

This repository contains Terraform Infrastructure as Code used to provision a production-ready Amazon EKS environment.

The platform integrates Karpenter to enable dynamic node autoscaling based on real-time Kubernetes workload demands. It supports both x86 and ARM64 (AWS Graviton) compute architectures and leverages EC2 Spot Instances to optimize infrastructure cost while maintaining scalability and performance.


### Key Features

- **Amazon EKS Cluster Deployment**  
  Provisions a fully managed Kubernetes cluster on AWS using Terraform, including the required infrastructure such as networking, IAM roles, and compute configuration.

- **Karpenter Integration**  
  Automatically provisions and terminates EC2 worker nodes based on Kubernetes pod scheduling demands, enabling real-time cluster scaling.

- **Multi-Architecture Support**  
  Supports both x86 and ARM64 (AWS Graviton) instance types for architecture-aware workload scheduling.

- **Spot Instance Utilization**  
  Prioritizes EC2 Spot Instances to significantly reduce compute cost.

- **Dynamic Node Provisioning**  
  Launches new nodes on demand when workloads require additional resources and removes underutilized nodes to maintain efficient cluster utilization.


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
- Existing AWS VPC (a reference configuration is provided in this repository)
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

3. Configure Variables

Review and modify `terraform.tfvars` to ensure correct values such as:

- `region`: AWS region for deployment.


4. Review Terraform Plan

```
terraform plan
```
This displays the infrastructure resources Terraform will create or modify.


5. Apply Configuration

```
terraform apply -auto-approve
```
This provisions the EKS cluster along with Karpenter and required infrastructure components.

6. Configure Kubectl
```
aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
```



## Deploying Workloads

Karpenter provisions nodes dynamically based on pod resource requirements.

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

Pods will be scheduled onto the appropriate node architectures.



## Monitoring Karpenter

1. View Karpenter logs:

```
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

2. List active/running nodes:

```
kubectl get nodes -o wide
```



## Cleanup

To destroy all provisioned infrastructure:

```
terraform destroy -auto-approve
```



## Notes
- Ensure IAM roles and policies required by Karpenter are properly configured.
- Karpenter provisions nodes dynamically; use `nodeSelector` or `affinity` rules for architecture-specific workload scheduling.
- A service-linked role must exist to allow EC2 Spot instance provisioning.



## Outcome

This project demonstrates the design of a scalable, cost-optimized Kubernetes platform that eliminates static node provisioning by enabling workload-driven infrastructure scaling.
