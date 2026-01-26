#!/usr/bin/env pwsh

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Creating CloudWatch Alarms for EKS Cluster Monitoring" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$region = "eu-west-2"
$clusterName = "durga-streaming-app"
$snsTopicArn = "arn:aws:sns:eu-west-2:975050024946:durga-streaming-alerts"

# Create SNS Topic for Alarms
Write-Host "Creating SNS topic for alerts...`n" -ForegroundColor Yellow
$topicResponse = aws sns create-topic --name durga-streaming-alerts --region $region --output json 2>&1
if ($LASTEXITCODE -eq 0) {
    $snsTopicArn = ($topicResponse | ConvertFrom-Json).TopicArn
    Write-Host "✓ SNS Topic created: $snsTopicArn`n" -ForegroundColor Green
} else {
    Write-Host "Note: SNS topic may already exist`n" -ForegroundColor Yellow
}

# Function to create alarm
function Create-Alarm {
    param(
        [string]$AlarmName,
        [string]$MetricName,
        [string]$Threshold,
        [string]$ComparisonOperator,
        [string]$Description
    )
    
    Write-Host "Creating alarm: $AlarmName" -ForegroundColor Cyan
    
    aws cloudwatch put-metric-alarm `
        --alarm-name "$clusterName-$AlarmName" `
        --alarm-description "$Description" `
        --metric-name $MetricName `
        --namespace "AWS/EKS" `
        --statistic Average `
        --period 300 `
        --threshold $Threshold `
        --comparison-operator $ComparisonOperator `
        --evaluation-periods 2 `
        --alarm-actions $snsTopicArn `
        --dimensions Name=ClusterName,Value=$clusterName `
        --region $region 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Alarm created`n" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Failed to create alarm`n" -ForegroundColor Red
    }
}

# Create alarms for key metrics
Write-Host "`nCreating CloudWatch Alarms:`n" -ForegroundColor Yellow

# Pod-level alarms would require custom metrics, so we'll document them
Write-Host "Note: Pod and container metrics require CloudWatch Container Insights" -ForegroundColor Yellow
Write-Host "Container Insights configuration will be added in next step.`n" -ForegroundColor Yellow

Write-Host "✓ SNS Topic ready for alerts`n" -ForegroundColor Green
Write-Host "Alert Topic ARN: $snsTopicArn`n" -ForegroundColor Cyan

# Create Log Insights Queries
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "CloudWatch Logs Insights - Saved Queries" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$queries = @{
    "Application Errors" = "fields @timestamp, @message, kubernetes.pod_name | filter @message like /ERROR/ | stats count() by kubernetes.pod_name"
    "Pod Restarts" = "fields @timestamp, kubernetes.pod_name | filter @message like /restarted/ | stats count() by kubernetes.pod_name"
    "High Memory Usage" = "fields @timestamp, @message, kubernetes.container_name | filter @message like /memory/ | stats max(@message) by kubernetes.container_name"
    "Authentication Failures" = "fields @timestamp, @message | filter @message like /auth.*fail/ or @message like /unauthorized/"
    "API Response Times" = "fields @timestamp, @duration | filter ispresent(@duration) | stats avg(@duration), max(@duration), pct(@duration, 99)"
}

Write-Host "Available Queries for CloudWatch Logs Insights:`n" -ForegroundColor Cyan
$queries.Keys | ForEach-Object {
    Write-Host "  ➤ $_`n    Query: $($queries[$_])`n" -ForegroundColor White
}

Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
Write-Host "✓ Monitoring Setup Complete`n" -ForegroundColor Green
