# AWS Credentials Configuration for Jenkins

## Problem

Jenkins build failed with:
```
Unable to locate credentials. You can configure credentials by running "aws configure"
```

**Root Cause**: AWS IAM credentials not configured in Jenkins environment.

## Solution: Add AWS Credentials to Jenkins

### Step 1: Get Your AWS Credentials

#### Method A: Using AWS Console (Recommended)

1. Go to AWS Console: https://console.aws.amazon.com
2. Sign in with your AWS account: durganareshpotta83@gmail.com
3. Go to **IAM** → **Users**
4. Click on your username
5. Click **Security credentials** tab
6. Under **Access keys**, you have two options:
   - **View existing key**: If you already have an access key
   - **Create access key**: If you need a new one

7. You'll see:
   - **Access Key ID** (e.g., `AKIA...`)
   - **Secret Access Key** (e.g., `wJalr...`)

⚠️ **IMPORTANT**: The Secret Access Key is only shown once! Save it somewhere safe.

#### Method B: Using AWS CLI (if configured locally)

```bash
# View existing credentials (in ~/.aws/credentials)
cat ~/.aws/credentials

# Or create new credentials
aws iam create-access-key --user-name your-iam-username
```

### Step 2: Add Credentials to Jenkins

1. **Open Jenkins Dashboard**
   - Go to: http://3.10.208.103:8080
   - Login with your admin user

2. **Navigate to Credentials**
   - Click **Manage Jenkins** (left sidebar)
   - Click **Credentials**
   - Click **System** (left sidebar)
   - Click **Global credentials (unrestricted)**

3. **Add New Credentials**
   - Click **Add Credentials** (left sidebar)
   - Select from dropdown:
     - **Kind**: `AWS Credentials`
     - **ID**: `aws-credentials` (MUST be exact)
     - **Description**: `AWS ECR Credentials for Docker builds`
     - **Access Key ID**: [paste your access key]
     - **Secret Access Key**: [paste your secret key]
     - **Scope**: Global (leave default)
   - Click **Create**

4. **Verify**
   - You should see `aws-credentials` in the credentials list
   - Click it to verify the ID is correct

### Step 3: Retry Jenkins Build

1. **Go to Jenkins Job**
   - Jenkins → `durga-streaming-app` → `develop` branch
   - Click **Build Now**

2. **Monitor Build**
   - Click on the new build number
   - View console output
   - Watch stages execute:
     - ✓ ECR Login (should now succeed)
     - ✓ Build Auth Service
     - ✓ Build Streaming Service
     - ✓ Build Admin Service
     - ✓ Build Chat Service
     - ✓ Build Frontend
     - ✓ Push to ECR
     - ✓ Cleanup

3. **Expected Build Time**
   - First build: 10-15 minutes (no Docker cache)
   - Subsequent builds: 2-5 minutes (with cache)

## Verification

### Check Jenkins Credentials

```bash
# SSH into EC2 instance
ssh -i path/to/durga-windows.pem ec2-user@3.10.208.103

# Credentials are stored in Jenkins
# To verify they work, check Jenkins configuration
sudo cat /var/lib/jenkins/credentials.xml | grep aws-credentials
```

### Verify Build Success

1. **Jenkins Console Output**
   - Should show: "Successfully logged in to ECR ✓"
   - Should show build stages complete

2. **Check ECR Images**
   ```bash
   aws ecr describe-images --repository-name durga-streaming-app/frontend --region eu-west-2 --output table
   ```

3. **Check Image Tags**
   ```bash
   # For each service, verify new images exist
   aws ecr describe-images \
     --repository-name durga-streaming-app/auth-service \
     --region eu-west-2 \
     --output table
   ```

## Troubleshooting

### Still Getting "Unable to locate credentials" Error

**Check 1**: Verify credential ID is exactly `aws-credentials`
- Jenkins → Manage Jenkins → Credentials → System
- Look for `aws-credentials` in the list

**Check 2**: Verify AWS credentials are valid
- Go to AWS IAM Console
- Check Access Key ID still exists (not deleted)
- Check Secret Access Key is correct

**Check 3**: Clear Jenkins cache and retry
```bash
# SSH to EC2
ssh -i durga-windows.pem ec2-user@3.10.208.103

# Restart Jenkins
sudo systemctl restart jenkins

# Check status
sudo systemctl status jenkins
```

**Check 4**: Review Jenkins logs
```bash
ssh -i durga-windows.pem ec2-user@3.10.208.103

# View recent logs
sudo tail -100 /var/log/jenkins/jenkins.log

# Search for error messages
sudo grep -i "credential\|aws\|error" /var/log/jenkins/jenkins.log | tail -20
```

### Build Fails at Different Stage

**If it fails after ECR Login**:
1. Check Docker is running: `docker ps`
2. Check disk space: `df -h` (need 50GB+ free)
3. Check Docker build output for specific error

**If it fails at Push to ECR**:
1. Verify access key has ECR permissions
2. Verify ECR repositories exist (5 total)
3. Check AWS region is eu-west-2

**If build hangs**:
1. Check EC2 CPU/Memory: `top`
2. Check Docker daemon: `docker stats`
3. Restart Jenkins: `sudo systemctl restart jenkins`

## AWS Credentials Security Best Practices

✅ **Do**:
- Rotate access keys every 90 days
- Store credentials only in Jenkins secure credential store
- Use separate IAM user for Jenkins (not your main account)
- Limit IAM permissions to only ECR operations
- Review access key usage in CloudTrail

❌ **Don't**:
- Share AWS credentials via email or chat
- Hardcode credentials in Jenkinsfile
- Commit credentials to Git repository
- Use root AWS account credentials
- Leave unused access keys active

## Reference

**Account Details**:
- AWS Account ID: `975050024946`
- AWS Region: `eu-west-2` (London)
- IAM User: Your configured user
- ECR Registry: `975050024946.dkr.ecr.eu-west-2.amazonaws.com`

**Jenkins Details**:
- Jenkins URL: http://3.10.208.103:8080
- Credential ID: `aws-credentials`
- Credential Type: AWS Credentials

**Pipeline Details**:
- Job Name: `durga-streaming-app`
- Branch: `develop`
- Jenkinsfile: In repository root

---

**Status**: Credentials should be configured and build ready to retry
**Last Updated**: January 16, 2026
