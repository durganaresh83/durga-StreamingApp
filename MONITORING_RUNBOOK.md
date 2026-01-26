# Monitoring & Logging Operations Runbook

**EKS Cluster**: durga-streaming-app  
**Region**: eu-west-2  
**Created**: January 26, 2026

---

## Quick Reference

### View Live Logs
```bash
# Recent logs from all application pods
kubectl logs -n durga-streaming --all-containers=true -f -l app=auth-service

# Logs from specific pod
kubectl logs -f <pod-name> -n durga-streaming

# Logs from specific container in a pod
kubectl logs -f <pod-name> -c <container-name> -n durga-streaming
```

### Monitor Cluster Events
```bash
# Watch pod events in real-time
kubectl get events -n durga-streaming -w

# Get detailed pod information
kubectl describe pod <pod-name> -n durga-streaming

# Check node status
kubectl get nodes -o wide

# View resource usage
kubectl top pods -n durga-streaming
kubectl top nodes
```

### Access CloudWatch Logs

**AWS Console Path**:
```
CloudWatch → Logs → Log Groups → /aws/eks/durga-streaming-app/
```

**Available Log Groups**:
1. `/aws/eks/durga-streaming-app/cluster` - EKS control plane logs
2. `/aws/eks/durga-streaming-app/pods` - Kubernetes pod events
3. `/aws/eks/durga-streaming-app/application` - Application logs via Fluent Bit

---

## Common Monitoring Tasks

### Task 1: Find Application Errors

**In CloudWatch Console**:
1. Go to Logs Insights
2. Select log group: `/aws/eks/durga-streaming-app/application`
3. Run query:
```sql
fields @timestamp, @message, kubernetes.pod_name 
| filter @message like /ERROR/ 
| stats count() by kubernetes.pod_name
```

**Result**: Shows error count per pod

---

### Task 2: Identify Failing Pods

**Step 1**: Check pod status
```bash
kubectl get pods -n durga-streaming --sort-by=.metadata.creationTimestamp
```

**Step 2**: Describe failing pod
```bash
kubectl describe pod <pod-name> -n durga-streaming
# Look for "Events" section showing why pod failed
```

**Step 3**: Check logs
```bash
kubectl logs <pod-name> -n durga-streaming
# Or view previous logs if pod crashed
kubectl logs <pod-name> -n durga-streaming --previous
```

---

### Task 3: Monitor API Performance

**In CloudWatch Logs Insights**:
```sql
fields @timestamp, @duration 
| filter ispresent(@duration) 
| stats avg(@duration), max(@duration), pct(@duration, 99)
```

**Interpretation**:
- `avg(@duration)`: Average response time (ms)
- `max(@duration)`: Slowest response
- `pct(@duration, 99)`: 99th percentile (P99 latency)

---

### Task 4: Check Resource Usage

**CPU Usage**:
```bash
kubectl top pods -n durga-streaming --containers
```

**Memory Usage**:
```bash
kubectl get pods -n durga-streaming -o json | \
  jq '.items[] | {pod: .metadata.name, memory: .spec.containers[].resources.limits.memory}'
```

**Storage**:
```bash
kubectl get pvc -n durga-streaming
```

---

### Task 5: Set Up Alert Subscriptions

**Subscribe to Alerts via Email**:
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:eu-west-2:975050024946:durga-streaming-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com \
  --region eu-west-2
```

**Confirm subscription** (check your email inbox)

---

## Dashboards & Queries

### Pre-configured Queries Reference

| Name | Purpose | Query |
|------|---------|-------|
| **Errors** | Find all errors in logs | `filter @message like /ERROR/` |
| **Pod Restarts** | Identify unstable pods | `filter @message like /restarted/` |
| **Auth Failures** | Security monitoring | `filter @message like /auth.*fail/` |
| **API Times** | Performance analysis | `filter ispresent(@duration)` |
| **Memory** | Resource monitoring | `filter @message like /memory/` |

---

## Troubleshooting

### Issue: No logs appearing in CloudWatch

**Check 1**: Verify Fluent Bit is running
```bash
kubectl get pods -n monitoring
kubectl logs -f -l app=fluent-bit -n monitoring
```

**Check 2**: Verify IAM permissions
```bash
# Check node IAM role has CloudWatch Logs permissions
aws iam get-role-policy --role-name <eks-node-role> \
  --policy-name CloudWatchLogsPolicy --region eu-west-2
```

**Check 3**: Verify log group exists
```bash
aws logs describe-log-groups --region eu-west-2 | grep durga-streaming
```

---

### Issue: High log storage costs

**Reduce retention period**:
```bash
aws logs put-retention-policy \
  --log-group-name /aws/eks/durga-streaming-app/application \
  --retention-in-days 7 \
  --region eu-west-2
```

**Filter logs at source** (in fluent-bit-config.yaml):
```yaml
[OUTPUT]
    Name  exclude  # Exclude certain logs
    ...
```

---

### Issue: Missing pod restart events

**Verify pod restart monitoring**:
```bash
kubectl get pods -n durga-streaming -o json | \
  jq '.items[] | {pod: .metadata.name, restarts: .status.containerStatuses[].restartCount}'
```

**View restart reasons**:
```bash
kubectl describe pod <pod-name> -n durga-streaming
# Look for LastState → Terminated → Reason
```

---

## Performance Baselines

| Metric | Healthy Range | Warning | Critical |
|--------|---------------|---------|----------|
| Pod Ready % | 100% | <95% | <80% |
| Error Rate | <0.1% | 0.1-1% | >1% |
| P99 Latency | <200ms | 200-500ms | >500ms |
| Memory Usage | <60% | 60-80% | >80% |
| CPU Usage | <50% | 50-80% | >80% |

---

## Alert Configuration

### Creating a Custom Alarm

**Example**: Alert when error rate exceeds 1%

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name durga-streaming-high-error-rate \
  --alarm-description "Alert when error rate > 1%" \
  --metric-name ErrorCount \
  --namespace AWS/EKS \
  --statistic Sum \
  --period 300 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:eu-west-2:975050024946:durga-streaming-alerts \
  --region eu-west-2
```

---

## Daily Operations Checklist

**Every Day**:
- [ ] Check pod status: `kubectl get pods -n durga-streaming`
- [ ] Review error rate in CloudWatch
- [ ] Verify all services responding: `kubectl get svc -n durga-streaming`

**Weekly**:
- [ ] Review performance metrics (P99 latency, error rate trends)
- [ ] Check storage usage: `kubectl get pvc`
- [ ] Review CloudWatch log retention settings
- [ ] Test alert notifications

**Monthly**:
- [ ] Review cost analysis in CloudWatch
- [ ] Update retention policies if needed
- [ ] Analyze trends for capacity planning
- [ ] Update runbook based on issues found

---

## Emergency Contacts & Escalation

**Immediate Issues**:
- Check logs: `kubectl logs -f <pod-name>`
- Restart pod: `kubectl delete pod <pod-name> -n durga-streaming`
- Check events: `kubectl describe pod <pod-name> -n durga-streaming`

**Escalation**:
- AWS Support (for infrastructure issues)
- Application team (for application logic issues)
- Security team (for authentication/authorization failures)

---

## Related Documentation

- **EKS Documentation**: https://docs.aws.amazon.com/eks/
- **CloudWatch Logs**: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/
- **Fluent Bit**: https://docs.fluentbit.io/
- **Kubernetes Logging**: https://kubernetes.io/docs/concepts/cluster-administration/logging/

---

**Last Updated**: January 26, 2026  
**Next Review**: February 26, 2026
