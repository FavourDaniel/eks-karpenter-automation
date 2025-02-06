# GPU Slicing Implementation for EKS Clusters with Karpenter: Cost Optimization Analysis

GPU slicing is an approach that partitions a single physical GPU into multiple isolated or shared segments, enabling multiple workloads to utilize GPU resources simultaneously. This maximizes resource utilization, leading to better cost efficiency, especially for workloads that do not require the full capacity of a GPU.

### Background
Traditional GPU allocation in Kubernetes assigns entire GPUs to individual pods, often leading to significant resource underutilization. On managed Kubernetes platforms like Amazon EKS, GPU-intensive workloads can be expensive, as GPUs often run underutilized. GPU slicing directly addresses this inefficiency by enabling multiple pods to share GPU resources more effectively.

## Benefits of GPU Slicing
1. Resource Optimization: Organizations can more efficiently utilize expensive GPU hardware by precisely allocating resources based on workload requirements. Supports multiple AI/ML workloads on the same instance.
2. Cost Reduction: Instead of requiring separate dedicated GPUs for different applications, multiple workloads can run simultaneously on sliced portions of a single GPU.
3. Workload Isolation: Each workload gets a portion of the GPU, ensuring stable performance.
4. Improved Security: Hardware-level isolation between slices provides better security guarantees compared to software-based virtualization.

## GPU Slicing Options
Kubernetes supports two main GPU slicing methods: **Time-Slicing** and **Multi-Instance GPU** (MIG).

### Time-Slicing
Time-slicing allows multiple users to share a GPU by allocating usage time in turns. It works on most NVIDIA GPUs, requiring no specialized hardware. While flexible and easy to implement, it may impact performance due to resource contention. This method also supports older GPUs that lack MIG capabilities.

### Multi-Instance GPU (MIG)
MIG partitions a GPU into smaller, independent units. Each unit acts like a mini-GPU with dedicated memory and compute power. This approach provides better isolation and ensures stable performance but requires specific drivers and configuration. It is available only on NVIDIA A100 and newer GPUs.

### Key Differences

| Feature          | Multi-Instance GPU (MIG) | Time-Slicing |
|-----------------|-------------------------|-------------|
| **Isolation**   | Strong (hardware-level memory and fault isolation) | Weak (shared memory, potential resource contention) |
| **Performance** | Consistent (dedicated resources per instance) | Variable (depends on scheduling and sharing) |
| **Resource Utilization** | More predictable, each instance has dedicated resources | Can allow more users to access the GPU, but with potential performance drops |
| **Best for** | AI/ML inference, cloud-based GPU sharing, multi-tenant environments | Interactive workloads, Jupyter notebooks, rendering, older GPUs |
| **Kubernetes Support** | Supported since 2020 | Supported using NVIDIA’s time-slicing features |

## Implementing GPU Slicing on Amazon EKS Clusters (Without Karpenter)
AWS has introduced support for GPU slicing using NVIDIA Multi-Instance GPU (MIG) on specific instance types, such as AWS EC2 P4d (A100 GPUs) and A10G instances.

### Prerequisites
Before implementing GPU slicing on EKS, ensure the following prerequisites are in place:
- An existing EKS cluster
- Worker nodes with supported NVIDIA GPUs (e.g., A100, A10G).
- Helm and kubectl installed.
- Appropriate IAM roles and permissions for Karpenter to provision nodes.

### Install NVIDIA GPU Operator
The NVIDIA GPU Operator simplifies the process of managing GPU resources in Kubernetes. It automatically installs the necessary components, such as the NVIDIA device plugin, NVIDIA drivers, and other software needed to run GPU workloads.

1. Add the NVIDIA GPU Operator Helm repository:
```
helm repo add nvidia https://nvidia.github.io/gpu-operator
helm repo update
```

2. Install the NVIDIA GPU Operator:
```
helm install --wait --generate-name \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator \
    --set "driver.enabled=true" \
    --set mig.strategy=mixed \
    --set migManager.enabled=true \
    --set migManager.WITH_REBOOT=true \
    --set operator.defaultRuntime=containerd \
    --set gfd.version=v0.17.0 \
    --set devicePlugin.version=v0.17.0 \
    --set migManager.default=all-balanced \
    --version=v24.9.2
``` 
The installation process will deploy all necessary resources, including the NVIDIA device plugin, drivers, and other utilities required for GPU workloads.

3. Verify the GPU Operator works fine
```
kubectl get pods -n nvidia-gpu-operator
kubectl describe daemonset gpu-operator -n nvidia-gpu-operator
kubectl logs -n nvidia-gpu-operator -l app=nvidia-gpu-operator
```
It may take a few moments for the GPU operator pod to reach the "ready" state.

## Set Up MIG partitions
MIG (Multi-Instance GPU) partitions are a feature of NVIDIA A100 and newer GPUs that allow a single physical GPU to be partitioned into multiple smaller, independent instances. Each of these instances (also referred to as "MIG devices") functions as a separate mini-GPU with dedicated memory and compute resources, offering better isolation and more efficient resource allocation.

To set up MIG (Multi-Instance GPU) partitions in Kubernetes using NVIDIA GPUs, you can choose between two strategies: **single strategy** and **mixed strategy**. Both approaches allow you to partition the GPU into smaller, isolated instances (MIG devices), but they differ in how these devices are allocated.

### Single Strategy vs. Mixed Strategy

1. **Single Strategy**:
- The single strategy creates MIG devices of the same size across all GPUs on a node. For example, on an A100 GPU, you could set up 56 slices of 1g.5gb, 24 slices of 2g.10gb, 16 slices of 3g.20gb, 8 slices of 4g.20gb, 1 slice of 7g.40gb
- The single strategy works best when you need uniform GPU power allocation for workloads that require similar resources.

2. **Mixed Strategy**:

- The mixed strategy allows for varying sizes of MIG devices across the GPUs on a node.
- This approach is particularly beneficial for handling workloads with different GPU demands. For example, the all-balanced profile divides the GPU into various sizes, such as 2 slices of 1g.10gb, 1 slice of 2g.20gb, 1 slice of 3g.40gb.
- This flexibility allows you to optimize GPU resource allocation based on the specific requirements of each task.


### Creating MIG Devices with the Single Strategy
In the single strategy, you can create MIG devices of the same size across all GPUs on a node. For instance, on a P4d.24XL instance, you might create 56 slices of 1g.5gb for multiple teams working on similar tasks, such as simulations and deep learning models.

To create MIG devices using the single strategy, follow these steps:

1. **Label the Node**: Label the node to use the desired MIG configuration. For example, to set up `1g.5gb` slices on all GPUs, use the following command (replace `$NODE` with your specific node name):

```
kubectl label nodes $NODE nvidia.com/mig.config=all-1g.5gb --overwrite
```

After labeling the node, it will display 56 MIG devices of size `1g.5gb`. Note that the `nvidia.com/gpu` label will show `0` because the GPUs are partitioned into MIG devices, and no full GPUs are available.

2. **Check the Node’s Status**: After applying the label, check the node's status to ensure the MIG devices are created correctly:

```
kubectl describe node $NODE
```

The output will show something like:

```
nvidia.com/gpu: 0
nvidia.com/mig-1g.5gb: 56
```

3. **Create a Deployment**: You can now create a deployment that uses the `1g.5gb` MIG devices. The following YAML configuration defines a deployment that uses one `1g.5gb` MIG device:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mig1.5
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mig1-5
  template:
    metadata:
      labels:
        app: mig1-5
    spec:
      containers:
      - name: vectoradd
        image: nvidia/cuda:8.0-runtime
        command: ["/bin/sh", "-c"]
        args: ["nvidia-smi && tail -f /dev/null"]
        resources:
          limits:
            nvidia.com/mig-1g.5gb: 1
```

4. **Deploy the Application**: Apply the deployment:

```
kubectl apply -f mig-1g-5gb-deployment.yaml
```

Check the status of the deployment:

```
kubectl get deployments.apps mig1.5
```

5. **Scale the Deployment**: If you scale the deployment to more replicas (e.g., 100), Kubernetes will only be able to run as many pods as there are MIG devices available on the node. For instance, if there are only 56 `1g.5gb` MIG devices available, only 56 pods will run:

```
kubectl scale deployment mig1.5 --replicas=10
```

### MIG Devices with the Mixed Strategy
The mixed strategy allows you to partition the GPUs into different sizes, creating flexibility in resource allocation. You can use predefined profiles (e.g., `all-balanced`) or define your own custom partitioning scheme.

1. **Use a Predefined Profile**: For example, the `all-balanced` profile divides the GPU into various sizes.

To apply the `all-balanced` profile, label the node like this:

```
kubectl label nodes $NODE nvidia.com/mig.config=all-balanced --overwrite
```

2. **Check the Node's Status**: After labeling the node, inspect the node to see the new MIG devices:

```
kubectl describe node $NODE
```

The output will show something like:

```
nvidia.com/mig-1g.5gb: 16
nvidia.com/mig-2g.10gb: 8
nvidia.com/mig-3g.20gb: 8
```

3. **Create Deployments Using the Mixed Strategy**: You can now create deployments that utilize the various MIG devices. For example, you can create one deployment that uses a 2g.10gb MIG device and another that uses a 3g.20gb MIG device.

**Example YAML configuration**:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mig2-10
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mig2-10
  template:
    metadata:
      labels:
        app: mig2-10
    spec:
      containers:
      - name: vectoradd
        image: nvidia/cuda:8.0-runtime
        command: ["/bin/sh", "-c"]
        args: ["nvidia-smi && tail -f /dev/null"]
        resources:
          limits:
            nvidia.com/mig-2g.10gb: 1
```

Apply the configuration:

```
kubectl apply -f mig-2g-10gb-deployment.yaml
```

4. **Scale the Deployments**: You can scale these deployments based on the available MIG devices:

```
kubectl scale deployments mig1.5 mig2-10 mig3-20 --replicas=20
```

5. Clean Up

To clean up the resources and delete the cluster:

```
# Uninstall the GPU Operator
helm list -n gpu-operator
helm uninstall <RELEASE_NAME> -n gpu-operator

# Delete the EKS cluster
eksctl delete cluster <CLUSTER_NAME>
```

## Implementing GPU Slicing on EKS Clusters with Karpenter Autoscaler Running
Karpenter is a node autoscaler that automatically provisions new compute resources based on cluster needs.
By integrating Karpenter with GPU slicing, you can ensure that your cluster dynamically scales both the compute resources and the GPU resources, thereby optimizing resource allocation for GPU-based workloads.

### Prerequisites
Before implementing GPU slicing with Karpenter on EKS, ensure the following prerequisites are in place:
- All previously mentioned prerequisites
- Karpenter installed and configured to manage node provisioning
- NVIDIA GPU Operator installed, which can be set up using the same installation process as before.

### Configure Karpenter for GPU Slicing

To support GPU workloads and MIG (Multi-Instance GPU) devices, you need to configure both Karpenter and create NodePool and EC2NodeClass definitions.

1. **Modify NodePool Configuration**:

Create or modify the NodePool to ensure the nodes have adequate GPU resources:
```
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: gpu-nodepool
spec:
  template:
    metadata:
      labels:
        workload-type: gpu
        nvidia.com/mig.config: "all-balanced" 
    spec:
      nodeClassRef:
        name: gpu
        kind: EC2NodeClass
        group: karpenter.k8s.aws
      requirements:
        - key: "karpenter.k8s.aws/instance-family"
          operator: In
          values: ["g5", "p3"]
        - key: "karpenter.k8s.aws/instance-size"
          operator: In
          values: ["g5.xlarge", "g5.2xlarge", "g5.4xlarge", "p3.2xlarge", "p3.8xlarge"]
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand"]
        - key: "nvidia.com/gpu"
          operator: Exists
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"] 
  limits:
    cpu: 32  
    memory: 128Gi  
    "nvidia.com/gpu": 1 
    "nvidia.com/mig-1g.10gb": 2
    "nvidia.com/mig-2g.20gb": 1
    "nvidia.com/mig-3g.40gb": 1 
```

2. **Modify EC2NodeClass Configuration**:

Modify the EC2NodeClass to define the instance configuration for your GPU nodes:
```
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: gpu
spec:
  amiFamily: Custom # Use "Custom" for non-standard AMIs
  amiSelectorTerms:
    - id: ami-0737727bbd00872fe # NVIDIA GPU-Optimized AMI
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: opsfleet-cluster
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: opsfleet-cluster
  instanceProfile: KarpenterNodeInstanceProfile-opsfleet-cluster
  blockDeviceMappings:
  - deviceName: /dev/xvda
    ebs:
      volumeSize: "50Gi"
      volumeType: gp3
      encrypted: true
      deleteOnTermination: true
```

3. **Apply Configurations**:

Apply the updated NodePool and EC2NodeClass configurations:

```
kubectl apply -f gpu-nodepool.yaml
kubectl apply -f gpu-ec2nodeclass.yaml
```

### Testing GPU Slicing
After configuring Karpenter, test by deploying GPU workloads that request fractional GPUs.

1. **Deploy a Test Workload**:

Deploy a test workload that requests a fractional GPU slice:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gpu-test
spec:
  replicas: 1
  selector:
    matchLabels:
      workload-type: gpu
  template:
    metadata:
      labels:
        workload-type: gpu
    spec:
      nodeSelector:
        workload-type: gpu
        nvidia.com/mig.config: "all-balanced"
      tolerations:
        - key: "nvidia.com/gpu"
          operator: "Exists"
          effect: "NoSchedule"
      containers:
      - name: cuda-vectoradd
        image: "nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda11.7.1-ubuntu20.04"
        command: ["sleep", "infinity"]
        resources:
          limits:
            nvidia.com/mig-1g.10gb: 1
            cpu: "2"
            memory: "8Gi"
          requests:
            nvidia.com/mig-1g.10gb: 1
            cpu: "1"
            memory: "4Gi"
```

**Apply the workload**:

```
kubectl apply -f gpu-test-workload.yaml
```

**Verify GPU usage by checking node and pod allocation**:

```
kubectl get nodes -o custom-columns="NODE:.metadata.name,MIG-1G:.status.allocatable.nvidia.com/mig-1g.10gb,MIG-2G:.status.allocatable.nvidia.com/mig-2g.20gb,MIG-3G:.status.allocatable.nvidia.com/mig-3g.40gb"

kubectl top pods -n gpu-workloads
```

4. **Scaling**:

Karpenter automatically scales the cluster based on MIG device availability. If existing nodes cannot fulfill the pod’s GPU request, Karpenter will provision new nodes with the required GPU slices.


## Conclusion
GPU slicing in EKS with Karpenter allows efficient GPU utilization, reducing costs. By configuring MIG and workloads accordingly, GPU efficiency is maximized, while Karpenter ensures dynamic scaling to meet workload demands.