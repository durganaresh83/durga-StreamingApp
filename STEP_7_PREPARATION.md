# Step 7: Ingress Configuration & Testing (Preparation Guide)

**Status**: 🟡 Ready to Execute (Awaiting worker nodes)  
**Estimated Time**: 15-20 minutes (after nodes are available)

---

## Prerequisites Checklist

Before executing Step 7, verify:

- [ ] Worker nodes deployed and READY (Step 5.3 complete)
- [ ] All pods in `durga-streaming` namespace are RUNNING
- [ ] Fluent Bit pods in `monitoring` namespace are RUNNING
- [ ] ALB ingress controller operational

---

## Architecture Overview

```
Internet
   ↓
ALB (Application Load Balancer)
   ↓
Ingress Controller (ALB Ingress)
   ↓
Services (ClusterIP)
   ↓
Pods (Frontend, Auth, Streaming, Admin, Chat)
   ↓
MongoDB (Persistent Volume)
```

---

## Current Ingress Configuration

**Location**: `helm/durga-streaming/templates/ingress.yaml`

**Current Setup**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: durga-streaming-ingress
  namespace: durga-streaming
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - host: streaming.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: auth-service
                port:
                  number: 3001
```

---

## Step-by-Step Testing Plan

### Phase 1: Verify Infrastructure (5 min)

**Command 1**: Check all pods are running
```bash
kubectl get pods -n durga-streaming -o wide
# Expected: All pods should show READY 1/1, STATUS Running
```

**Command 2**: Check services
```bash
kubectl get svc -n durga-streaming
# Expected: See 3 services (frontend, auth-service, mongodb)
```

**Command 3**: Check ingress status
```bash
kubectl get ingress -n durga-streaming -o wide
# Expected: See ADDRESS (ALB DNS name)
```

---

### Phase 2: Get ALB Endpoint (2 min)

**Extract ALB DNS Name**:
```bash
# Get the ALB endpoint
INGRESS_HOST=$(kubectl get ingress durga-streaming-ingress \
  -n durga-streaming \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "ALB Endpoint: $INGRESS_HOST"
```

**Example Output**:
```
ALB Endpoint: k8s-durga-<random>.eu-west-2.elb.amazonaws.com
```

---

### Phase 3: Test Health Endpoints (3 min)

**Test Frontend Service**:
```bash
curl http://$INGRESS_HOST/ -I
# Expected: HTTP 200 or 304
```

**Test Auth Service API**:
```bash
curl http://$INGRESS_HOST/api/health -I
# Expected: HTTP 200
```

**Full Response Test**:
```bash
curl -v http://$INGRESS_HOST/api/health
# Expected: JSON health check response
```

---

### Phase 4: Monitor Logs During Testing (5 min)

**Watch Application Logs**:
```bash
kubectl logs -f -l app=frontend -n durga-streaming
```

**Watch Auth Service Logs**:
```bash
kubectl logs -f -l app=auth-service -n durga-streaming
```

**Monitor All Events**:
```bash
kubectl get events -n durga-streaming -w
```

---

### Phase 5: Verify CloudWatch Logs (3 min)

**Check CloudWatch Log Groups**:
```bash
aws logs describe-log-groups \
  --region eu-west-2 | grep durga-streaming
```

**Query Recent Logs**:
```bash
aws logs filter-log-events \
  --log-group-name /aws/eks/durga-streaming-app/application \
  --start-time $(($(date +%s%N) - 600000000000)) \
  --region eu-west-2
```

**Run Logs Insights Query**:
In AWS Console → CloudWatch → Logs Insights → Select log group → Run:
```sql
fields @timestamp, @message, kubernetes.pod_name
| filter ispresent(@message)
| stats count() by kubernetes.pod_name
```

---

## Testing Scenarios

### Scenario 1: Normal Traffic Load

**Test Plan**:
1. Generate continuous traffic to ALB
2. Monitor response times
3. Check for errors in logs

**Commands**:
```bash
# Install ab (Apache Bench) if needed
apt-get install apache2-utils

# Generate 100 requests with 10 concurrent connections
ab -n 100 -c 10 http://$INGRESS_HOST/

# Expected results:
# - Response time: <200ms average
# - Success rate: 100%
```

---

### Scenario 2: Authentication Test

**Test Plan**:
1. Test login endpoint
2. Verify JWT token generation
3. Test API access with token

**Commands**:
```bash
# Test registration/login
curl -X POST http://$INGRESS_HOST/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Expected: JWT token in response
```

---

### Scenario 3: Error Monitoring

**Test Plan**:
1. Send invalid requests
2. Verify error logging
3. Check CloudWatch Logs Insights

**Commands**:
```bash
# Send invalid request
curl http://$INGRESS_HOST/api/nonexistent

# Query errors in CloudWatch
aws logs filter-log-events \
  --log-group-name /aws/eks/durga-streaming-app/application \
  --filter-pattern "ERROR"
```

---

## DNS Configuration

### Option 1: Use ALB DNS Directly (Temporary)
```
http://k8s-durga-<random>.eu-west-2.elb.amazonaws.com/
```

### Option 2: Create Route53 Record (Production)

**Prerequisites**: 
- Hosted Zone in Route53
- Domain: `streaming.example.com` (or your domain)

**Commands**:
```bash
# Get ALB endpoint
ALB_DNS=$(kubectl get ingress durga-streaming-ingress \
  -n durga-streaming \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Get ALB hosted zone ID
ALB_ZONE_ID=$(aws elbv2 describe-load-balancers \
  --names k8s-durga-* \
  --region eu-west-2 \
  --query 'LoadBalancers[0].CanonicalHostedZoneId' \
  --output text)

# Create Route53 record (via AWS Console or CLI)
aws route53 change-resource-record-sets \
  --hosted-zone-id <YOUR_ZONE_ID> \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"CREATE\",
      \"ResourceRecordSet\": {
        \"Name\": \"streaming.example.com\",
        \"Type\": \"A\",
        \"AliasTarget\": {
          \"HostedZoneId\": \"$ALB_ZONE_ID\",
          \"DNSName\": \"$ALB_DNS\",
          \"EvaluateTargetHealth\": false
        }
      }
    }]
  }"
```

---

## SSL/TLS Configuration (Optional)

### Enable HTTPS with ACM Certificate

**Prerequisites**:
- AWS Certificate Manager certificate
- Certificate ARN

**Update Ingress**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: durga-streaming-ingress
  namespace: durga-streaming
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
spec:
  # ... rest of configuration
```

---

## Troubleshooting Guide

### Issue 1: Ingress shows no ADDRESS

**Diagnosis**:
```bash
kubectl describe ingress durga-streaming-ingress -n durga-streaming
```

**Causes**:
- ALB Ingress Controller not running
- No nodes available
- IAM permissions issue

**Fix**:
```bash
# Check ALB Ingress Controller
kubectl get deployment -n kube-system | grep alb

# Check for pending pods
kubectl get pods -A --field-selector=status.phase=Pending
```

---

### Issue 2: Service Unreachable (502 Bad Gateway)

**Diagnosis**:
```bash
# Check target health
kubectl get endpoints -n durga-streaming

# Check pod logs
kubectl logs -f -l app=frontend -n durga-streaming
```

**Possible Causes**:
- Pods not ready
- Service misconfiguration
- Network policies blocking traffic

**Fix**:
```bash
# Force pod restart
kubectl rollout restart deployment/frontend -n durga-streaming

# Wait for readiness
kubectl rollout status deployment/frontend -n durga-streaming
```

---

### Issue 3: High Latency

**Diagnosis**:
```bash
# Check pod resource usage
kubectl top pods -n durga-streaming

# Monitor ALB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time 2026-01-26T00:00:00Z \
  --end-time 2026-01-26T23:59:59Z \
  --period 300 \
  --statistics Average
```

**Optimization**:
- Increase pod replicas
- Adjust resource limits
- Enable connection pooling

---

## Success Criteria

✅ **Step 7 Complete When**:
- [ ] ALB endpoint returns HTTP 200 responses
- [ ] All services are accessible via ALB
- [ ] Logs appear in CloudWatch
- [ ] No 502/503 errors in responses
- [ ] Average response time < 200ms
- [ ] 100% success rate in health checks

---

## Next Steps (After Step 7)

1. **Performance Optimization**:
   - Implement auto-scaling policies
   - Configure pod disruption budgets
   - Set up performance monitoring

2. **Security Hardening**:
   - Enable WAF on ALB
   - Configure network policies
   - Implement pod security policies

3. **Production Readiness**:
   - Enable automatic backups
   - Configure disaster recovery
   - Implement cost optimization

---

## Estimated Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| 1. Infrastructure Verification | 5 min | 🟡 Pending nodes |
| 2. ALB Endpoint Extraction | 2 min | 🟡 Pending nodes |
| 3. Health Endpoint Testing | 3 min | 🟡 Pending nodes |
| 4. Log Monitoring | 5 min | 🟡 Pending nodes |
| 5. CloudWatch Verification | 3 min | 🟡 Pending nodes |
| 6. Advanced Testing | 10 min | 🟡 Pending nodes |
| 7. DNS/SSL Setup | 10 min | 🟡 Optional |
| **Total** | **~38 min** | **🟡 Blocked** |

---

## Commands Quick Reference

```bash
# Get ALB endpoint
kubectl get ingress -n durga-streaming -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'

# Test all services
curl http://$ALB_ENDPOINT/
curl http://$ALB_ENDPOINT/api/health

# Monitor in real-time
kubectl get pods -n durga-streaming -w

# Check CloudWatch logs
aws logs tail /aws/eks/durga-streaming-app/application --follow

# Troubleshoot
kubectl describe pod <pod-name> -n durga-streaming
kubectl logs <pod-name> -n durga-streaming
```

---

**Status**: Ready to execute once worker nodes (Step 5.3) are available.

**Last Updated**: January 26, 2026  
**Prepared By**: Infrastructure Team
