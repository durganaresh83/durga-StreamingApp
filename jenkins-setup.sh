#!/bin/bash
# Jenkins Installation Script for MERN Streaming App CI/CD
# This script installs Jenkins and required tools on an AWS EC2 instance (Amazon Linux 2)
# Run as: sudo bash jenkins-setup.sh

set -e

echo "======================================"
echo "Jenkins CI/CD Setup for Streaming App"
echo "======================================"

# Update system packages
echo "Step 1: Updating system packages..."
sudo yum update -y

# Install Java (Jenkins requirement)
echo "Step 2: Installing Java..."
sudo yum install java-17-amazon-corretto -y
java -version

# Add Jenkins repository
echo "Step 3: Adding Jenkins repository..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

# Install Jenkins
echo "Step 4: Installing Jenkins..."
sudo yum install jenkins -y

# Start Jenkins service
echo "Step 5: Starting Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins

# Install Docker (for building container images)
echo "Step 6: Installing Docker..."
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker

# Add Jenkins user to docker group
echo "Step 7: Adding Jenkins to docker group..."
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins

# Install Git
echo "Step 8: Installing Git..."
sudo yum install git -y

# Install pip and AWS CLI
echo "Step 9: Installing AWS CLI..."
sudo yum install python3-pip -y
pip3 install awscli --upgrade

# Install Node.js and npm (for frontend builds)
echo "Step 10: Installing Node.js..."
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install nodejs -y

# Configure Docker credentials for ECR
echo "Step 11: Configuring Docker for ECR access..."
mkdir -p /var/lib/jenkins/.docker

# Create docker config with ECR credentials
cat > /tmp/docker-config.json << 'EOF'
{
  "credentialHelpers": {}
}
EOF

sudo cp /tmp/docker-config.json /var/lib/jenkins/.docker/config.json
sudo chown jenkins:jenkins /var/lib/jenkins/.docker/config.json
sudo chmod 600 /var/lib/jenkins/.docker/config.json

# Get initial Jenkins password
echo ""
echo "======================================"
echo "Jenkins Setup Complete!"
echo "======================================"
echo ""
echo "📌 NEXT STEPS:"
echo "1. Get initial admin password:"
echo "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "2. Access Jenkins at:"
echo "   http://YOUR_EC2_PUBLIC_IP:8080"
echo ""
echo "3. Complete Jenkins setup wizard"
echo "4. Install suggested plugins"
echo ""
echo "======================================"
echo ""

# Display useful information
echo "Installed versions:"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Git: $(git --version)"
echo "Docker: $(docker --version)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo ""
echo "Jenkins is running on port 8080"
echo "======================================"
