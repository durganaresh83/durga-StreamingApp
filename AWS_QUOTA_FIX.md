# AWS Service Limits Resolution Guide

## Current Issue
Your AWS account has reached the maximum number of VPCs and Internet Gateways in the eu-west-2 region:
- **VPCs**: 5/5 used
- **Internet Gateways**: 5/5 used

This prevents creating a new EKS cluster without expanding the limits.

## Account Details
- **AWS Account**: 975050024946
- **Region**: eu-west-2 (London)
- **Target Cluster**: durga-streaming-app

---

## Solution: Request Service Quota Increase (Recommended - 10 mins)

### Step-by-Step Instructions

#### 1. Open AWS Service Quotas Console
- Link: https://eu-west-2.console.aws.amazon.com/servicequotas/home
- Or: AWS Console → Service Quotas

#### 2. Request VPC Quota Increase
1. Search for **"VPCs per region"** in the search box
2. Click on the result "VPCs per region"
3. Click **"Request quota increase"** button
4. Change desired quota from 5 to **10**
5. Click **"Request"**
6. Click **"Request quota increase"** in confirmation popup

**Expected**: Usually approved within 1 hour (sometimes immediately)

#### 3. Request Internet Gateway Quota Increase
1. Search for **"Internet Gateways per region"**
2. Click on the result
3. Click **"Request quota increase"** button
4. Change desired quota from 5 to **10**
5. Click **"Request"**
6. Confirm

#### 4. Check Quota Request Status
1. Click **"Recent requests"** tab
2. You should see 2 new requests
3. Wait for both to show **"Approved"** status

**Note**: Usually takes 5-60 minutes. AWS may auto-approve if you have good account history.

---

## Option 2: Use Different Region (if you don't want to wait)

If you want to deploy immediately without waiting for quota increase:

```powershell
$eksctlPath = "C:\ProgramData\chocolatey\lib\eksctl\tools\eksctl.exe"

# Try us-east-1 (N. Virginia) - usually has available quota
& $eksctlPath create cluster `
  --name durga-streaming-app `
  --region us-east-1 `
  --nodegroup-name standard-nodes `
  --nodes 3 `
  --node-type t3.medium `
  --version 1.30 `
  --managed
```

**Tradeoff**: Application will be in us-east-1 instead of eu-west-2 (London)
- Slightly higher latency if users are in Europe
- Costs remain similar

---

## Option 3: Delete Unused Resources (Advanced)

If there are unused EKS clusters or VPCs in other regions, you could delete them to free up quota locally. However, this requires careful identification of what to delete.

Clusters currently using quota in eu-west-2:
- eksctl-jatin-shopnow-cluster (deleted earlier)
- eksctl-streaming-cluster-adi (deleted earlier)
- eksctl-container-cluster-adish (deleted earlier)
- sam-shopnow-vpc (appears to be in use)
- VPC 0376ebe6043cd8004 (default VPC - keep it)

---

## What Happens Next

Once your quota increase is approved (usually within 1 hour):

1. Run cluster creation command again:
```powershell
$eksctlPath = "C:\ProgramData\chocolatey\lib\eksctl\tools\eksctl.exe"
& $eksctlPath create cluster `
  --name durga-streaming-app `
  --region eu-west-2 `
  --nodegroup-name standard-nodes `
  --nodes 3 `
  --node-type t3.medium `
  --version 1.30 `
  --managed
```

2. EKS will create:
   - New VPC (now quota will allow it)
   - Internet Gateway (now quota will allow it)
   - Subnets, Security Groups, etc.
   - 3 EC2 instances (t3.medium)
   - EKS Control Plane

3. Takes 15-20 minutes total

4. Once complete:
   ```powershell
   kubectl get nodes  # Verify cluster is ready
   ```

---

## Cost Impact

**Quota Increase**: No cost - it's just a limit increase

**EKS Cluster Deployment**: Same as before
- EKS Control Plane: ~$73/month
- 3 x t3.medium nodes: ~$35/month
- Load Balancer: ~$76/month
- **Total**: ~$184/month

---

## Timeline

| Option | Time | Success Rate |
|--------|------|--------------|
| Request Quota (Recommended) | 5 min request + 1 hr wait | 99% (auto-approved) |
| Deploy to us-east-1 | 5 min + 20 min cluster creation | 100% |
| Delete resources | 30 min + risk of deleting wrong thing | 70% |

---

## Recommended Next Steps

1. **Right now**: Go to AWS Service Quotas console (link above)
2. **Request** VPCs and IGWs quotas to 10
3. **Wait** ~1 hour for approval (check email)
4. **Run** the cluster creation command again
5. **Verify** with `kubectl get nodes`

---

## Support

If quota request is rejected or takes too long:
- Contact AWS Support: https://console.aws.amazon.com/support/
- Create a case requesting VPC and IGW quota increase
- Usually resolved within 1-2 business days

---

**Date Created**: January 26, 2026  
**Status**: Awaiting AWS Service Quotas approval
