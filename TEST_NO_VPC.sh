#!/bin/bash
# Test Lambda after removing VPC config

echo "🧪 Testing Lambda WITHOUT VPC (Step 1 of fix plan)"
echo "=================================================="
echo ""

# Step 1: Upload test file
echo "📤 Step 1: Uploading test file..."
aws s3 cp /tmp/test_manual.geojson s3://geojson-dev-data-pipeline-2024/test_data/test_no_vpc.geojson

echo ""
echo "⏳ Step 2: Waiting 30 seconds for Lambda to process..."
sleep 30

echo ""
echo "🔍 Step 3: Checking for log streams (THIS IS THE KEY TEST)..."
LOG_STREAMS=$(aws logs describe-log-streams \
  --log-group-name '/aws/lambda/geojson-data-processor' \
  --max-items 5 \
  --query 'length(logStreams)' \
  --output text)

if [ "$LOG_STREAMS" -gt 0 ]; then
  echo "✅ SUCCESS! Log streams found: $LOG_STREAMS"
  echo ""
  echo "📋 Recent log streams:"
  aws logs describe-log-streams \
    --log-group-name '/aws/lambda/geojson-data-processor' \
    --max-items 5 \
    --order-by LastEventTime \
    --descending \
    --query 'logStreams[*].[logStreamName,lastEventTime]' \
    --output table
else
  echo "❌ Still no log streams. Issue is NOT VPC-related."
fi

echo ""
echo "📊 Step 4: Checking logs..."
aws logs tail "/aws/lambda/geojson-data-processor" --since 2m --format short

echo ""
echo "📈 Step 5: Checking metrics..."
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=geojson-data-processor \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --output table

echo ""
echo "✅ Test complete!"
echo ""
echo "If log streams appeared → VPC was the issue. Next: Add VPC endpoint for CloudWatch Logs"
echo "If no log streams → Issue is code/import related. Check logs above for errors."

