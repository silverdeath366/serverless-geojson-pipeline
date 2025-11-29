# Complete System Test Guide

## Quick Test Commands

After successful `terraform apply`, run these commands to verify everything works:

### 1. Get Infrastructure Details
```bash
cd terraform

export BUCKET=$(terraform output -raw s3_bucket_name)
export LAMBDA=$(terraform output -raw lambda_function_name)
export LOG_GROUP=$(terraform output -raw cloudwatch_log_group_name)

echo "Bucket: $BUCKET"
echo "Lambda: $LAMBDA"
echo "Logs: $LOG_GROUP"
```

### 2. Verify S3 Bucket
```bash
aws s3 ls s3://$BUCKET/
```

### 3. Verify Lambda Function
```bash
# Check Lambda status
aws lambda get-function --function-name "$LAMBDA" --query 'Configuration.State'

# Check code size (should be large if dependencies included)
aws lambda get-function --function-name "$LAMBDA" --query 'Configuration.CodeSize'
```

### 4. Create and Upload Test File
```bash
# Create test GeoJSON
cat > /tmp/test_full.geojson << 'EOF'
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"name": "Test Point 1"},
      "geometry": {"type": "Point", "coordinates": [-74.006, 40.7128]}
    },
    {
      "type": "Feature",
      "properties": {"name": "Test Point 2"},
      "geometry": {"type": "Point", "coordinates": [-122.4194, 37.7749]}
    }
  ]
}
EOF

# Upload to S3
aws s3 cp /tmp/test_full.geojson s3://$BUCKET/test_data/
```

### 5. Wait and Check Logs
```bash
# Wait 30 seconds for Lambda to process
sleep 30

# Check logs
aws logs tail "$LOG_GROUP" --since 2m --format short
```

### 6. Check for Errors
```bash
# Check for ERROR in logs
aws logs filter-log-events \
  --log-group-name "$LOG_GROUP" \
  --start-time $(($(date +%s) - 300))000 \
  --filter-pattern "ERROR" \
  --query 'events[*].message' \
  --output text
```

### 7. Check Lambda Metrics
```bash
# Get invocation count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=$LAMBDA \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --output table

# Get error count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=$LAMBDA \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --output table
```

### 8. Verify S3 Trigger
```bash
aws s3api get-bucket-notification-configuration --bucket $BUCKET
```

## Automated Full Test

Run the automated test script:

```bash
chmod +x FULL_TEST.sh
./FULL_TEST.sh
```

This will:
- ✅ Verify all infrastructure components
- ✅ Upload a test file
- ✅ Wait for processing
- ✅ Check logs for errors
- ✅ Verify metrics
- ✅ Provide a summary

## Expected Results

### ✅ Success Indicators:
- Lambda state: `Active`
- Code size: > 1MB (includes dependencies)
- Invocations: > 0
- Errors: 0
- Logs show: "Successfully processed X features"
- No ERROR messages in logs

### ❌ Failure Indicators:
- Lambda state: not `Active`
- Code size: < 1MB (dependencies missing)
- Errors: > 0
- Logs show: "Runtime.ImportModuleError" or "psycopg2" errors
- ERROR messages in logs

## Troubleshooting

### If Lambda shows import errors:
```bash
# Rebuild Lambda package
cd terraform
terraform apply -target=module.lambda.null_resource.lambda_build -target=module.lambda.aws_lambda_function.main
```

### If no logs appear:
```bash
# Check log group exists
aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP"

# Check Lambda configuration
aws lambda get-function --function-name "$LAMBDA" --query 'Configuration.LoggingConfig'
```

### If S3 trigger not working:
```bash
# Manually invoke Lambda
aws lambda invoke \
  --function-name "$LAMBDA" \
  --payload '{
    "Records": [{
      "s3": {
        "bucket": {"name": "'$BUCKET'"},
        "object": {"key": "test_data/test_full.geojson"}
      }
    }]
  }' \
  /tmp/lambda_response.json

cat /tmp/lambda_response.json
```

