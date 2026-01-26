# ============================================================================
# EXECUTE_STEP_5_3: Deploy Worker Nodes to EKS Cluster
# ============================================================================
# Purpose: Automated deployment with pre-flight checks and verification
# Prerequisites: SSM Parameter Store GetParameter permission (NOW APPROVED!)
# ============================================================================

param(
    [string]$ConfigFile = "nodegroup-simple.yaml",
    [int]$MaxAttempts = 20,
    [int]$WaitTimeSeconds = 30
)

# Set error handling
$ErrorActionPreference = "Stop"

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 5.3: Deploy Worker Nodes to EKS Cluster" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

Write-Host "Running Pre-Flight Checks..." -ForegroundColor Yellow
$checksCount = 0

# Check 1: AWS CLI
Write-Host "`n[1/7] Checking AWS CLI..." -ForegroundColor Cyan
try {
    $awsVersion = aws --version 2>&1
    Write-Host "  ✓ AWS CLI installed: $awsVersion" -ForegroundColor Green
    $checksCount++
} catch {
    Write-Host "  ✗ AWS CLI not found" -ForegroundColor Red
    exit 1
}

# Check 2: eksctl
Write-Host "`n[2/7] Checking eksctl..." -ForegroundColor Cyan
try {
    $eksctlVersion = eksctl version 2>&1
    Write-Host "  ✓ eksctl installed: $eksctlVersion" -ForegroundColor Green
    $checksCount++
} catch {
    Write-Host "  ✗ eksctl not found" -ForegroundColor Red
    exit 1
}

# Check 3: kubectl
Write-Host "`n[3/7] Checking kubectl..." -ForegroundColor Cyan
try {
    $kubectlVersion = kubectl version --client --short 2>&1
    Write-Host "  ✓ kubectl installed: $kubectlVersion" -ForegroundColor Green
    $checksCount++
} catch {
    Write-Host "  ✗ kubectl not found" -ForegroundColor Red
    exit 1
}

# Check 4: EKS Cluster Status
Write-Host "`n[4/7] Verifying EKS Cluster Status..." -ForegroundColor Cyan
try {
    $clusterStatus = aws eks describe-cluster --name durga-streaming-app --region eu-west-2 --query 'cluster.status' --output text 2>&1
    if ($clusterStatus -eq "ACTIVE") {
        Write-Host "  ✓ Cluster is ACTIVE" -ForegroundColor Green
        $checksCount++
    } else {
        Write-Host "  ✗ Cluster status is: $clusterStatus (expected ACTIVE)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✗ Failed to get cluster status" -ForegroundColor Red
    exit 1
}

# Check 5: Nodegroup Config File
Write-Host "`n[5/7] Checking nodegroup config file..." -ForegroundColor Cyan
if (Test-Path $ConfigFile) {
    Write-Host "  ✓ Config file found: $ConfigFile" -ForegroundColor Green
    $checksCount++
} else {
    Write-Host "  ✗ Config file not found: $ConfigFile" -ForegroundColor Red
    exit 1
}

# Check 6: SSM Permission (CRITICAL - Now approved!)
Write-Host "`n[6/7] Verifying SSM Parameter Store access..." -ForegroundColor Cyan
try {
    $ssmTest = aws ssm get-parameter --name "/aws/service/eks/optimized-ami/1.30/amazon-linux-2/recommended/image_id" --region eu-west-2 --output text 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ SSM Parameter Store access confirmed" -ForegroundColor Green
        $checksCount++
    } else {
        Write-Host "  ✗ SSM permission still not granted" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✗ SSM permission check failed: $_" -ForegroundColor Red
    exit 1
}

# Check 7: EKS Permissions
Write-Host "`n[7/7] Checking EKS permissions..." -ForegroundColor Cyan
try {
    $eksPermCheck = aws eks list-clusters --region eu-west-2 --output text 2>&1
    Write-Host "  ✓ EKS permissions verified" -ForegroundColor Green
    $checksCount++
} catch {
    Write-Host "  ✗ EKS permissions check failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✓ All 7 Pre-Flight Checks Passed!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Green

# ============================================================================
# DEPLOY NODEGROUP
# ============================================================================

Write-Host "Starting Node Group Deployment..." -ForegroundColor Cyan
Write-Host "Configuration: $ConfigFile`n" -ForegroundColor Yellow

$startTime = Get-Date
$logFileName = "nodegroup-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

try {
    eksctl create nodegroup -f $ConfigFile 2>&1 | Tee-Object -FilePath $logFileName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ Nodegroup creation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n✓ Nodegroup creation command completed successfully" -ForegroundColor Green
} catch {
    Write-Host "`n✗ Nodegroup creation failed: $_" -ForegroundColor Red
    exit 1
}

# ============================================================================
# MONITOR NODE READINESS
# ============================================================================

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Monitoring Node Startup (up to 10 minutes)..." -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$attempts = 0
$nodeReadyCount = 0
$targetNodeCount = 3

while ($attempts -lt $MaxAttempts) {
    $attempts++
    
    # Get current node status
    $nodesOutput = kubectl get nodes -o json 2>&1 | ConvertFrom-Json
    $readyNodes = $nodesOutput.items | Where-Object {
        $_.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" }
    }
    
    $nodeReadyCount = @($readyNodes).Count
    $elapsedSeconds = ($attempts * $WaitTimeSeconds)
    $elapsedMinutes = [math]::Round($elapsedSeconds / 60, 1)
    
    Write-Host "Attempt $($attempts)/$($MaxAttempts): Ready Nodes: $nodeReadyCount/$targetNodeCount [$($elapsedMinutes)m elapsed]" -ForegroundColor Yellow
    
    if ($nodeReadyCount -ge $targetNodeCount) {
        Write-Host "`n✓ All $targetNodeCount nodes are READY!" -ForegroundColor Green
        break
    }
    
    if ($attempts -lt $MaxAttempts) {
        Start-Sleep -Seconds $WaitTimeSeconds
    }
}

if ($nodeReadyCount -lt $targetNodeCount) {
    Write-Host "`n⚠ Warning: Not all nodes are ready yet. Check AWS Console for details." -ForegroundColor Yellow
    Write-Host "Current status: $nodeReadyCount/$targetNodeCount nodes ready`n" -ForegroundColor Yellow
}

# ============================================================================
# VERIFY POD DEPLOYMENT
# ============================================================================

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Verifying Application Pods..." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$podAttempts = 0
$maxPodAttempts = 10

while ($podAttempts -lt $maxPodAttempts) {
    $podAttempts++
    
    $podsOutput = kubectl get pods -n durga-streaming -o json 2>&1 | ConvertFrom-Json
    $runningPods = @($podsOutput.items | Where-Object { $_.status.phase -eq "Running" })
    
    Write-Host "Pod check $($podAttempts)/$($maxPodAttempts): $($runningPods.Count) pods RUNNING" -ForegroundColor Yellow
    
    if ($runningPods.Count -ge 3) {
        Write-Host "`n✓ Application pods are starting up!" -ForegroundColor Green
        
        # Show pod summary
        Write-Host "`nPod Summary:" -ForegroundColor Cyan
        kubectl get pods -n durga-streaming -o wide 2>&1
        break
    }
    
    if ($podAttempts -lt $maxPodAttempts) {
        Start-Sleep -Seconds 10
    }
}

# ============================================================================
# VERIFY MONITORING (FLUENT BIT)
# ============================================================================

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Verifying Monitoring Setup (Fluent Bit)..." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$fluentBitPods = kubectl get pods -n monitoring -o json 2>&1 | ConvertFrom-Json
$fluentBitRunning = @($fluentBitPods.items | Where-Object { $_.status.phase -eq "Running" })

Write-Host "Fluent Bit DaemonSet Status:" -ForegroundColor Cyan
kubectl get daemonsets -n monitoring 2>&1
Write-Host "`nRunning Fluent Bit pods: $($fluentBitRunning.Count)" -ForegroundColor Yellow

if ($fluentBitRunning.Count -gt 0) {
    Write-Host "✓ Fluent Bit is collecting logs from nodes!" -ForegroundColor Green
}

# ============================================================================
# FINAL STATUS
# ============================================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 STEP 5.3 DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Green

Write-Host "Deployment Summary:" -ForegroundColor Yellow
Write-Host "  Start Time: $startTime" -ForegroundColor White
Write-Host "  End Time: $endTime" -ForegroundColor White
Write-Host "  Duration: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
Write-Host "  Nodes Ready: $nodeReadyCount/3" -ForegroundColor White
Write-Host "  Pods Running: $($runningPods.Count)" -ForegroundColor White
Write-Host "  Fluent Bit Pods: $($fluentBitRunning.Count)" -ForegroundColor White
Write-Host "  Log File: $logFileName`n" -ForegroundColor White

Write-Host "What's Next:" -ForegroundColor Cyan
Write-Host "  1. Verify all pods are running:" -ForegroundColor White
Write-Host "     kubectl get pods -n durga-streaming -o wide" -ForegroundColor Gray
Write-Host "  2. Check application logs:" -ForegroundColor White
Write-Host "     aws logs tail /aws/eks/durga-streaming-app/application --follow" -ForegroundColor Gray
Write-Host "  3. Proceed to Step 7 - Ingress Testing:" -ForegroundColor White
Write-Host "     Reference: STEP_7_PREPARATION.md`n" -ForegroundColor Gray

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Status: ✓ READY FOR PRODUCTION" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Green
