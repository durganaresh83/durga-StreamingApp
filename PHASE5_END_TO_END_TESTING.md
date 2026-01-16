# Phase 5: End-to-End CI/CD Testing

## Overview

Phase 5 is the final verification step that tests the complete CI/CD pipeline from code push to Docker images in ECR.

**Status**: Ready to execute

## Quick Start

### Step 1: Make Test Commit
```bash
# Make a small change to any file
echo "# CI/CD test $(date)" >> README.md

# Stage and commit
git add .
git commit -m "test: trigger Jenkins CI/CD pipeline"

# Push to develop
git push origin develop
```

### Step 2: Watch Jenkins Build
1. Open: http://3.10.208.103:8080
2. Click `durga-streaming-app` job
3. Watch the build progress
4. Expected time: 8-15 minutes (first build)

### Step 3: Verify ECR Images
```bash
# Check images pushed to ECR
aws ecr describe-images --repository-name durga-streaming-app/frontend --region eu-west-2 --output table
```

## Expected Pipeline Execution

### GitHub Webhook Trigger
- ✓ Push commit to develop branch
- ✓ GitHub webhook sends POST to Jenkins
- ✓ Jenkins receives webhook (should be green ✅ in GitHub)

### Jenkins Build Stages
1. **Checkout** - Clone repository
2. **Initialize** - Verify environment
3. **ECR Login** - Authenticate with AWS
4. **Build Services** - Docker build for 5 services:
   - auth-service
   - streaming-service
   - admin-service
   - chat-service
   - frontend
5. **Push to ECR** - Upload images to AWS ECR
6. **Cleanup** - Remove old Docker images

### Success Indicators
- Build status: **GREEN** ✅
- Console output ends with: `Finished: SUCCESS`
- ECR repository shows new images with tags
- All 5 services appear in ECR

## Build Performance

| Scenario | Time |
|----------|------|
| First build (no cache) | 10-15 minutes |
| Subsequent builds (with cache) | 2-5 minutes |
| Just frontend change | 3-5 minutes |
| Just backend service change | 5-8 minutes |

## Verification Steps

### GitHub Webhook
1. Repo → Settings → Webhooks
2. Click webhook URL
3. Check "Recent Deliveries"
4. Look for green ✅ next to latest push

### Jenkins Console
```bash
# SSH to EC2 and check logs
ssh -i path/to/durga-windows.pem ec2-user@3.10.208.103

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check Docker
docker ps
docker images
```

### ECR Repository
**Option A: AWS Console**
- Console → ECR → durga-streaming-app
- View each service repository
- Check image tags and sizes

**Option B: AWS CLI**
```bash
# List all repositories
aws ecr describe-repositories --region eu-west-2 --output table

# List images in a repository
aws ecr describe-images --repository-name durga-streaming-app/frontend --region eu-west-2 --output table

# Get image details
aws ecr describe-images \
  --repository-name durga-streaming-app/frontend \
  --region eu-west-2 \
  --query 'imageDetails[*].[imageTags,imageSizeInBytes,imagePushedAt]' \
  --output table
```

## Troubleshooting

### Jenkins Build Not Triggered
**Problem**: Push to GitHub but no Jenkins build starts

**Solutions**:
1. Check GitHub webhook:
   - Repo → Settings → Webhooks
   - Should show green ✅ checkmark
   - Click to view delivery status

2. Check Jenkins configuration:
   - Jenkins → durga-streaming-app → Configure
   - Verify GitHub repository URL is correct
   - Verify credentials are configured

3. Manually trigger build:
   - Jenkins dashboard → Build Now
   - Check if manual build works

### Build Fails at Docker Stage
**Problem**: Docker build command fails

**Solutions**:
1. Check EC2 storage:
   ```bash
   ssh -i key.pem ec2-user@IP
   df -h  # Check free space (need 50GB+)
   ```

2. Check Docker daemon:
   ```bash
   sudo systemctl status docker
   docker ps
   ```

3. Check Jenkins logs:
   ```bash
   sudo journalctl -u jenkins -n 100
   ```

### ECR Push Fails
**Problem**: Docker image built but push to ECR fails

**Solutions**:
1. Verify AWS credentials in Jenkins:
   - Jenkins → Manage Jenkins → Credentials
   - Check AWS credentials are configured

2. Verify ECR repositories exist:
   ```bash
   aws ecr describe-repositories --region eu-west-2
   ```

3. Check IAM permissions:
   - Verify Jenkins IAM user has ecr:BatchGetImage, ecr:GetDownloadUrlForLayer, ecr:PutImage permissions

### Images Not in ECR
**Problem**: Build succeeds but images not visible in ECR

**Solutions**:
1. Verify build completed:
   - Check Jenkins console output
   - Look for "Pushed" messages

2. Check AWS region:
   - Verify looking at eu-west-2
   - ECR might show different regions

3. Check repository names:
   ```bash
   aws ecr describe-repositories --region eu-west-2 --output table
   ```

## Success Checklist

Complete this checklist when Phase 5 is done:

- [ ] Test commit created and pushed
- [ ] GitHub webhook shows delivery status ✅
- [ ] Jenkins build triggered automatically
- [ ] Build progresses through all stages
- [ ] Build completes with SUCCESS status
- [ ] All 5 services built without errors
- [ ] Docker images tagged correctly
- [ ] Images pushed to ECR successfully
- [ ] ECR shows all 5 repositories with new images
- [ ] Jenkins logs show no error messages
- [ ] Build time recorded for baseline

## Next Steps

After Phase 5 completes successfully:

1. **Archive this setup** for future reference
2. **Document your deployment** process
3. **Create ECS/Kubernetes manifests** for deployment
4. **Setup monitoring** and alerts
5. **Configure production environments**

## Quick Reference

**Jenkins URL**: http://3.10.208.103:8080

**ECR Region**: eu-west-2

**AWS Account**: 975050024946

**Repository**: durga-streaming-app

**Docker Services**:
- auth-service
- streaming-service
- admin-service
- chat-service
- frontend

## Support Documents

- `README_JENKINS_CI_CD.md` - Setup index
- `JENKINS_SETUP_GUIDE.md` - Detailed guide
- `GITHUB_WEBHOOK_SETUP.md` - Webhook configuration
- `JENKINS_EC2_INFO.md` - EC2 details
- `JENKINS_CREDENTIALS.md` - Credentials reference

---

**Phase 5 Status**: Ready for end-to-end testing
**Last Updated**: January 16, 2026
