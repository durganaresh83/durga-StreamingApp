#####################################################################
# Configure AWS Credentials for Jenkins - V2 (Simplified)
# This script SSHs into EC2 and runs the setup script
#####################################################################

param(
    [Parameter(Mandatory=$true)]
    [string]$AwsAccessKey,
    
    [Parameter(Mandatory=$true)]
    [string]$AwsSecretKey,
    
    [Parameter(Mandatory=$false)]
    [string]$EC2PublicIP = "3.10.208.103",
    
    [Parameter(Mandatory=$false)]
    [string]$PemKeyPath = "durga-windows.pem"
)

$ErrorActionPreference = "Stop"

$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow
$Red = [System.ConsoleColor]::Red
$Cyan = [System.ConsoleColor]::Cyan

function Write-ColorOutput {
    param([string]$Message, [System.ConsoleColor]$Color = $Green)
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════════╗" $Cyan
    Write-ColorOutput "║     Configuring AWS Credentials for Jenkins on EC2                 ║" $Cyan
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════════╝`n" $Cyan

    # Verify PEM file
    Write-ColorOutput "Step 1: Verifying PEM key file..." $Yellow
    if (-not (Test-Path $PemKeyPath)) {
        Write-ColorOutput "✗ PEM file not found: $PemKeyPath" $Red
        exit 1
    }
    Write-ColorOutput "✓ PEM file found" $Green

    $SSHOptions = "-i", $PemKeyPath, "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"

    # Upload setup script
    Write-ColorOutput "`nStep 2: Uploading setup script to EC2..." $Yellow
    $setupScript = "setup-jenkins-aws-credentials.sh"
    if (-not (Test-Path $setupScript)) {
        Write-ColorOutput "✗ Setup script not found: $setupScript" $Red
        exit 1
    }
    
    ssh $SSHOptions "ec2-user@$EC2PublicIP" "mkdir -p /tmp" | Out-Null
    scp $SSHOptions $setupScript "ec2-user@${EC2PublicIP}:/tmp/" | Out-Null
    Write-ColorOutput "✓ Setup script uploaded" $Green

    # Run setup script
    Write-ColorOutput "`nStep 3: Running AWS configuration script on EC2..." $Yellow
    Write-ColorOutput "  This will create credential files and restart Jenkins" $Yellow
    
    $output = ssh $SSHOptions "ec2-user@$EC2PublicIP" "bash /tmp/$setupScript '$AwsAccessKey' '$AwsSecretKey'" 2>&1
    
    Write-Host $output
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "`n✓ AWS credentials configured successfully" $Green
    } else {
        Write-ColorOutput "`n✗ Configuration failed with exit code: $LASTEXITCODE" $Red
        exit 1
    }

    # Step 4: Wait for Jenkins to restart
    Write-ColorOutput "`nStep 4: Waiting for Jenkins to fully restart..." $Yellow
    Write-ColorOutput "  This may take 60 seconds..." $Yellow
    
    $maxAttempts = 30
    $attempt = 0
    $jenkinsReady = $false
    
    while ($attempt -lt $maxAttempts) {
        $attempt++
        try {
            $response = Invoke-WebRequest -Uri "http://$EC2PublicIP:8080" -Method Head -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $jenkinsReady = $true
                break
            }
        } catch {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 2
        }
    }

    if ($jenkinsReady) {
        Write-ColorOutput "`n✓ Jenkins is running and ready" $Green
    } else {
        Write-ColorOutput "`n⚠ Jenkins may still be starting, but proceeding anyway" $Yellow
    }

    # Summary
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════════╗" $Cyan
    Write-ColorOutput "║                  ✅ SETUP COMPLETE                                 ║" $Cyan
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════════╝" $Cyan

    Write-ColorOutput "`n✓ AWS Credentials Configured:" $Green
    Write-ColorOutput "  • /var/lib/jenkins/.aws/credentials" $Green
    Write-ColorOutput "  • /var/lib/jenkins/.aws/config" $Green
    Write-ColorOutput "  • Jenkins service restarted" $Green

    Write-ColorOutput "`n📋 NEXT STEPS:" $Yellow
    Write-ColorOutput "  1. Push a test commit to develop branch:" $Yellow
    Write-ColorOutput "     git add . && git commit -m 'test: trigger build' && git push origin develop" $Cyan
    Write-ColorOutput "  2. Watch the build at:" $Yellow
    Write-ColorOutput "     http://$EC2PublicIP:8080/job/durga-streaming-app/job/develop/" $Cyan
    Write-ColorOutput "  3. Build should now succeed!" $Yellow

    Write-ColorOutput "`n⏱️  EXPECTED TIME:" $Yellow
    Write-ColorOutput "  First build: 10-15 minutes" $Yellow
    Write-ColorOutput "  Subsequent builds: 2-5 minutes (with Docker cache)" $Yellow

} catch {
    Write-ColorOutput "`n✗ Error: $_" $Red
    exit 1
}
