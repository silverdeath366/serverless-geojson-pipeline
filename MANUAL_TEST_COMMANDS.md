# Manual Test Commands - Step by Step

Run these commands one by one and share the outputs.

## Step 1: Get Infrastructure Details

```bash
cd terraform

# Get S3 bucket name
terraform output -raw s3_bucket_name

# Get Lambda function name
terraform output -raw lambda_function_name

# Get CloudWatch log group name
terraform output -raw cloudwatch_log_group_name

# Get database endpoint
terraform output -raw db_endpoint
```

**Share these values with me.**

---

## Step 2: Verify S3 Bucket Exists

```bash
# Replace $BUCKET with the value from Step 1
aws s3 ls s3://$BUCKET/
```

**Expected:** Should list files (or be empty but no error)

---

## Step 3: Verify Lambda Function Status

```bash
# Replace $LAMBDA with the value from Step 1
aws lambda get-function --function-name "$LAMBDA" --query 'Configuration.[State,CodeSize,LastModified]' --output table
```

**Expected:** 
- State: `Active`
- CodeSize: Should be > 1,000,000 bytes (1MB) if dependencies are included

---

## Step 4: Create Test GeoJSON File

```bash
cat > /tmp/test_manual.geojson << 'EOF'
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

# Verify file was created
cat /tmp/test_manual.geojson
```

---

## Step 5: Upload Test File to S3

```bash
# Replace $BUCKET with the value from Step 1
aws s3 cp /tmp/test_manual.geojson s3://$BUCKET/test_data/test_manual.geojson
```

**Expected:** `upload: ... to s3://...`

---

## Step 6: Wait for Lambda Processing

```bash
echo "Waiting 30 seconds for Lambda to process..."
sleep 30
echo "Done waiting"
```

---

## Step 7: Check Lambda Logs

```bash
# Replace $LOG_GROUP with the value from Step 1
aws logs tail "$LOG_GROUP" --since 2m --format short
```

**Share the output.** Look for:
- ✅ "Successfully processed X features"
- ❌ "ERROR" or "Runtime.ImportModuleError"

---

## Step 8: Check for Errors in Logs

```bash
# Replace $LOG_GROUP with the value from Step 1
aws logs filter-log-events \
  --log-group-name "$LOG_GROUP" \
  --start-time $(($(date +%s) - 300))000 \
  --filter-pattern "ERROR" \
  --query 'events[*].message' \
  --output text
```

**Share the output.** Should be empty if no errors.

---

## Step 9: Check Lambda Invocations

```bash
# Replace $LAMBDA with the value from Step 1
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=$LAMBDA \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --output table
```

**Share the output.** Should show Invocations > 0.

---

## Step 10: Check Lambda Errors

```bash
# Replace $LAMBDA with the value from Step 1
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

**Share the output.** Should show Errors = 0 or empty.

---

## Step 11: Verify S3 Event Trigger

```bash
# Replace $BUCKET with the value from Step 1
aws s3api get-bucket-notification-configuration --bucket $BUCKET
```

**Share the output.** Should show Lambda function configuration.

---

## Step 12: Manually Invoke Lambda (Optional Test)

If you want to test Lambda directly:

```bash
# Replace $LAMBDA and $BUCKET with values from Step 1
aws lambda invoke \
  --function-name "$LAMBDA" \
  --payload '{
    "Records": [{
      "s3": {
        "bucket": {"name": "'$BUCKET'"},
        "object": {"key": "test_data/test_manual.geojson"}
      }
    }]
  }' \
  /tmp/lambda_response.json

# View response
cat /tmp/lambda_response.json
```

**Share the output.**

---

## Summary Checklist

After running all commands, verify:

- [ ] S3 bucket exists and is accessible
- [ ] Lambda function is `Active`
- [ ] Lambda code size > 1MB (dependencies included)
- [ ] Test file uploaded successfully
- [ ] Logs show "Successfully processed" message
- [ ] No ERROR messages in logs
- [ ] Invocations > 0
- [ ] Errors = 0
- [ ] S3 trigger configured

**Share all outputs and I'll help interpret them!**

