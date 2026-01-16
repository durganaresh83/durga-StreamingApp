# 🚀 Jenkins CI/CD Setup - Complete Documentation Index

This folder contains everything needed to set up Jenkins CI/CD automation for the MERN Streaming App.

## ⚡ Quick Start

**New to this? Start here:**

1. **Read first**: `JENKINS_SETUP_OVERVIEW.md` - Get the big picture
2. **Create EC2**: Run `.\create-jenkins-instance.ps1` - Creates dedicated Jenkins instance  
3. **Install Jenkins**: Run `jenkins-setup.sh` on the EC2 instance
4. **Configure webhooks**: Follow `GITHUB_WEBHOOK_SETUP.md`
5. **Test**: Push to GitHub and watch Jenkins build automatically

## 📁 File Guide

### 🔧 Automation Scripts

| File | Purpose | Usage |
|------|---------|-------|
| `jenkins-setup.sh` | Installs Jenkins on EC2 | `sudo bash jenkins-setup.sh` |
| `jenkins-setup-helper.ps1` | Windows setup assistant | `.\jenkins-setup-helper.ps1` |
| `create-jenkins-instance.ps1` | Creates EC2 + Jenkins | `.\create-jenkins-instance.ps1` |

### 📋 Configuration

| File | Purpose |
|------|---------|
| `Jenkinsfile` | Pipeline definition (goes in repo root) |

### 📚 Documentation (Read in Order)

1. **`JENKINS_SETUP_OVERVIEW.md`** ⭐ START HERE
   - Quick start guide
   - 5-phase setup checklist
   - Feature overview
   - Architecture diagram

2. **`JENKINS_SETUP_GUIDE.md`** 
   - Detailed step-by-step setup
   - 9 major sections
   - Screenshots recommendations
   - All configuration options

3. **`GITHUB_WEBHOOK_SETUP.md`**
   - GitHub integration
   - Personal access token creation
   - Webhook configuration
   - Troubleshooting webhook issues

4. **`EC2_JENKINS_INSTANCE_SETUP.md`**
   - EC2 instance creation
   - Security group configuration
   - Key pair setup
   - PowerShell automation scripts

5. **`JENKINS_CI_REFERENCE.md`**
   - Quick command reference
   - Useful commands for EC2
   - Monitoring build progress
   - Troubleshooting guide

## 🎯 Setup Phases

### Phase 1: EC2 Instance (5 minutes)
```powershell
# List your key pairs
aws ec2 describe-key-pairs --region eu-west-2

# Create instance
.\create-jenkins-instance.ps1 -KeyName "your-key-pair"
```

### Phase 2: Jenkins Installation (5-10 minutes)
```bash
ssh -i your-key.pem ec2-user@PUBLIC_IP
curl -fsSL https://raw.githubusercontent.com/durganaresh83/durga-StreamingApp/develop/jenkins-setup.sh | sudo bash
```

### Phase 3: Jenkins Configuration (10 minutes)
- Access `http://PUBLIC_IP:8080`
- Run setup wizard
- Add credentials
- Create pipeline job

### Phase 4: GitHub Integration (5 minutes)
- Create personal access token
- Add webhook to repository
- Test webhook delivery

### Phase 5: Testing (5 minutes)
```bash
git push origin develop
# Watch Jenkins build automatically!
```

## 🔑 Key Information

| Item | Value |
|------|-------|
| AWS Account ID | 975050024946 |
| ECR Registry | 975050024946.dkr.ecr.eu-west-2.amazonaws.com |
| Repository | durga-streaming-app |
| Region | eu-west-2 (London) |
| Jenkins Port | 8080 |
| Supported Services | 5 (auth, streaming, admin, chat, frontend) |

## 📊 Pipeline Capabilities

### Supported Services
- ✅ auth-service (Node.js + Express)
- ✅ streaming-service (Node.js + Express)
- ✅ admin-service (Node.js + Express)
- ✅ chat-service (Node.js + Socket.io)
- ✅ frontend (React + Nginx)

### Build Options
- Build all services or individual services
- Push to ECR or local only
- Tag as 'latest' or build number only
- Manual or automatic triggers

### Pipeline Stages
1. Checkout code from GitHub
2. Initialize build environment
3. Login to AWS ECR
4. Build Docker images
5. Push images to ECR
6. Cleanup old images

## ⚠️ Important Notes

### ✅ DO
- ✅ Create dedicated EC2 instance for Jenkins
- ✅ Use strong passwords for Jenkins admin
- ✅ Rotate GitHub tokens regularly
- ✅ Keep PEM files secure
- ✅ Monitor Jenkins logs
- ✅ Test webhook deliveries

### ❌ DON'T
- ❌ Share EC2 instances (like "full-adish")
- ❌ Use instance i-0a4d87a45f3ad38ee
- ❌ Commit PEM files to Git
- ❌ Hardcode AWS credentials in code
- ❌ Open security groups to 0.0.0.0/0 (except testing)
- ❌ Reuse Jenkins instances across projects

## 🐛 Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| Jenkins won't start | Check EC2 status and logs |
| Docker command not found | Add jenkins to docker group |
| Can't push to ECR | Verify AWS credentials |
| Webhook not triggering | Check GitHub webhook Recent Deliveries |
| Build slow | Increase EC2 instance size |

See `JENKINS_CI_REFERENCE.md` for detailed troubleshooting.

## 📈 Performance Tips

1. **Faster Builds**: Use EC2 instance type t3.large or larger
2. **Parallel Builds**: Increase Jenkins executors to 4-8
3. **Docker Caching**: Jenkinsfile already optimized
4. **Disk Space**: Monitor `/var/lib/jenkins/workspace/`

## 🔒 Security Best Practices

1. Change Jenkins admin password immediately
2. Enable Jenkins security settings
3. Use AWS IAM roles instead of access keys
4. Rotate credentials every 90 days
5. Keep EC2 security group restrictive
6. Enable SSL/TLS (optional but recommended)
7. Monitor webhook delivery logs
8. Audit Jenkins activity logs

## 📞 Need Help?

1. **Getting started?** → Read `JENKINS_SETUP_OVERVIEW.md`
2. **Stuck on setup?** → Read `JENKINS_SETUP_GUIDE.md`
3. **Webhook issues?** → Read `GITHUB_WEBHOOK_SETUP.md`
4. **EC2 problems?** → Read `EC2_JENKINS_INSTANCE_SETUP.md`
5. **Quick reference?** → Read `JENKINS_CI_REFERENCE.md`

## 🎓 Learning Resources

- Jenkins Documentation: https://www.jenkins.io/doc/
- Jenkins Plugins: https://plugins.jenkins.io/
- AWS ECR Guide: https://docs.aws.amazon.com/ecr/
- GitHub Webhooks: https://docs.github.com/en/developers/webhooks-and-events/webhooks
- Docker Documentation: https://docs.docker.com/

## ✅ Completion Checklist

- [ ] Reviewed all documentation files
- [ ] Created EC2 instance
- [ ] Installed Jenkins
- [ ] Configured credentials
- [ ] Created pipeline job
- [ ] Added GitHub webhook
- [ ] Tested automatic build trigger
- [ ] Verified images in ECR
- [ ] Monitored Jenkins logs
- [ ] Tested manual build with parameters

## 📊 File Statistics

| Type | Count | Lines |
|------|-------|-------|
| Scripts | 3 | 500+ |
| Documentation | 5 | 2000+ |
| Configuration | 1 | 300+ |
| **Total** | **9** | **2800+** |

## 🚀 Next Steps After Setup

After Jenkins is running:
1. **Deploy to ECS** - Use Jenkins to deploy to AWS ECS
2. **Add testing** - Integrate unit tests in pipeline
3. **Code quality** - Add SonarQube analysis
4. **Notifications** - Configure Slack/email alerts
5. **Monitoring** - Set up CloudWatch dashboards

## 📝 Version Info

- Created: January 16, 2026
- Updated: January 16, 2026
- Status: ✅ Ready for production use

---

**Ready to get started?** → Open `JENKINS_SETUP_OVERVIEW.md` now!
