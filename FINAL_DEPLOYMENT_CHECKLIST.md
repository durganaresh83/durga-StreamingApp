# FINAL ACTION CHECKLIST - Deploy Worker Nodes

**Status**: Ready to execute once SSM permission approved  
**Time Estimate**: 5 min (permission) + 20 min (deployment) = ~25 min total  
**Destination**: Full production deployment

---

## ✅ Pre-Deployment Checklist

Before running the deployment script, verify:

- [ ] SSM permission has been approved by admin
- [ ] You have AWS CLI credentials configured
- [ ] You have kubectl configured (kubeconfig updated)
- [ ] You have eksctl installed
- [ ] Internet connection is stable
- [ ] You're in the correct directory: `durga-StreamingApp`

---

## 🚀 Execution Steps

### Step 1: Navigate to Project Directory
```powershell
cd "C:\Durga Naresh\HeroVired\Assignments\durga-StreamingApp"
```

### Step 2: Run Automated Deployment Script
```powershell
.\EXECUTE_STEP_5_3.ps1
```

**What it does automatically**:
1. ✓ Verifies all 7 prerequisites
2. ✓ Confirms SSM permission is granted
3. ✓ Deploys 3 worker nodes (t3.medium)
4. ✓ Monitors node startup (up to 20 min)
5. ✓ Verifies pods transition to RUNNING
6. ✓ Displays final status

### Step 3: Monitor Deployment
The script displays live progress:
```
[1/7] Checking AWS CLI... ✓
[2/7] Checking eksctl... ✓
[3/7] Checking kubectl... ✓
[4/7] Verifying EKS cluster... ✓
[5/7] Checking nodegroup config... ✓
[6/7] Verifying SSM permission... ✓
[7/7] Checking EKS permissions... ✓

All Prerequisites Verified! Ready to Deploy Worker Nodes

Deploying nodegroup...
[Deployment log output...]

✓ NODEGROUP DEPLOYMENT SUCCESSFUL!
```

---

## 📊 Expected Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| SSM Permission Approval | 5-15 min | ⏳ Waiting |
| Verify Prerequisites | 1 min | 🟡 Script runs this |
| Deploy Nodes | 15-20 min | 🟡 Script runs this |
| Verify Node Status | 2-3 min | 🟡 Script runs this |
| **TOTAL** | **~25 min** | **Automated** |

---

## ✅ After Deployment Completes

### Verify Everything Worked

**1. Check nodes are READY** (within 30 seconds of script completion):
```bash
kubectl get nodes -o wide
# Expected: 3 nodes in Ready state
```

**2. Check pods are RUNNING**:
```bash
kubectl get pods -n durga-streaming -o wide
# Expected: 5 pods showing READY 1/1, STATUS Running
```

**3. Verify Fluent Bit collecting logs**:
```bash
kubectl get pods -n monitoring -o wide
# Expected: 3 fluent-bit pods Running
```

**4. Check CloudWatch logs** (should appear within 2-3 minutes):
```bash
aws logs tail /aws/eks/durga-streaming-app/application --follow
# Should show pod startup logs
```

---

## 🔍 Troubleshooting If Deployment Fails

### If Script Fails at SSM Permission Check
**Error**: `ssm:GetParameter` permission not granted

**Solution**: 
1. Verify with admin that permission was actually added
2. Wait 1-2 minutes for IAM cache to update
3. Run script again

### If Nodes Don't Become READY
**Error**: Nodes showing `NotReady` after 20 minutes

**Check CloudFormation stack**:
```bash
aws cloudformation describe-stacks \
  --stack-name eksctl-durga-streaming-app-nodegroup-standard-nodes \
  --region eu-west-2
```

**Check node events**:
```bash
kubectl describe node <node-name>
# Look for warning events
```

### If Pods Stay PENDING
**After nodes are READY**, pods should transition to RUNNING within 1-2 minutes

**Check pod events**:
```bash
kubectl describe pod <pod-name> -n durga-streaming
# Look for "Events" section
```

---

## 📋 Post-Deployment Verification Checklist

Once the script completes successfully:

- [ ] Run `kubectl get nodes` → See 3 nodes in READY state
- [ ] Run `kubectl get pods -n durga-streaming` → See 5 pods RUNNING
- [ ] Run `kubectl get pods -n monitoring` → See 3 fluent-bit pods RUNNING
- [ ] Check CloudWatch logs → See application startup logs appearing
- [ ] Verify SNS topic ready → Check alerts can be subscribed
- [ ] Review monitoring dashboard → See cluster metrics

---

## 🎯 Next Steps (After Nodes Ready)

### Immediate (5 minutes)
1. Get ALB endpoint
2. Test health endpoints
3. Verify services responding

### Short-term (30 minutes)
1. Subscribe to SNS alerts
2. Configure custom dashboards
3. Run full test suite (Step 7)

### Long-term (After testing)
1. Setup DNS (optional)
2. Configure SSL/TLS (optional)
3. Production handoff complete ✓

---

## 💡 Success Indicators

✅ **Deployment is successful when**:
- All 3 nodes show `Ready` status
- All 5 pods show `1/1` Ready
- All pods show `Running` status
- Fluent Bit pods collecting logs
- No pods in `Pending`, `CrashLoopBackOff`, or `Error` states
- CloudWatch logs show application output
- SNS topic can receive subscriptions

---

## 📞 Support

| Issue | Reference |
|-------|-----------|
| Pre-deployment questions | `STATUS_QUICK_REFERENCE.md` |
| Troubleshooting | `MONITORING_RUNBOOK.md` |
| Architecture questions | `STEP_6_MONITORING_SUMMARY.md` |
| Overall status | `DEPLOYMENT_STATUS_REPORT.md` |

---

## 🎓 Important Notes

1. **Script is idempotent**: Can be run multiple times safely
2. **Logs saved**: Deployment log saved to `nodegroup-deployment-*.log`
3. **Automatic monitoring**: Script monitors node startup for you
4. **No manual intervention**: All steps automated
5. **Production-ready**: Configuration follows AWS best practices

---

## Final Checklist

- [ ] SSM permission approved and active
- [ ] All prerequisites verified
- [ ] Ready to execute: `.\EXECUTE_STEP_5_3.ps1`
- [ ] Have 25 minutes available for deployment
- [ ] Can monitor output during execution

---

**Status**: ✅ Ready to proceed  
**Next Action**: Wait for SSM permission → Run EXECUTE_STEP_5_3.ps1  
**Expected Completion**: ~20-25 minutes after execution starts

Good luck! 🚀
