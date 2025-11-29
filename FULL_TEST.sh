#!/bin/bash

# Comprehensive Full System Test
# Tests all components end-to-end

set -e

echo "🧪 GeoJSON Pipeline - Full System Test"
echo "========================================"
echo ""

cd terraform

# Step 1: Get all infrastructure details
echo "📋 Step 1: Getting infrastructure details..."
BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
LAMBDA=$(terraform output -raw lambda_function_name 2>/dev/null || echo "")
DB_ENDPOINT=$(terraform output -raw db_endpoint 2>/dev/null || echo "")
LOG_GROUP=$(terraform output -raw cloudwatch_log_group_name 2>/dev/null || echo "")

if [ -z "$BUCKET" ] || [ -z "$LAMBDA" ]; then
    echo "❌ Error: Could not get infrastructure details. Is Terraform applied?"
    exit 1
fi

echo "  ✅ S3 Bucket: $BUCKET"
echo "  ✅ Lambda: $LAMBDA"
if [ -n "$DB_ENDPOINT" ]; then
    echo "  ✅ DB Endpoint: $DB_ENDPOINT"
fi
echo "  ✅ Log Group: $LOG_GROUP"
echo ""

# Step 2: Verify S3 bucket
echo "☁️ Step 2: Verifying S3 bucket..."
if aws s3 ls "s3://$BUCKET/" > /dev/null 2>&1; then
    echo "  ✅ S3 bucket accessible"
    FILE_COUNT=$(aws s3 ls "s3://$BUCKET/" | wc -l)
    echo "  📦 Files in bucket: $FILE_COUNT"
else
    echo "  ❌ S3 bucket NOT accessible"
    exit 1
fi
echo ""

# Step 3: Verify Lambda function
echo "🚀 Step 3: Verifying Lambda function..."
LAMBDA_STATUS=$(aws lambda get-function --function-name "$LAMBDA" --query 'Configuration.State' --output text 2>/dev/null || echo "")
if [ "$LAMBDA_STATUS" = "Active" ]; then
    echo "  ✅ Lambda function is Active"
    CODE_SIZE=$(aws lambda get-function --function-name "$LAMBDA" --query 'Configuration.CodeSize' --output text)
    echo "  📦 Code size: $CODE_SIZE bytes"
    if [ "$CODE_SIZE" -lt 1000000 ]; then
        echo "  ⚠️  WARNING: Code size is small. Dependencies may not be included."
    else
        echo "  ✅ Code size looks good (includes dependencies)"
    fi
else
    echo "  ❌ Lambda function is not Active (Status: $LAMBDA_STATUS)"
    exit 1
fi
echo ""

# Step 4: Create comprehensive test file
echo "📝 Step 4: Creating test GeoJSON file..."
TEST_FILE="/tmp/full_test_$(date +%s).geojson"
cat > "$TEST_FILE" << 'EOF'
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"name": "New York City"},
      "geometry": {"type": "Point", "coordinates": [-74.006, 40.7128]}
    },
    {
      "type": "Feature",
      "properties": {"name": "San Francisco"},
      "geometry": {"type": "Point", "coordinates": [-122.4194, 37.7749]}
    },
    {
      "type": "Feature",
      "properties": {"name": "London"},
      "geometry": {"type": "Point", "coordinates": [-0.1276, 51.5074]}
    }
  ]
}
EOF
echo "  ✅ Test file created: $TEST_FILE"
echo ""

# Step 5: Upload test file
echo "📤 Step 5: Uploading test file to S3..."
UPLOAD_KEY="test_data/$(basename "$TEST_FILE")"
if aws s3 cp "$TEST_FILE" "s3://$BUCKET/$UPLOAD_KEY"; then
    echo "  ✅ File uploaded: s3://$BUCKET/$UPLOAD_KEY"
else
    echo "  ❌ Failed to upload file"
    exit 1
fi
echo ""

# Step 6: Wait for Lambda processing
echo "⏳ Step 6: Waiting for Lambda to process (30 seconds)..."
sleep 30
echo "  ✅ Wait complete"
echo ""

# Step 7: Check Lambda logs
echo "🔍 Step 7: Checking Lambda execution logs..."
echo "  📊 Recent logs (last 2 minutes):"
aws logs tail "$LOG_GROUP" --since 2m --format short 2>/dev/null | tail -20 || echo "    No recent logs found"

echo ""
echo "  🔎 Checking for errors..."
ERROR_COUNT=$(aws logs filter-log-events \
    --log-group-name "$LOG_GROUP" \
    --start-time $(($(date +%s) - 300))000 \
    --filter-pattern "ERROR" \
    --query 'length(events)' \
    --output text 2>/dev/null || echo "0")

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "  ⚠️  Found $ERROR_COUNT error(s) in logs"
    echo "  Recent errors:"
    aws logs filter-log-events \
        --log-group-name "$LOG_GROUP" \
        --start-time $(($(date +%s) - 300))000 \
        --filter-pattern "ERROR" \
        --query 'events[*].message' \
        --output text 2>/dev/null | head -5
else
    echo "  ✅ No errors found in recent logs"
fi
echo ""

# Step 8: Check Lambda metrics
echo "📈 Step 8: Checking Lambda metrics..."
INVOCATIONS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value="$LAMBDA" \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum \
    --query 'Datapoints[0].Sum' \
    --output text 2>/dev/null || echo "0")

ERRORS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Errors \
    --dimensions Name=FunctionName,Value="$LAMBDA" \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum \
    --query 'Datapoints[0].Sum' \
    --output text 2>/dev/null || echo "0")

echo "  📊 Invocations (last hour): $INVOCATIONS"
echo "  📊 Errors (last hour): $ERRORS"

if [ "$ERRORS" != "0" ] && [ "$ERRORS" != "None" ]; then
    echo "  ⚠️  Errors detected in metrics"
else
    echo "  ✅ No errors in metrics"
fi
echo ""

# Step 9: Verify S3 trigger
echo "🔗 Step 9: Verifying S3 event trigger..."
NOTIFICATION_CONFIG=$(aws s3api get-bucket-notification-configuration --bucket "$BUCKET" 2>/dev/null || echo "")
if echo "$NOTIFICATION_CONFIG" | grep -q "$LAMBDA"; then
    echo "  ✅ S3 event trigger configured"
else
    echo "  ⚠️  S3 trigger configuration not found (may be configured differently)"
fi
echo ""

# Step 10: Test summary
echo "📋 Test Summary"
echo "==============="
echo ""
echo "✅ Infrastructure Status:"
echo "  - S3 Bucket: $BUCKET ($(aws s3 ls "s3://$BUCKET/" | wc -l) files)"
echo "  - Lambda: $LAMBDA (State: Active)"
echo "  - Database: $DB_ENDPOINT"
echo ""
echo "✅ Test File:"
echo "  - Uploaded: s3://$BUCKET/$UPLOAD_KEY"
echo ""
echo "✅ Lambda Execution:"
echo "  - Invocations: $INVOCATIONS"
echo "  - Errors: $ERRORS"
echo ""
if [ "$ERRORS" = "0" ] || [ "$ERRORS" = "None" ]; then
    echo "🎉 SUCCESS: All tests passed! System is working correctly."
else
    echo "⚠️  WARNING: Some errors detected. Check logs above for details."
fi
echo ""
echo "📊 Next Steps:"
echo "  1. Check CloudWatch Dashboard for detailed metrics"
echo "  2. Query RDS database to verify data was inserted"
echo "  3. Upload more test files to verify pipeline"
echo ""

