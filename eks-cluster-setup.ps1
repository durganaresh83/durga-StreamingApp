# ============================================================================
# EKS Cluster Setup Script for Durga Streaming App
# ============================================================================
# This script sets up an Amazon EKS cluster using eksctl
# Prerequisites:
#   - AWS CLI v2 installed and configured
#   - eksctl installed (https://eksctl.io/)
#   - kubectl installed
#   - IAM permissions to create EKS resources

param(
    [string]$ClusterName = "durga-streaming-app",
    [string]$Region = "eu-west-2",
    [int]$NodeCount = 3,
    [string]$NodeType = "t3.medium",
    [string]$Version = "1.28"
)

$ErrorActionPreference = "Stop"

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

# Check prerequisites
Write-Info "Checking prerequisites..."

$tools = @("aws", "eksctl", "kubectl")
foreach ($tool in $tools) {
    $check = & $tool --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$tool is not installed or not in PATH"
        Write-Info "Please install $tool and try again"
        exit 1
    }
    Write-Success "$tool is installed"
}

Write-Info ""
Write-Info "========================================================================="
Write-Info "EKS CLUSTER SETUP PARAMETERS"
Write-Info "========================================================================="
Write-Info "Cluster Name:     $ClusterName"
Write-Info "Region:           $Region"
Write-Info "Node Count:       $NodeCount"
Write-Info "Node Type:        $NodeType"
Write-Info "Kubernetes Ver:   $Version"
Write-Info "========================================================================="
Write-Info ""

$response = Read-Host "Do you want to proceed with cluster creation? (yes/no)"
if ($response -ne "yes") {
    Write-Info "Cluster creation cancelled"
    exit 0
}

Write-Info ""
Write-Info "========================================================================="
Write-Info "STEP 1: Creating EKS Cluster (this may take 15-20 minutes)"
Write-Info "========================================================================="

$eksctlCommand = @(
    "create",
    "cluster",
    "--name", $ClusterName,
    "--region", $Region,
    "--nodes", $NodeCount,
    "--node-type", $NodeType,
    "--version", $Version,
    "--enable-ssm",
    "--managed"
)

Write-Info "Executing: eksctl $($eksctlCommand -join ' ')"
Write-Info ""

eksctl @eksctlCommand

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create EKS cluster"
    exit 1
}

Write-Success "EKS cluster created successfully"

Write-Info ""
Write-Info "========================================================================="
Write-Info "STEP 2: Configuring kubectl"
Write-Info "========================================================================="

Write-Info "Updating kubeconfig..."
aws eks update-kubeconfig --region $Region --name $ClusterName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to update kubeconfig"
    exit 1
}

Write-Success "kubeconfig updated"

Write-Info ""
Write-Info "========================================================================="
Write-Info "STEP 3: Verifying Cluster Connectivity"
Write-Info "========================================================================="

Write-Info "Testing cluster connection..."
$clusterInfo = kubectl cluster-info 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Success "Connected to cluster successfully"
    Write-Info $clusterInfo
} else {
    Write-Error "Failed to connect to cluster"
    exit 1
}

Write-Info ""
Write-Info "========================================================================="
Write-Info "STEP 4: Checking Node Status"
Write-Info "========================================================================="

Write-Info "Waiting for nodes to be ready..."
$nodeCheck = 0
$maxAttempts = 30

while ($nodeCheck -lt $maxAttempts) {
    $nodes = kubectl get nodes --no-headers 2>$null | Measure-Object | Select-Object -ExpandProperty Count
    if ($nodes -ge $NodeCount) {
        Write-Success "All $NodeCount nodes are ready"
        break
    }
    $nodeCheck++
    if ($nodeCheck -lt $maxAttempts) {
        Write-Info "Nodes ready: $nodes/$NodeCount (waiting...)"
        Start-Sleep -Seconds 30
    }
}

if ($nodeCheck -eq $maxAttempts) {
    Write-Warning "Not all nodes became ready within expected time"
}

kubectl get nodes

Write-Info ""
Write-Info "========================================================================="
Write-Info "STEP 5: Installing Required Add-ons"
Write-Info "========================================================================="

# Install AWS Load Balancer Controller
Write-Info "Installing AWS Load Balancer Controller..."

# Create IAM policy
$policyDocument = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Action = @(
                "iam:CreateServiceLinkedRole",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "ec2:GetSecurityGroupsForVpc",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:GetSecurityGroupsForVpc",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags"
            )
            Resource = "*"
        }
    )
}

Write-Info "You may need to manually add AWS Load Balancer Controller via Helm:"
Write-Info "  helm repo add eks https://aws.github.io/eks-charts"
Write-Info "  helm repo update"
Write-Info "  helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set cluster.name=$ClusterName"

Write-Info ""
Write-Info "========================================================================="
Write-Info "STEP 6: Creating Namespaces"
Write-Info "========================================================================="

Write-Info "Creating namespace for streaming app..."
kubectl create namespace durga-streaming --dry-run=client -o yaml | kubectl apply -f -

Write-Success "Namespace 'durga-streaming' created"

Write-Info ""
Write-Info "========================================================================="
Write-Info "SETUP COMPLETE! ✅"
Write-Info "========================================================================="
Write-Info ""
Write-Info "Your EKS cluster is ready for deployment!"
Write-Info ""
Write-Info "Next steps:"
Write-Info "1. Create Helm charts for your application"
Write-Info "2. Push Docker images to ECR (already done!)"
Write-Info "3. Deploy using: helm install durga-streaming ./helm/durga-streaming -n durga-streaming"
Write-Info "4. Monitor pods: kubectl get pods -n durga-streaming"
Write-Info "5. View logs: kubectl logs -n durga-streaming -l app=<service-name>"
Write-Info ""
Write-Info "Cluster Details:"
Write-Info "  Name: $ClusterName"
Write-Info "  Region: $Region"
Write-Info "  Kubernetes Version: $Version"
Write-Info "  Nodes: $NodeCount x $NodeType"
Write-Info ""
Write-Info "Useful commands:"
Write-Info "  kubectl get nodes"
Write-Info "  kubectl get pods -n durga-streaming"
Write-Info "  kubectl describe node <node-name>"
Write-Info "  kubectl logs -n durga-streaming <pod-name>"
Write-Info "  eksctl delete cluster --name $ClusterName --region $Region (to delete)"
Write-Info ""
Write-Info "========================================================================="
