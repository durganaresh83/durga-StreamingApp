# Resume EKS Setup - January 24, 2026

## Current Status
- ✅ AWS CLI v2 installed (2.33.5)
- ✅ eksctl installed (0.221.0)
- ✅ kubectl installed (v1.34.3)
- ✅ Helm installed (v4.1.0)
- ✅ AWS credentials configured
- ⚠️ Failed CloudFormation stack needs cleanup

## Issue from Yesterday
A CloudFormation stack `eksctl-durga-streaming-app-cluster` has TerminationProtection enabled and is in a failed state. This needs to be cleaned up before creating a new cluster.

## Step-by-Step Resume Instructions

### Step 1: Clean Up Failed CloudFormation Stack

Open PowerShell and run:

```powershell
cd "C:\Durga Naresh\HeroVired\Assignments\durga-StreamingApp"

# Disable termination protection
aws cloudformation update-stack-set --stack-set-name eksctl-durga-streaming-app-cluster --region eu-west-2 --parameters ParameterOverrides='{TerminationProtection=false}' 2>&1 | Out-Null

# Or directly delete with force flag
aws cloudformation delete-stack --stack-name eksctl-durga-streaming-app-cluster --region eu-west-2 --force-delete 2>&1 | Out-Null

# Verify deletion (wait 1-2 minutes)
Start-Sleep -Seconds 120

# Check if deleted
aws cloudformation describe-stacks --stack-name eksctl-durga-streaming-app-cluster --region eu-west-2 2>&1 | Out-Null
```

If the stack still exists, try listing all stacks:

```powershell
aws cloudformation list-stacks --region eu-west-2 --query 'StackSummaries[?contains(StackName, `durga-streaming-app`)]'
```

### Step 2: Create Fresh EKS Cluster

Once the stack is deleted, create a new cluster:

```powershell
$eksctlPath = "C:\ProgramData\chocolatey\lib\eksctl\tools\eksctl.exe"

Write-Host "Creating EKS cluster 'durga-streaming-app' in eu-west-2..." -ForegroundColor Cyan
Write-Host "This will take 15-20 minutes. Keep this terminal open." -ForegroundColor Yellow

& $eksctlPath create cluster `
  --name durga-streaming-app `
  --region eu-west-2 `
  --nodegroup-name standard-nodes `
  --nodes 3 `
  --node-type t3.medium `
  --version 1.30 `
  --managed `
  --with-oidc
```

**Expected Output:**
- Cluster creation begins
- Progress messages appear every 30-60 seconds
- After 15-20 minutes: "✅ EKS cluster creation completed"
- kubeconfig automatically updated

### Step 3: Verify Cluster Creation

Once complete, verify the cluster:

```powershell
# Check nodes
kubectl get nodes

# Check cluster info
kubectl cluster-info

# Check pods in kube-system
kubectl get pods -n kube-system
```

**Expected Output:**
```
NAME                                        STATUS   ROLES    AGE
ip-192-168-xx-xx.eu-west-2.compute.internal Ready    <none>   2m
ip-192-168-xx-xx.eu-west-2.compute.internal Ready    <none>   2m
ip-192-168-xx-xx.eu-west-2.compute.internal Ready    <none>   2m
```

### Step 4: Create Kubernetes Namespace & Secrets

```powershell
# Create namespace
kubectl create namespace durga-streaming

# Create MongoDB secret (change password!)
kubectl create secret generic mongodb-secret `
  -n durga-streaming `
  --from-literal=root-password='ChangeMe123!@#'

# Create app secrets (use your actual AWS credentials)
kubectl create secret generic aws-credentials `
  -n durga-streaming `
  --from-literal=AWS_ACCESS_KEY_ID='AKIA...' `
  --from-literal=AWS_SECRET_ACCESS_KEY='...'

# Verify secrets created
kubectl get secrets -n durga-streaming
```

### Step 5: Deploy Application with Helm

```powershell
cd "C:\Durga Naresh\HeroVired\Assignments\durga-StreamingApp"

# Validate Helm chart
helm lint ./helm/durga-streaming

# Deploy application
helm install durga-streaming ./helm/durga-streaming `
  -n durga-streaming `
  --wait

# Or use the deployment script
bash deploy-to-eks.sh
```

### Step 6: Monitor Deployment

```powershell
# Watch pods being created
kubectl get pods -n durga-streaming -w

# Once running, get service info
kubectl get svc -n durga-streaming

# Get ingress/ALB URL
kubectl get ingress -n durga-streaming
```

## Troubleshooting

### If Stack Deletion Fails
```powershell
# List all stacks
aws cloudformation list-stacks --region eu-west-2

# Manually delete with AWS Console or:
aws cloudformation delete-stack --stack-name eksctl-durga-streaming-app-cluster --region eu-west-2 --no-cli-pager
```

### If Cluster Creation Fails
```powershell
# Check CloudFormation status
aws cloudformation describe-stacks --stack-name eksctl-durga-streaming-app-cluster --region eu-west-2

# Check for error events
aws cloudformation describe-stack-events --stack-name eksctl-durga-streaming-app-cluster --region eu-west-2 | ConvertFrom-Json
```

### If kubectl commands fail
```powershell
# Update kubeconfig
aws eks update-kubeconfig --name durga-streaming-app --region eu-west-2

# Verify credentials
aws sts get-caller-identity
```

## Important Notes

- ✅ All prerequisites are installed (AWS CLI, eksctl, kubectl, Helm)
- ✅ AWS credentials are configured
- ✅ Helm charts are ready at `./helm/durga-streaming`
- ✅ Docker images are in ECR (975050024946.dkr.ecr.eu-west-2.amazonaws.com)
- ⏱️ EKS cluster creation takes 15-20 minutes - plan accordingly
- 💰 Cost: ~$73/month for EKS + ~$35/month for nodes

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│         AWS Region: eu-west-2 (London)              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │    EKS Control Plane (Managed by AWS)        │  │
│  │  ✓ API Server   ✓ Scheduler                   │  │
│  │  ✓ etcd        ✓ Controller Manager          │  │
│  └───────────────────────────────────────────────┘  │
│                        │                            │
│         ┌──────────────┼──────────────┐            │
│         │              │              │            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │
│  │ Worker Node │ │ Worker Node │ │ Worker Node │  │
│  │ (t3.medium) │ │ (t3.medium) │ │ (t3.medium) │  │
│  │             │ │             │ │             │  │
│  │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │  │
│  │ │ Pods    │ │ │ │ Pods    │ │ │ │ Pods    │ │  │
│  │ │ (App)   │ │ │ │ (App)   │ │ │ │ (App)   │ │  │
│  │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │  │
│  └─────────────┘ └─────────────┘ └─────────────┘  │
│         │              │              │            │
│         └──────────────┼──────────────┘            │
│                        │                            │
│         ┌──────────────▼──────────────┐            │
│         │   AWS Application           │            │
│         │   Load Balancer (ALB)       │            │
│         └──────────────┬──────────────┘            │
│                        │                            │
└────────────────────────┼────────────────────────────┘
                         │
                    ┌────▼────┐
                    │ Internet │
                    └──────────┘
```

## Commands Summary

| Command | Purpose |
|---------|---------|
| `eksctl create cluster ...` | Create EKS cluster |
| `kubectl get nodes` | List worker nodes |
| `kubectl get pods -A` | List all pods |
| `helm install ...` | Deploy application |
| `kubectl logs <pod>` | View pod logs |
| `kubectl port-forward ...` | Forward local port to pod |

## Next Steps After Deployment

1. ✅ Get ALB URL and configure DNS
2. ✅ Test application endpoints
3. ✅ Set up monitoring (Prometheus/Grafana)
4. ✅ Configure auto-scaling policies
5. ✅ Set up CI/CD integration with Jenkins

---

**Ready to continue tomorrow?** Follow the steps above in order, starting with Step 1: Clean Up Failed CloudFormation Stack.

Good luck! 🚀
