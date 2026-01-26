#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy EKS cluster using existing default VPC (no new VPC/IGW creation)

.DESCRIPTION
This script creates an EKS cluster in the existing VPC, avoiding AWS quota limits
on VPC and Internet Gateway creation.

.PARAMETER ConfigFile
Path to the EKS cluster configuration file (default: eks-cluster-existing-vpc.yaml)

.PARAMETER Region
AWS region (default: eu-west-2)

.EXAMPLE
.\deploy-eks-existing-vpc.ps1
#>

param(
    [string]$ConfigFile = "eks-cluster-existing-vpc.yaml",
    [string]$Region = "eu-west-2"
)

$eksctlPath = "C:\ProgramData\chocolatey\lib\eksctl\tools\eksctl.exe"

Write-Host @"
════════════════════════════════════════════════════════════════════════════════
🚀 EKS CLUSTER DEPLOYMENT - USING EXISTING VPC
════════════════════════════════════════════════════════════════════════════════

Configuration:
  • File: $ConfigFile
  • Region: $Region
  • VPC: vpc-0376ebe6043cd8004 (existing default VPC - 172.31.0.0/16)
  • Subnets: 3 (across eu-west-2a, eu-west-2b, eu-west-2c)
  • Nodes: 3 x t3.medium
  • Time Estimate: 15-20 minutes

Advantage: No new VPC/IGW creation = No quota limits hit!

════════════════════════════════════════════════════════════════════════════════
"@ -ForegroundColor Cyan

# Verify config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Host "❌ Error: Config file not found: $ConfigFile" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Verifying AWS credentials..." -ForegroundColor Yellow
$identity = aws sts get-caller-identity --region $Region 2>&1 | ConvertFrom-Json
Write-Host "✓ AWS Account: $($identity.Account)" -ForegroundColor Green
Write-Host "✓ User: $($identity.Arn)`n" -ForegroundColor Green

Write-Host "Step 2: Verifying existing VPC and subnets..." -ForegroundColor Yellow
$vpc = aws ec2 describe-vpcs --vpc-ids vpc-0376ebe6043cd8004 --region $Region --query 'Vpcs[0]' 2>&1 | ConvertFrom-Json
Write-Host "✓ VPC: $($vpc.VpcId) - $($vpc.CidrBlock)" -ForegroundColor Green

$subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0376ebe6043cd8004" --region $Region --query 'Subnets[*].{Id:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}' 2>&1 | ConvertFrom-Json
foreach ($subnet in $subnets) {
    Write-Host "✓ Subnet: $($subnet.Id) - $($subnet.CIDR) ($($subnet.AZ))" -ForegroundColor Green
}

Write-Host "`nStep 3: Creating EKS cluster with existing VPC..." -ForegroundColor Yellow
Write-Host "This will take 15-20 minutes. Do not close this terminal.`n" -ForegroundColor Cyan

$logFile = "eks-cluster-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

& $eksctlPath create cluster -f $ConfigFile --region $Region 2>&1 | Tee-Object -FilePath $logFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ EKS CLUSTER CREATED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "`nCluster name: durga-streaming-app" -ForegroundColor Cyan
    Write-Host "Region: $Region" -ForegroundColor Cyan
    Write-Host "VPC: vpc-0376ebe6043cd8004 (existing)" -ForegroundColor Cyan
    Write-Host "`nVerifying cluster..." -ForegroundColor Yellow
    kubectl cluster-info
    Write-Host "`nNodes:" -ForegroundColor Cyan
    kubectl get nodes
} else {
    Write-Host "`n❌ Cluster creation failed. Check log: $logFile" -ForegroundColor Red
    exit 1
}

Write-Host "`n════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ NEXT STEPS:" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "
1. Create namespace:
   kubectl create namespace durga-streaming

2. Create secrets:
   kubectl create secret generic mongodb-secret -n durga-streaming \\
     --from-literal=root-password='ChangeMe123!@#'

3. Deploy with Helm:
   helm install durga-streaming ./helm/durga-streaming -n durga-streaming

4. Get load balancer URL:
   kubectl get ingress -n durga-streaming
" -ForegroundColor Yellow

Write-Host "════════════════════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
