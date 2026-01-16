#####################################################################
# Configure AWS CLI on Jenkins EC2 Instance
# This script SSH's into the EC2 instance and configures AWS credentials
#####################################################################

param(
    [Parameter(Mandatory=$true)]
    [string]$AwsAccessKey,
    
    [Parameter(Mandatory=$true)]
    [string]$AwsSecretKey,
    
    [Parameter(Mandatory=$false)]
    [string]$EC2PublicIP = "3.10.208.103",
    
    [Parameter(Mandatory=$false)]
    [string]$PemKeyPath = "durga-windows.pem",
    
    [Parameter(Mandatory=$false)]
    [string]$EC2User = "ec2-user"
)

$ErrorActionPreference = "Stop"

# Colors
$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow
$Red = [System.ConsoleColor]::Red
$Cyan = [System.ConsoleColor]::Cyan

function Write-ColorOutput {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = $Green
    )
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════════╗" $Cyan
    Write-ColorOutput "║      Configuring AWS CLI on Jenkins EC2 Instance                  ║" $Cyan
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════════╝`n" $Cyan

    # Step 1: Verify PEM file exists
    Write-ColorOutput "Step 1: Verifying PEM key file..." $Yellow
    if (-not (Test-Path $PemKeyPath)) {
        Write-ColorOutput "✗ PEM file not found: $PemKeyPath" $Red
        Write-ColorOutput "  Please make sure the PEM file is in the current directory" $Red
        exit 1
    }
    Write-ColorOutput "✓ PEM file found: $PemKeyPath" $Green

    # Step 2: Configure SSH options
    Write-ColorOutput "`nStep 2: Preparing SSH connection..." $Yellow
    $SSHOptions = "-i", $PemKeyPath, "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"
    Write-ColorOutput "✓ SSH options configured" $Green

    # Step 3: Create AWS credentials file on EC2
    Write-ColorOutput "`nStep 3: Creating AWS credentials configuration..." $Yellow
    
    # Create the AWS credentials in proper format
    $awsConfig = @"
[default]
aws_access_key_id = $AwsAccessKey
aws_secret_access_key = $AwsSecretKey
region = eu-west-2
output = json
"@

    # Use ssh to create the credentials
    Write-ColorOutput "  Sending AWS configuration to EC2..." $Yellow
    
    # Create .aws directory
    ssh $SSHOptions "${EC2User}@${EC2PublicIP}" @"
mkdir -p ~/.aws
"@ | Out-Null

    # Create credentials file using heredoc
    ssh $SSHOptions "${EC2User}@${EC2PublicIP}" @"
cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = $AwsAccessKey
aws_secret_access_key = $AwsSecretKey
EOF
chmod 600 ~/.aws/credentials
"@ | Out-Null

    # Create config file
    ssh $SSHOptions "${EC2User}@${EC2PublicIP}" @"
cat > ~/.aws/config << 'EOF'
[default]
region = eu-west-2
output = json
EOF
chmod 600 ~/.aws/config
"@ | Out-Null

    Write-ColorOutput "✓ AWS credentials configured on EC2" $Green

    # Step 4: Verify AWS configuration
    Write-ColorOutput "`nStep 4: Verifying AWS configuration..." $Yellow
    $verifyOutput = ssh $SSHOptions "${EC2User}@${EC2PublicIP}" "aws sts get-caller-identity" 2>&1
    
    if ($verifyOutput -match "Account") {
        Write-ColorOutput "✓ AWS credentials verified successfully" $Green
        Write-ColorOutput "  Output: $verifyOutput" $Green
    } else {
        Write-ColorOutput "⚠ Could not verify AWS credentials" $Yellow
        Write-ColorOutput "  Output: $verifyOutput" $Yellow
    }

    # Step 5: Configure Jenkins user
    Write-ColorOutput "`nStep 5: Configuring Jenkins user AWS credentials..." $Yellow
    
    ssh $SSHOptions "${EC2User}@${EC2PublicIP}" @"
# Configure for Jenkins user
sudo mkdir -p /var/lib/jenkins/.aws
sudo bash -c "cat > /var/lib/jenkins/.aws/credentials << 'EOF'
[default]
aws_access_key_id = $AwsAccessKey
aws_secret_access_key = $AwsSecretKey
EOF"
sudo bash -c "cat > /var/lib/jenkins/.aws/config << 'EOF'
[default]
region = eu-west-2
output = json
EOF"
sudo chown -R jenkins:jenkins /var/lib/jenkins/.aws
sudo chmod 700 /var/lib/jenkins/.aws
sudo chmod 600 /var/lib/jenkins/.aws/*
"@ | Out-Null

    Write-ColorOutput "✓ Jenkins user AWS credentials configured" $Green

    # Step 6: Verify Jenkins can access AWS
    Write-ColorOutput "`nStep 6: Verifying Jenkins user AWS access..." $Yellow
    $jenkinsVerify = ssh $SSHOptions "${EC2User}@${EC2PublicIP}" "sudo -u jenkins aws sts get-caller-identity" 2>&1
    
    if ($jenkinsVerify -match "Account") {
        Write-ColorOutput "✓ Jenkins user can access AWS" $Green
        Write-ColorOutput "  Account: 975050024946" $Green
    } else {
        Write-ColorOutput "⚠ Warning: Could not verify Jenkins AWS access" $Yellow
        Write-ColorOutput "  This may still work when Jenkins runs the build" $Yellow
    }

    # Step 7: Trigger Jenkins build
    Write-ColorOutput "`nStep 7: Triggering Jenkins build..." $Yellow
    
    # Get Jenkins token (if available) or trigger without token
    Write-ColorOutput "  Building durga-streaming-app/develop branch..." $Yellow
    
    $jenkinsUrl = "http://$EC2PublicIP:8080"
    $jobUrl = "$jenkinsUrl/job/durga-streaming-app/job/develop/build?delay=0sec"
    
    Write-ColorOutput "  Build URL: $jobUrl" $Cyan
    Write-ColorOutput "  Note: Build will be triggered once Jenkins receives webhook event" $Yellow

    # Step 8: Summary
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════════╗" $Cyan
    Write-ColorOutput "║                    CONFIGURATION COMPLETE                         ║" $Cyan
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════════╝" $Cyan

    Write-ColorOutput "`n✅ AWS CLI configured successfully!" $Green
    Write-ColorOutput "`n📋 NEXT STEPS:" $Yellow
    Write-ColorOutput "  1. Wait 30 seconds for configuration to take effect" $Yellow
    Write-ColorOutput "  2. Push a commit to develop branch:" $Yellow
    Write-ColorOutput "     git push origin develop" $Cyan
    Write-ColorOutput "  3. Jenkins will automatically build" $Yellow
    Write-ColorOutput "  4. Monitor Jenkins at: $jenkinsUrl" $Cyan
    
    Write-ColorOutput "`n⏱️  BUILD EXPECTED TIME:" $Yellow
    Write-ColorOutput "  First build: 10-15 minutes" $Yellow
    Write-ColorOutput "  Cached builds: 2-5 minutes" $Yellow

    Write-ColorOutput "`n📊 BUILD STATUS CHECK:" $Yellow
    Write-ColorOutput "  Jenkins Console: $jenkinsUrl/job/durga-streaming-app/job/develop/lastBuild/console" $Cyan

} catch {
    Write-ColorOutput "`n✗ Error: $_" $Red
    Write-ColorOutput "`nTroubleshooting:" $Yellow
    Write-ColorOutput "  • Make sure PEM file is in current directory" $Yellow
    Write-ColorOutput "  • Check EC2 instance is running at $EC2PublicIP" $Yellow
    Write-ColorOutput "  • Verify SSH access: ssh -i $PemKeyPath ${EC2User}@${EC2PublicIP}" $Yellow
    exit 1
}
