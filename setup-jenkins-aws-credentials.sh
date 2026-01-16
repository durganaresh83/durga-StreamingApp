#!/bin/bash
#####################################################################
# Setup AWS credentials for Jenkins on EC2
# This script configures AWS CLI credentials for the Jenkins user
# Run with: bash setup-jenkins-aws-credentials.sh ACCESS_KEY SECRET_KEY
#####################################################################

set -e

if [ $# -ne 2 ]; then
    echo "Usage: bash $0 <AWS_ACCESS_KEY> <AWS_SECRET_KEY>"
    echo "Example: bash $0 AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    exit 1
fi

AWS_ACCESS_KEY="$1"
AWS_SECRET_KEY="$2"
AWS_REGION="eu-west-2"

echo "════════════════════════════════════════════════════════════════"
echo "Setting up AWS credentials for Jenkins"
echo "════════════════════════════════════════════════════════════════"

# Step 1: Create .aws directory for Jenkins user
echo ""
echo "Step 1: Creating AWS configuration directory..."
sudo mkdir -p /var/lib/jenkins/.aws
sudo chmod 700 /var/lib/jenkins/.aws
echo "✓ Directory created"

# Step 2: Create credentials file
echo ""
echo "Step 2: Creating AWS credentials file..."
sudo tee /var/lib/jenkins/.aws/credentials > /dev/null << EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_KEY}
EOF
echo "✓ Credentials file created"

# Step 3: Create config file
echo ""
echo "Step 3: Creating AWS config file..."
sudo tee /var/lib/jenkins/.aws/config > /dev/null << EOF
[default]
region = ${AWS_REGION}
output = json
EOF
echo "✓ Config file created"

# Step 4: Set proper permissions
echo ""
echo "Step 4: Setting file permissions..."
sudo chown jenkins:jenkins /var/lib/jenkins/.aws/credentials
sudo chown jenkins:jenkins /var/lib/jenkins/.aws/config
sudo chmod 600 /var/lib/jenkins/.aws/credentials
sudo chmod 600 /var/lib/jenkins/.aws/config
echo "✓ Permissions set correctly"

# Step 5: Create ec2-user credentials for testing
echo ""
echo "Step 5: Creating credentials for ec2-user..."
mkdir -p ~/.aws
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_KEY}
EOF
chmod 600 ~/.aws/credentials

cat > ~/.aws/config << EOF
[default]
region = ${AWS_REGION}
output = json
EOF
chmod 600 ~/.aws/config
echo "✓ ec2-user credentials created"

# Step 6: Verify credentials
echo ""
echo "Step 6: Verifying AWS credentials..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    echo "✓ AWS credentials verified for ec2-user"
    aws sts get-caller-identity
else
    echo "✗ Failed to verify credentials for ec2-user"
    exit 1
fi

# Step 7: Verify Jenkins can access
echo ""
echo "Step 7: Verifying Jenkins user can access AWS..."
if sudo -u jenkins bash -c 'source /etc/profile.d/java.sh 2>/dev/null; aws sts get-caller-identity' > /dev/null 2>&1; then
    echo "✓ Jenkins user can access AWS"
else
    echo "⚠ Warning: Could not verify Jenkins user AWS access"
    echo "  This may still work during Jenkins build execution"
fi

# Step 8: Restart Jenkins
echo ""
echo "Step 8: Restarting Jenkins service..."
sudo systemctl restart jenkins
echo "✓ Jenkins restarted"

# Step 9: Wait for Jenkins to start
echo ""
echo "Step 9: Waiting for Jenkins to start (30 seconds)..."
sleep 30
echo "✓ Jenkins should be ready"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ AWS credentials setup complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Files created:"
echo "  • /var/lib/jenkins/.aws/credentials"
echo "  • /var/lib/jenkins/.aws/config"
echo "  • ~/.aws/credentials (for ec2-user testing)"
echo "  • ~/.aws/config (for ec2-user testing)"
echo ""
echo "Next steps:"
echo "  1. Trigger a new Jenkins build"
echo "  2. Watch: http://YOUR_EC2_IP:8080/job/durga-streaming-app/job/develop/"
echo ""
