# GitHub Webhook Configuration Guide

This guide shows how to configure GitHub webhooks to automatically trigger Jenkins builds.

## Prerequisites

- Jenkins instance running and accessible from the internet
- GitHub repository access
- GitHub Personal Access Token with repo and admin:repo_hook permissions

## Step 1: Create GitHub Personal Access Token

### 1.1 Generate Token

1. Go to https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Fill in:
   - **Token name**: `jenkins-ci-token`
   - **Expiration**: 90 days (or customize)
   - **Scopes**:
     - ✓ `repo` (Full control of private repositories)
     - ✓ `admin:repo_hook` (Write access to hooks in public and private repositories)

4. Click **"Generate token"**
5. **Copy the token** (you won't see it again!)

### 1.2 Add Token to Jenkins

1. In Jenkins, go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **"Add Credentials"**
3. Fill in:
   - **Kind**: Username with password
   - **Username**: Your GitHub username
   - **Password**: Paste the token
   - **ID**: `github-credentials`
   - **Description**: GitHub Token for durga-streaming-app
4. Click **Create**

## Step 2: Configure GitHub Repository Webhook

### 2.1 Add Webhook to Repository

1. Go to https://github.com/durganaresh83/durga-StreamingApp
2. Click **Settings** → **Webhooks** → **Add webhook**

### 2.2 Fill Webhook Details

1. **Payload URL**: 
   ```
   http://YOUR_JENKINS_PUBLIC_IP:8080/github-webhook/
   ```
   Example: `http://18.170.42.18:8080/github-webhook/`

2. **Content type**: Select `application/json`

3. **Which events would you like to trigger this webhook?**:
   - Select: **Just the push event**
   - Optional: Also select **Pull requests**

4. **Active**: ✓ Check this box

5. Click **Add webhook**

### 2.3 Verify Webhook

After creating the webhook:
- You should see a green ✓ next to the webhook
- Under "Recent Deliveries", you should see successful POST requests (202 status)

If you see errors:
- Check Jenkins logs for details
- Verify Jenkins URL is publicly accessible
- Verify security group allows port 8080

## Step 3: Configure Jenkins for GitHub

### 3.1 Install GitHub Plugin

1. In Jenkins, go to **Manage Jenkins** → **Manage Plugins**
2. Search for: `GitHub Integration`
3. Check the box and click **Install without restart**
4. Restart Jenkins:
   ```
   sudo systemctl restart jenkins
   ```

### 3.2 Configure GitHub Server

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **GitHub** section
3. Click **Add GitHub Server** → **GitHub Server**
4. Fill in:
   - **Name**: GitHub (default)
   - **API URL**: `https://api.github.com`
   - **Credentials**: Select `github-credentials`
5. Click **Test connection** - should show green ✓
6. Click **Save**

## Step 4: Pipeline Configuration

### 4.1 For Multibranch Pipeline

1. Create or edit your Multibranch Pipeline job
2. Under **Branch Sources** → **GitHub**
3. Fill in:
   - **Credentials**: `github-credentials`
   - **Repository URL**: `https://github.com/durganaresh83/durga-StreamingApp.git`
   - **Discover branches**: Select all options
   - **Discover pull requests from origin**: Enabled
   - **Discover pull requests from forks**: Enabled (if you want)

4. Under **Scan Triggers**:
   - ✓ Check **Periodically if not otherwise run**
   - Interval: `1 hour`

5. Click **Save**

### 4.2 For Declarative Pipeline Job

1. Create or edit your Pipeline job
2. Under **Pipeline** section:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/durganaresh83/durga-StreamingApp.git`
   - **Credentials**: `github-credentials`
   - **Branch Specifier**: `*/develop`
   - **Script Path**: `Jenkinsfile`

3. Under **Build Triggers**:
   - ✓ Check **GitHub hook trigger for GITScm polling**

4. Click **Save**

## Step 5: Test Webhook

### 5.1 Manual Trigger Test

1. Make a push to the repository:
   ```bash
   git add .
   git commit -m "Test webhook trigger"
   git push origin develop
   ```

2. Go to GitHub webhook settings (Settings → Webhooks)
3. You should see the delivery under "Recent Deliveries"

### 5.2 Verify Jenkins Build

1. Go to your Jenkins pipeline job
2. You should see a new build automatically triggered
3. Check the build log to verify everything ran correctly

## Webhook Events Explained

### Push Event (Recommended)
- Triggered on `git push` to any branch
- Good for general CI/CD

### Pull Request Events
- Triggered when PR is opened/updated
- Useful for PR validation before merge

## Troubleshooting

### Issue: Webhook Delivery Shows 404 Error

**Solution**:
- Verify Jenkins URL is correct and publicly accessible
- Check Jenkins is running: `sudo systemctl status jenkins`
- Verify security group allows port 8080 inbound
- Check Jenkins plugin is installed: **Manage Jenkins** → **Manage Plugins** → search "GitHub Integration"

### Issue: Webhook Delivery Shows 403 Forbidden

**Solution**:
- Verify GitHub credentials are correct in Jenkins
- Verify Personal Access Token has `admin:repo_hook` scope
- Re-save Jenkins configuration: **Manage Jenkins** → **Configure System**

### Issue: Build Not Triggered on Push

**Solution**:
1. Check Recent Deliveries in GitHub webhook settings
2. Verify build trigger is enabled in Jenkins job
3. Try manual webhook delivery from GitHub:
   - Go to webhook settings
   - Click **Redeliver** on a previous delivery
4. Check Jenkins logs: `sudo tail -f /var/log/jenkins/jenkins.log`

### Issue: Webhook Delivery Shows 202 but Build Doesn't Start

**Solution**:
- Verify Jenkinsfile exists in repository
- Check Git credentials are correct
- Verify branch name matches (develop vs main)
- Check Multibranch pipeline branch discovery settings

## GitHub Actions Integration (Optional)

If you want to use GitHub Actions instead of webhooks:

1. Create `.github/workflows/build.yml` in repository:
```yaml
name: Build and Push to ECR

on:
  push:
    branches: [develop, main]
  pull_request:
    branches: [develop]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and push to ECR
        run: |
          # Add your build commands here
```

2. Configure GitHub Secrets with AWS credentials
3. GitHub Actions will run instead of Jenkins webhooks

## Security Considerations

1. **Token Expiration**: GitHub tokens expire - set reminders to refresh
2. **Webhook Secret** (Optional): Add a secret to webhook for additional security
3. **Limited Scopes**: Tokens should have minimal required permissions
4. **Webhook Logs**: Regularly check webhook delivery logs for suspicious activity
5. **IP Whitelist** (if applicable): Only allow GitHub's IP ranges

## Webhook Payload

The webhook sends a JSON payload containing:

```json
{
  "ref": "refs/heads/develop",
  "repository": {
    "name": "durga-StreamingApp",
    "url": "https://github.com/durganaresh83/durga-StreamingApp"
  },
  "pusher": {
    "name": "durganaresh83"
  },
  "commits": [
    {
      "id": "abc1234567890",
      "message": "Your commit message",
      "author": {
        "name": "Author Name"
      }
    }
  ]
}
```

Jenkins uses this to determine:
- Which branch was pushed
- Which commits were included
- Trigger corresponding builds

## Monitoring Webhooks

### GitHub Side

1. Go to **Settings** → **Webhooks** → Select webhook
2. Click **Recent Deliveries**
3. View:
   - Status code (200/202 = success, 4xx/5xx = error)
   - Response body
   - Request/response headers
   - Payload sent

### Jenkins Side

1. Go to Pipeline job
2. Click on build number
3. View **Console Output** for:
   - Git clone details
   - Branch information
   - Build execution

## Advanced: Custom Webhook Payloads

Jenkins supports custom payload transformations:

1. **Manage Jenkins** → **Manage Plugins** → Install **Generic Webhook Trigger**
2. Use regex patterns to extract and parse webhook data
3. Advanced trigger conditions based on payload content

---

**Status**: ✓ Webhook configured for automatic CI/CD builds

**Next**: Push a commit to develop branch to test the webhook!
