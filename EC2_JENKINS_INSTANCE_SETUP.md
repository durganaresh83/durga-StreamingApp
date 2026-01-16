# Jenkins Setup - EC2 Instance Selection Guide

## Current Running Instances

Based on your AWS account (eu-west-2), here are your instances:

### Running Instances:
1. **i-0a4d87a45f3ad38ee** - full-adish (t3.medium, 18.170.42.18) - NOT YOURS
2. **i-0ec037ee18cfd32a7** - streaming-cluster-adi-standard-workers-Node (t3.medium, 18.132.68.96)
3. **i-0344225adf4402505** - streaming-cluster-adi-standard-workers-Node (t3.medium, 18.175.148.184)

### Stopped Instances:
- i-0a35901713e44d2ad - Adish-Test (t3.medium) - STOPPED
- i-079fe7b51a0bcd1f0 - adish-shopNow (t3.medium) - STOPPED

---

## Options

### Option 1: Create New EC2 Instance for Jenkins ⭐ RECOMMENDED

This is the cleanest approach - create a dedicated Jenkins instance named "durga-streaming-app"

```powershell
# Step 1: Create new EC2 instance
aws ec2 run-instances `
    --image-id ami-0a8e758f5e873d1c1 `
    --instance-type t3.medium `
    --region eu-west-2 `
    --security-groups "default" `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=durga-streaming-app}]" `
    --key-name your-key-pair-name

# Step 2: Wait for instance to start (1-2 minutes)

# Step 3: Get the public IP
aws ec2 describe-instances `
    --filters "Name=tag:Name,Values=durga-streaming-app" `
    --region eu-west-2 `
    --query 'Reservations[0].Instances[0].PublicIpAddress' `
    --output text
```

### Option 2: Use Existing Instance

If you want to use one of your existing instances:
- Check the streaming-cluster instances if they're dedicated for Jenkins
- Verify they have sufficient resources (at least t3.medium with 4GB RAM)

---

## Steps to Create New Jenkins EC2 Instance

### 1. Choose the Right AMI

For Jenkins on Amazon Linux 2:
```powershell
# Find the latest Amazon Linux 2 AMI in eu-west-2
aws ec2 describe-images `
    --owners amazon `
    --filters "Name=name,Values=amzn2-ami-hvm-*" `
    --query 'sort_by(Images, &CreationDate)[-1].[ImageId, Name]' `
    --region eu-west-2 `
    --output text
```

### 2. Create the Instance

```powershell
# Replace values as needed
$ImageId = "ami-0a8e758f5e873d1c1"  # Latest Amazon Linux 2
$InstanceType = "t3.medium"
$Region = "eu-west-2"
$InstanceName = "durga-streaming-app"
$KeyName = "your-existing-key-pair"  # Your PEM key

# Create instance
$response = aws ec2 run-instances `
    --image-id $ImageId `
    --instance-type $InstanceType `
    --region $Region `
    --key-name $KeyName `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$InstanceName}]" `
    --output json | ConvertFrom-Json

$InstanceId = $response.Instances[0].InstanceId
Write-Host "Instance created: $InstanceId"
```

### 3. Configure Security Group

```powershell
# Get the instance's security group
$InstanceId = "i-xxxxxxxxxxxxx"
$SecurityGroupId = $(aws ec2 describe-instances `
    --instance-ids $InstanceId `
    --region eu-west-2 `
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' `
    --output text)

# Add inbound rule for Jenkins (port 8080)
aws ec2 authorize-security-group-ingress `
    --group-id $SecurityGroupId `
    --protocol tcp `
    --port 8080 `
    --cidr 0.0.0.0/0 `
    --region eu-west-2

# Add inbound rule for SSH (port 22)
aws ec2 authorize-security-group-ingress `
    --group-id $SecurityGroupId `
    --protocol tcp `
    --port 22 `
    --cidr 0.0.0.0/0 `
    --region eu-west-2

Write-Host "Security group updated: $SecurityGroupId"
```

### 4. Wait for Instance to Start

```powershell
$InstanceId = "i-xxxxxxxxxxxxx"

# Wait for running state
aws ec2 wait instance-running `
    --instance-ids $InstanceId `
    --region eu-west-2

# Get public IP
$PublicIP = aws ec2 describe-instances `
    --instance-ids $InstanceId `
    --region eu-west-2 `
    --query 'Reservations[0].Instances[0].PublicIpAddress' `
    --output text

Write-Host "Instance is running at: $PublicIP"
```

### 5. Install Jenkins

```bash
# SSH into the instance
ssh -i durga-windows.pem ec2-user@$PublicIP

# Download and run Jenkins setup script
curl -fsSL https://raw.githubusercontent.com/durganaresh83/durga-StreamingApp/develop/jenkins-setup.sh | sudo bash

# Get initial Jenkins password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Complete PowerShell Script for EC2 + Jenkins Setup

Save this as `create-jenkins-instance.ps1`:

```powershell
param(
    [string]$InstanceName = "durga-streaming-app",
    [string]$InstanceType = "t3.medium",
    [string]$Region = "eu-west-2",
    [string]$KeyName = "durga-windows",  # Your existing key pair name
    [string]$PemFilePath = "durga-windows.pem"
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

Write-Info "`n========================================`n"
Write-Info "Jenkins EC2 Instance Setup"
Write-Info "========================================`n"

# Step 1: Find latest Amazon Linux 2 AMI
Write-Info "Step 1: Finding latest Amazon Linux 2 AMI..."
try {
    $ImageId = aws ec2 describe-images `
        --owners amazon `
        --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" `
        --query 'sort_by(Images, &CreationDate)[-1].ImageId' `
        --region $Region `
        --output text
    
    Write-Success "✓ Found AMI: $ImageId`n"
}
catch {
    Write-Error-Custom "Failed to find AMI"
    exit 1
}

# Step 2: Check if key pair exists
Write-Info "Step 2: Verifying key pair..."
try {
    $keyCheck = aws ec2 describe-key-pairs --key-names $KeyName --region $Region --output json 2>&1
    Write-Success "✓ Key pair exists: $KeyName`n"
}
catch {
    Write-Error-Custom "Key pair not found: $KeyName"
    Write-Host "`nAvailable key pairs:"
    aws ec2 describe-key-pairs --region $Region --query 'KeyPairs[].KeyName' --output table
    exit 1
}

# Step 3: Create EC2 instance
Write-Info "Step 3: Creating EC2 instance..."
try {
    $response = aws ec2 run-instances `
        --image-id $ImageId `
        --instance-type $InstanceType `
        --region $Region `
        --key-name $KeyName `
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$InstanceName}]" `
        --output json | ConvertFrom-Json
    
    $InstanceId = $response.Instances[0].InstanceId
    Write-Success "✓ Instance created: $InstanceId`n"
}
catch {
    Write-Error-Custom "Failed to create instance: $_"
    exit 1
}

# Step 4: Wait for instance to start
Write-Info "Step 4: Waiting for instance to start (this takes 1-2 minutes)..."
try {
    aws ec2 wait instance-running `
        --instance-ids $InstanceId `
        --region $Region
    
    Write-Success "✓ Instance is running`n"
}
catch {
    Write-Error-Custom "Failed waiting for instance"
    exit 1
}

# Step 5: Get instance details
Write-Info "Step 5: Retrieving instance details..."
try {
    $instance = aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --region $Region `
        --query 'Reservations[0].Instances[0]' `
        --output json | ConvertFrom-Json
    
    $PublicIP = $instance.PublicIpAddress
    $SecurityGroupId = $instance.SecurityGroups[0].GroupId
    
    Write-Success "✓ Instance details:`n"
    Write-Host "  Instance ID: $InstanceId"
    Write-Host "  Public IP: $PublicIP"
    Write-Host "  Security Group: $SecurityGroupId`n"
}
catch {
    Write-Error-Custom "Failed to get instance details"
    exit 1
}

# Step 6: Configure security group
Write-Info "Step 6: Configuring security group..."
try {
    # Add Jenkins port
    aws ec2 authorize-security-group-ingress `
        --group-id $SecurityGroupId `
        --protocol tcp `
        --port 8080 `
        --cidr 0.0.0.0/0 `
        --region $Region 2>&1 | Out-Null
    
    # Add SSH port
    aws ec2 authorize-security-group-ingress `
        --group-id $SecurityGroupId `
        --protocol tcp `
        --port 22 `
        --cidr 0.0.0.0/0 `
        --region $Region 2>&1 | Out-Null
    
    Write-Success "✓ Security group configured`n"
}
catch {
    Write-Error-Custom "Failed to configure security group (may already be configured)"
}

# Step 7: Display next steps
Write-Info "========================================`n"
Write-Success "✓ Jenkins EC2 Instance Ready!"
Write-Info "========================================`n"

Write-Host "📌 Next Steps:`n"
Write-Host "1. SSH into the instance:"
Write-Host "   ssh -i $PemFilePath ec2-user@$PublicIP`n"

Write-Host "2. On the EC2 instance, run:"
Write-Host "   curl -fsSL https://raw.githubusercontent.com/durganaresh83/durga-StreamingApp/develop/jenkins-setup.sh | sudo bash`n"

Write-Host "3. Get initial Jenkins password:"
Write-Host "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword`n"

Write-Host "4. Access Jenkins:"
Write-Host "   http://$PublicIP:8080`n"

Write-Host "Instance Details:"
Write-Host "  Instance ID: $InstanceId"
Write-Host "  Instance Type: $InstanceType"
Write-Host "  Public IP: $PublicIP"
Write-Host "  Region: $Region"
Write-Host "  Key Pair: $KeyName`n"

Write-Info "========================================`n"
```

Run it with:
```powershell
.\create-jenkins-instance.ps1 -KeyName "your-key-pair-name"
```

---

## Next Steps

1. **Create the EC2 instance** using the script above
2. **Wait for it to start** (1-2 minutes)
3. **SSH into the instance** using your PEM key
4. **Run Jenkins setup script**
5. **Configure Jenkins** through the web UI
6. **Add credentials** (GitHub, AWS)
7. **Create pipeline** job
8. **Configure webhook** in GitHub

---

## Important Notes

- **Never use shared instances** for CI/CD - create a dedicated one
- **Update security group** to only allow your IP if possible (instead of 0.0.0.0/0)
- **Tag the instance** properly for easy identification
- **Keep PEM file secure** - don't commit to git

---

Which instance would you like to use, or would you like me to help you create a new one named "durga-streaming-app"?
