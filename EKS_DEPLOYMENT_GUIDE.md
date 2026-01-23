# Kubernetes Deployment Guide for Durga Streaming App

This guide covers deploying the Durga Streaming MERN application to AWS EKS using Helm.

## Prerequisites

Before starting, ensure you have:

1. **AWS Account** with appropriate IAM permissions
2. **AWS CLI v2** installed and configured
3. **eksctl** installed (https://eksctl.io/)
4. **kubectl** installed
5. **Helm 3** installed
6. **Docker images** already pushed to ECR (via Jenkins CI/CD)

## Installation Instructions

### Step 1: Install Required Tools

#### On Windows (PowerShell):

```powershell
# Install AWS CLI v2
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Install eksctl
choco install eksctl

# Install kubectl
choco install kubernetes-cli

# Install Helm
choco install kubernetes-helm
```

#### On macOS:

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Install eksctl
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Install kubectl
brew install kubectl

# Install Helm
brew install helm
```

#### On Linux:

```bash
# AWS CLI v2
curl "https://awscli.amazonaws.com/awscliv2.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Step 2: Create EKS Cluster

#### Option A: Using PowerShell Script (Windows)

```powershell
cd <path-to-repo>
.\eks-cluster-setup.ps1 -ClusterName "durga-streaming-app" -Region "eu-west-2" -NodeCount 3 -NodeType "t3.medium"
```

#### Option B: Manual Setup with eksctl

```bash
eksctl create cluster \
  --name durga-streaming-app \
  --region eu-west-2 \
  --nodes 3 \
  --node-type t3.medium \
  --version 1.28 \
  --enable-ssm \
  --managed
```

**This will take 15-20 minutes. Be patient!**

### Step 3: Verify Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-2 --name durga-streaming-app

# Verify cluster connectivity
kubectl cluster-info

# Check nodes
kubectl get nodes

# Expected output:
# NAME                                           STATUS   ROLES    AGE     VERSION
# ip-192-168-XX-XX.eu-west-2.compute.internal   Ready    <none>   10m     v1.28.x
```

### Step 4: Install AWS Load Balancer Controller

```bash
# Add AWS EKS Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set cluster.name=durga-streaming-app \
  --set serviceAccount.create=true
```

### Step 5: Create Secrets for Application

```bash
# Create namespace
kubectl create namespace durga-streaming

# Create secrets for database and AWS credentials
kubectl create secret generic mongodb-secret \
  -n durga-streaming \
  --from-literal=root-password='changeme'

kubectl create secret generic app-secrets \
  -n durga-streaming \
  --from-literal=JWT_SECRET='your-jwt-secret-key' \
  --from-literal=AWS_ACCESS_KEY_ID='AKIA6GBMCU7ZOFFYUQNG' \
  --from-literal=AWS_SECRET_ACCESS_KEY='your-secret-key'
```

### Step 6: Deploy Application with Helm

```bash
# Navigate to helm chart directory
cd helm/durga-streaming

# Install Helm chart
helm install durga-streaming . \
  -n durga-streaming \
  --values values.yaml

# Verify deployment
kubectl get pods -n durga-streaming

# Expected output:
# NAME                              READY   STATUS    RESTARTS   AGE
# auth-service-xxx                  1/1     Running   0          2m
# streaming-service-xxx             1/1     Running   0          2m
# admin-service-xxx                 1/1     Running   0          2m
# chat-service-xxx                  1/1     Running   0          2m
# frontend-xxx                      1/1     Running   0          2m
# mongodb-xxx                       1/1     Running   0          2m
```

## Post-Deployment

### Check Service Status

```bash
# Check all services
kubectl get svc -n durga-streaming

# Check ingress
kubectl get ingress -n durga-streaming

# Describe ingress (get load balancer URL)
kubectl describe ingress durga-streaming-ingress -n durga-streaming
```

### View Logs

```bash
# View auth service logs
kubectl logs -n durga-streaming -l app=auth-service --tail=100 -f

# View all service logs
kubectl logs -n durga-streaming --all-containers=true --tail=50 -f
```

### Port Forward for Local Testing

```bash
# Forward frontend to localhost:3000
kubectl port-forward -n durga-streaming svc/frontend 3000:80

# Forward auth service to localhost:3001
kubectl port-forward -n durga-streaming svc/auth-service 3001:3001

# Forward streaming service to localhost:3002
kubectl port-forward -n durga-streaming svc/streaming-service 3002:3002
```

### Update Deployment

```bash
# After pushing new images to ECR
helm upgrade durga-streaming . \
  -n durga-streaming \
  --values values.yaml \
  --set authService.image.tag=latest
```

### Monitor Cluster Health

```bash
# Watch pods
kubectl get pods -n durga-streaming --watch

# Check resource usage
kubectl top nodes
kubectl top pods -n durga-streaming

# View events
kubectl get events -n durga-streaming --sort-by='.lastTimestamp'
```

## Troubleshooting

### Pods not starting?

```bash
# Check pod details
kubectl describe pod <pod-name> -n durga-streaming

# Check pod logs
kubectl logs <pod-name> -n durga-streaming

# Check events
kubectl get events -n durga-streaming
```

### Can't connect to database?

```bash
# Test MongoDB connectivity
kubectl run -it --rm debug --image=mongo:6 --restart=Never -n durga-streaming -- \
  mongo mongodb://mongodb:27017 --eval "db.adminCommand('ping')"
```

### Services not accessible?

```bash
# Check service endpoints
kubectl get endpoints -n durga-streaming

# Verify ingress configuration
kubectl get ingress -n durga-streaming -o yaml
```

## Cleanup

### Delete Application

```bash
# Delete Helm release
helm uninstall durga-streaming -n durga-streaming

# Delete namespace
kubectl delete namespace durga-streaming
```

### Delete EKS Cluster

```bash
# Delete cluster (takes 10-15 minutes)
eksctl delete cluster --name durga-streaming-app --region eu-west-2
```

## Cost Optimization Tips

1. **Use Spot Instances**: Add `--spot` flag when creating cluster to save 70% on compute
2. **Auto-scaling**: Enable Cluster Autoscaler or Karpenter for automatic scaling
3. **Right-sizing**: Adjust node types and pod resource requests/limits
4. **Scheduled Scaling**: Use scheduled scaling to stop clusters during off-hours
5. **Multi-region**: Distribute load across regions for better resilience

## Monitoring and Logging

### Install Prometheus and Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### Access Grafana Dashboard

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# Access at http://localhost:3000 (default: admin/prom-operator)
```

## Next Steps

1. Configure DNS and SSL certificates
2. Set up monitoring and alerting
3. Implement CI/CD integration with Jenkins
4. Set up log aggregation (ELK Stack, Datadog, etc.)
5. Configure backup and disaster recovery

## Support and Documentation

- EKS Documentation: https://docs.aws.amazon.com/eks/
- Kubernetes Documentation: https://kubernetes.io/docs/
- Helm Documentation: https://helm.sh/docs/
- eksctl Documentation: https://eksctl.io/

---

**Last Updated**: 2026-01-23
**Version**: 1.0.0
