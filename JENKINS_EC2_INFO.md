# Jenkins EC2 Instance - Connection Information

## Instance Details
- **Instance ID**: i-0a88cd9cc156659b8
- **Instance Name**: durga-streaming-app
- **Instance Type**: t3.medium
- **Region**: eu-west-2
- **Public IP**: 3.10.208.103
- **Private IP**: 172.31.37.244
- **Key File**: durga-windows.pem
- **SSH User**: ec2-user
- **Security Group ID**: sg-0fb75c4d9f8d88524

## Jenkins Access Information
- **Jenkins URL**: http://3.10.208.103:8080
- **Jenkins Port**: 8080
- **SSH Port**: 22

## Next Steps

### Phase 2: Install Jenkins (5-10 minutes)

Wait 30-60 seconds, then SSH into the instance:
```bash
ssh -i path/to/durga-windows.pem ec2-user@3.10.208.103
```

After logging in, run the Jenkins installation script:
```bash
curl -fsSL https://raw.githubusercontent.com/durganaresh83/durga-StreamingApp/develop/jenkins-setup.sh | sudo bash
```

The installation will:
- ✓ Install Java 11
- ✓ Install Jenkins
- ✓ Install Docker
- ✓ Install Git
- ✓ Install AWS CLI v2
- ✓ Install Node.js 18
- ✓ Configure Jenkins for Docker builds

**Expected time**: 5-10 minutes

### After Installation

Once the installation completes, retrieve your Jenkins admin password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Save this password! You'll need it to complete the Jenkins setup wizard.

### Proceed to Phase 3

Open your browser and navigate to: **http://3.10.208.103:8080**

Complete the Jenkins setup wizard with your initial admin password.

## Useful Commands During Setup

Check Jenkins status:
```bash
sudo systemctl status jenkins
```

View Jenkins logs:
```bash
sudo tail -f /var/log/jenkins/jenkins.log
```

Restart Jenkins if needed:
```bash
sudo systemctl restart jenkins
```

## Troubleshooting

If Jenkins doesn't start after 10 minutes:
1. SSH into the instance
2. Check logs: `sudo tail -f /var/log/jenkins/jenkins.log`
3. Check Java: `java -version`
4. Restart: `sudo systemctl restart jenkins`

For more details, see: **JENKINS_SETUP_OVERVIEW.md** and **JENKINS_SETUP_GUIDE.md**
