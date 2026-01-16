# Jenkins Setup Helper for Windows
# This PowerShell script helps set up Jenkins on EC2

param(
    [string]$InstanceId = "",
    [string]$InstanceName = "durga-streaming-app",
    [string]$Region = "eu-west-2",
    [string]$PemFilePath = "durga-windows.pem",
    [string]$JenkinsScriptPath = "jenkins-setup.sh"
)

$ErrorActionPreference = "Stop"

function Write-Success {
    Write-Host $args -ForegroundColor Green
}

function Write-Info {
    Write-Host $args -ForegroundColor Cyan
}

function Write-Error-Custom {
    Write-Host $args -ForegroundColor Red
}

# Step 1: Find or validate instance
Write-Info "`n========================================`n"
Write-Info "Jenkins EC2 Setup Helper"
Write-Info "========================================`n"

if (-not $InstanceId) {
    Write-Info "Step 1: Finding EC2 instance by name..."
    try {
        $instances = aws ec2 describe-instances `
            --filters "Name=tag:Name,Values=$InstanceName" `
            --region $Region `
            --query 'Reservations[].Instances[]' `
            --output json | ConvertFrom-Json
        
        if ($instances.Count -eq 0) {
            Write-Error-Custom "No instance found with name: $InstanceName"
            Write-Host "`nAvailable instances in $Region :"
            aws ec2 describe-instances `
                --filters "Name=instance-state-name,Values=running" `
                --region $Region `
                --query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`].Value|[0], InstanceType]' `
                --output table
            exit 1
        }
        
        $InstanceId = $instances[0].InstanceId
        Write-Success "✓ Found instance: $InstanceId`n"
    }
    catch {
        Write-Error-Custom "Failed to find instance: $_"
        exit 1
    }
}

# Step 2: Get instance details
Write-Info "Step 2: Getting EC2 instance details..."
try {
    $instance = aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --region $Region `
        --query 'Reservations[0].Instances[0]' `
        --output json | ConvertFrom-Json
    
    $publicIp = $instance.PublicIpAddress
    $instanceType = $instance.InstanceType
    $keyName = $instance.KeyName
    
    Write-Success "✓ Instance found!"
    Write-Host "  Instance ID: $InstanceId"
    Write-Host "  Instance Type: $instanceType"
    Write-Host "  Public IP: $publicIp"
    Write-Host "  Key Name: $keyName`n"
}
catch {
    Write-Error-Custom "Failed to get instance details"
    exit 1
}

# Step 3: Check PEM file
Write-Info "Step 3: Checking PEM file..."
if (-not (Test-Path $PemFilePath)) {
    Write-Error-Custom "PEM file not found: $PemFilePath"
    exit 1
}
Write-Success "✓ PEM file found`n"

# Step 4: Check Jenkins setup script
Write-Info "Step 4: Checking Jenkins setup script..."
if (-not (Test-Path $JenkinsScriptPath)) {
    Write-Error-Custom "Jenkins script not found: $JenkinsScriptPath"
    exit 1
}
Write-Success "✓ Jenkins setup script found`n"

# Step 5: Upload and run setup script
Write-Info "Step 5: Uploading Jenkins setup script to EC2..."

# Use AWS Systems Manager Session Manager (no SSH needed)
Write-Info "`nTwo options to proceed:`n"
Write-Host "Option A: AWS Systems Manager Session Manager (Recommended - no SSH key needed)"
Write-Host "  - No port 22 access required"
Write-Host "  - Uses IAM authentication`n"

Write-Host "Option B: SSH Connection (Requires SSH client)"
Write-Host "  - Requires port 22 access"
Write-Host "  - Uses PEM key authentication`n"

$choice = Read-Host "Choose option (A/B)"

if ($choice -eq "A" -or $choice -eq "a") {
    Write-Info "`nUsing AWS Systems Manager Session Manager...`n"
    
    Write-Info "Starting Systems Manager session..."
    Write-Host "This will open an interactive shell in your terminal.`n"
    
    # Prepare script for upload
    Write-Info "Uploading jenkins-setup.sh..."
    aws ssm start-session --target $InstanceId --region $Region --document-name "AWS-StartInteractiveCommand"
    
    Write-Info "`nIn the session shell, run these commands:`n"
    Write-Host @"
# Upload the script
cat << 'EOF' > jenkins-setup.sh
$(Get-Content $JenkinsScriptPath -Raw)
EOF

# Run the setup
sudo bash jenkins-setup.sh

# Get initial admin password (after Jenkins starts)
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
"@
}
else {
    Write-Info "`nUsing SSH connection...`n"
    
    Write-Info "Uploading jenkins-setup.sh..."
    
    # Convert Windows path to WSL path if needed
    $wslPemPath = $PemFilePath -replace '\\', '/'
    if ($wslPemPath -match '^[a-zA-Z]:') {
        $drive = [char]($wslPemPath[0]) | % { $_.ToString().ToLower() }
        $wslPemPath = "/mnt/$drive/$($wslPemPath.Substring(3))"
    }
    
    # Use SCP to upload
    Write-Host @"
# Using Git Bash or WSL, run:
scp -i $PemFilePath $JenkinsScriptPath ec2-user@$publicIp:/tmp/

# SSH into instance
ssh -i $PemFilePath ec2-user@$publicIp

# On EC2, run:
sudo bash /tmp/jenkins-setup.sh

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
"@
}

# Step 6: Access Jenkins
Write-Info "`n========================================`n"
Write-Success "Jenkins Setup Complete!"
Write-Info "========================================`n"

Write-Host "📌 Next Steps:`n"
Write-Host "1. Wait for Jenkins to start (2-3 minutes)"
Write-Host "2. Get initial admin password:"
Write-Host "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword`n"

Write-Host "3. Open Jenkins in browser:`n"
Write-Host "   http://$publicIp:8080`n"

Write-Host "4. Complete Jenkins setup wizard"
Write-Host "5. Install suggested plugins"
Write-Host "6. Configure credentials and webhooks`n"

Write-Info "========================================`n"

# Optional: Display security group suggestion
Write-Info "Security Group Configuration:`n"
Write-Host "Make sure your EC2 security group allows:`n"
Write-Host "✓ Inbound TCP port 8080 from your IP"
Write-Host "✓ Inbound TCP port 22 for SSH (if using SSH)"`n"

Write-Info "For more help, see: JENKINS_SETUP_GUIDE.md`n"
