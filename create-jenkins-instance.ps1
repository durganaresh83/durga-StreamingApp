#####################################################################
# AWS EC2 Instance Creation Script for Jenkins CI/CD
# This script creates a dedicated t3.medium EC2 instance for Jenkins
#####################################################################

param(
    [Parameter(Mandatory=$true)]
    [string]$KeyName,
    
    [Parameter(Mandatory=$false)]
    [string]$InstanceName = "durga-streaming-app",
    
    [Parameter(Mandatory=$false)]
    [string]$InstanceType = "t3.medium",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "eu-west-2",
    
    [Parameter(Mandatory=$false)]
    [int]$RootVolumeSize = 50
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow
$Red = [System.ConsoleColor]::Red
$Cyan = [System.ConsoleColor]::Cyan

function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [System.ConsoleColor]$Color = $Green
    )
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════════╗" $Cyan
    Write-ColorOutput "║         AWS EC2 Instance Creation for Jenkins CI/CD                ║" $Cyan
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════════╝`n" $Cyan

    # Step 1: Verify AWS credentials
    Write-ColorOutput "Step 1: Verifying AWS credentials..." $Yellow
    try {
        $identity = aws sts get-caller-identity --region $Region --output json | ConvertFrom-Json
        Write-ColorOutput "✓ AWS credentials verified" $Green
        Write-ColorOutput "  Account: $($identity.Account)" $Green
        Write-ColorOutput "  User: $($identity.Arn)" $Green
    } catch {
        Write-ColorOutput "✗ Failed to verify AWS credentials" $Red
        Write-ColorOutput "  Make sure AWS CLI is configured with valid credentials" $Red
        exit 1
    }

    # Step 2: Verify key pair exists
    Write-ColorOutput "`nStep 2: Verifying key pair '$KeyName'..." $Yellow
    try {
        $keyPair = aws ec2 describe-key-pairs --key-names $KeyName --region $Region --output json 2>$null | ConvertFrom-Json
        Write-ColorOutput "✓ Key pair found: $($keyPair.KeyPairs[0].KeyName)" $Green
    } catch {
        Write-ColorOutput "✗ Key pair '$KeyName' not found in region $Region" $Red
        Write-ColorOutput "  Available key pairs:" $Red
        aws ec2 describe-key-pairs --region $Region --query 'KeyPairs[*].KeyName' --output table
        exit 1
    }

    # Step 3: Get latest Amazon Linux 2 AMI
    Write-ColorOutput "`nStep 3: Finding latest Amazon Linux 2 AMI..." $Yellow
    $amiJson = aws ec2 describe-images `
        --owners amazon `
        --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" `
        --query 'Images | sort_by(@, &CreationDate)[-1].[ImageId,CreationDate]' `
        --region $Region `
        --output json | ConvertFrom-Json
    
    $ami = $amiJson[0]
    if (-not $ami) {
        Write-ColorOutput "✗ Failed to find Amazon Linux 2 AMI" $Red
        exit 1
    }
    Write-ColorOutput "✓ Latest AMI found: $ami" $Green

    # Step 4: Create security group (if needed)
    Write-ColorOutput "`nStep 4: Setting up security group..." $Yellow
    
    # Get default VPC
    $defaultVpc = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region $Region --query 'Vpcs[0].VpcId' --output text
    if (-not $defaultVpc) {
        Write-ColorOutput "✗ No default VPC found" $Red
        exit 1
    }
    Write-ColorOutput "✓ Using default VPC: $defaultVpc" $Green

    # Check if security group already exists
    $sgName = "jenkins-sg-$([DateTime]::Now.ToString('yyyyMMdd-HHmm'))"
    $sgDescription = "Security group for Jenkins CI/CD server"
    
    $sgJson = aws ec2 create-security-group `
        --group-name $sgName `
        --description $sgDescription `
        --vpc-id $defaultVpc `
        --region $Region `
        --output json 2>$null | ConvertFrom-Json
    
    $securityGroupId = $sgJson.GroupId
    Write-ColorOutput "✓ Security group created: $securityGroupId" $Green

    # Add ingress rules
    Write-ColorOutput "  Adding ingress rules..." $Yellow
    
    # Allow SSH (port 22)
    aws ec2 authorize-security-group-ingress `
        --group-id $securityGroupId `
        --protocol tcp `
        --port 22 `
        --cidr 0.0.0.0/0 `
        --region $Region | Out-Null
    Write-ColorOutput "  ✓ SSH (port 22): 0.0.0.0/0" $Green

    # Allow Jenkins (port 8080)
    aws ec2 authorize-security-group-ingress `
        --group-id $securityGroupId `
        --protocol tcp `
        --port 8080 `
        --cidr 0.0.0.0/0 `
        --region $Region | Out-Null
    Write-ColorOutput "  ✓ Jenkins (port 8080): 0.0.0.0/0" $Green

    # Allow HTTP (port 80)
    aws ec2 authorize-security-group-ingress `
        --group-id $securityGroupId `
        --protocol tcp `
        --port 80 `
        --cidr 0.0.0.0/0 `
        --region $Region | Out-Null
    Write-ColorOutput "  ✓ HTTP (port 80): 0.0.0.0/0" $Green

    # Allow HTTPS (port 443)
    aws ec2 authorize-security-group-ingress `
        --group-id $securityGroupId `
        --protocol tcp `
        --port 443 `
        --cidr 0.0.0.0/0 `
        --region $Region | Out-Null
    Write-ColorOutput "  ✓ HTTPS (port 443): 0.0.0.0/0" $Green

    # Step 5: Create EC2 instance
    Write-ColorOutput "`nStep 5: Creating EC2 instance..." $Yellow
    Write-ColorOutput "  Instance Type: $InstanceType" $Green
    Write-ColorOutput "  Instance Name: $InstanceName" $Green
    Write-ColorOutput "  Root Volume Size: $RootVolumeSize GB" $Green

    $instanceJson = aws ec2 run-instances `
        --image-id $ami `
        --instance-type $InstanceType `
        --key-name $KeyName `
        --security-group-ids $securityGroupId `
        --block-device-mappings "DeviceName=/dev/xvda,Ebs={VolumeSize=$RootVolumeSize,VolumeType=gp2,DeleteOnTermination=true}" `
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$InstanceName},{Key=Purpose,Value=Jenkins-CI-CD},{Key=ManagedBy,Value=PowerShell-Script}]" `
        --monitoring Enabled=true `
        --region $Region `
        --output json | ConvertFrom-Json

    $instanceId = $instanceJson.Instances[0].InstanceId
    Write-ColorOutput "✓ EC2 instance created: $instanceId" $Green

    # Step 6: Wait for instance to be running
    Write-ColorOutput "`nStep 6: Waiting for instance to start..." $Yellow
    Write-ColorOutput "  (This may take 1-3 minutes)" $Yellow
    
    $maxAttempts = 30
    $attempt = 0
    $instanceRunning = $false
    
    while ($attempt -lt $maxAttempts) {
        $attempt++
        $statusJson = aws ec2 describe-instances --instance-ids $instanceId --region $Region --output json | ConvertFrom-Json
        $state = $statusJson.Reservations[0].Instances[0].State.Name
        
        if ($state -eq "running") {
            $instanceRunning = $true
            break
        }
        
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 2
    }

    if (-not $instanceRunning) {
        Write-ColorOutput "`n✗ Instance failed to start" $Red
        exit 1
    }

    Write-ColorOutput "`n✓ Instance is running" $Green

    # Step 7: Get instance details
    Write-ColorOutput "`nStep 7: Retrieving instance details..." $Yellow
    $detailsJson = aws ec2 describe-instances --instance-ids $instanceId --region $Region --output json | ConvertFrom-Json
    $instance = $detailsJson.Reservations[0].Instances[0]
    
    $publicIp = $instance.PublicIpAddress
    $privateIp = $instance.PrivateIpAddress
    
    if (-not $publicIp) {
        Write-ColorOutput "⚠ Warning: Public IP not yet assigned, retrying..." $Yellow
        Start-Sleep -Seconds 5
        $detailsJson = aws ec2 describe-instances --instance-ids $instanceId --region $Region --output json | ConvertFrom-Json
        $instance = $detailsJson.Reservations[0].Instances[0]
        $publicIp = $instance.PublicIpAddress
    }

    Write-ColorOutput "✓ Instance Details:" $Green
    Write-ColorOutput "  Instance ID: $instanceId" $Green
    Write-ColorOutput "  Public IP: $publicIp" $Green
    Write-ColorOutput "  Private IP: $privateIp" $Green
    Write-ColorOutput "  Instance Type: $($instance.InstanceType)" $Green
    Write-ColorOutput "  Security Group: $securityGroupId" $Green

    # Step 8: Display next steps
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════════╗" $Cyan
    Write-ColorOutput "║                         NEXT STEPS                                 ║" $Cyan
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════════╝" $Cyan
    
    Write-ColorOutput "`n1. Wait 30-60 seconds for instance initialization" $Yellow
    Write-ColorOutput "`n2. SSH into the instance:" $Yellow
    Write-ColorOutput "   ssh -i path/to/durga-windows.pem ec2-user@$publicIp" $Cyan
    
    Write-ColorOutput "`n3. Run Jenkins installation script:" $Yellow
    Write-ColorOutput "   curl -fsSL https://raw.githubusercontent.com/durganaresh83/durga-StreamingApp/develop/jenkins-setup.sh | sudo bash" $Cyan
    
    Write-ColorOutput "`n4. After installation (5-10 min), retrieve Jenkins admin password:" $Yellow
    Write-ColorOutput "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword" $Cyan
    
    Write-ColorOutput "`n5. Access Jenkins in your browser:" $Yellow
    Write-ColorOutput "   http://$publicIp`:8080" $Cyan
    
    Write-ColorOutput "`n📋 INSTANCE INFO SUMMARY" $Green
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" $Green
    Write-ColorOutput "Instance ID:       $instanceId" $Green
    Write-ColorOutput "Public IP:         $publicIp" $Green
    Write-ColorOutput "Private IP:        $privateIp" $Green
    Write-ColorOutput "Key File:          durga-windows.pem" $Green
    Write-ColorOutput "Region:            $Region" $Green
    Write-ColorOutput "SSH User:          ec2-user" $Green
    Write-ColorOutput "Jenkins URL:       http://$publicIp`:8080" $Green
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" $Green

    Write-ColorOutput "`n✅ EC2 Instance created successfully!`n" $Green

} catch {
    Write-ColorOutput "`n✗ Error: $_" $Red
    exit 1
}
