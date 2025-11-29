# Continue Testing - Lambda Not Showing Logs

## Step 1: Check if Lambda was Invoked

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=geojson-data-processor \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --output table
```

## Step 2: Check for Errors

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=geojson-data-processor \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --output table
```

## Step 3: Manually Invoke Lambda (Direct Test)

```bash
aws lambda invoke \
  --function-name geojson-data-processor \
  --payload '{
    "Records": [{
      "s3": {
        "bucket": {"name": "geojson-dev-data-pipeline-2024"},
        "object": {"key": "test_data/test_manual2.geojson"}
      }
    }]
  }' \
  /tmp/lambda_response.json

# View response
cat /tmp/lambda_response.json
```

## Step 4: Check Logs with Different Time Range

```bash
# Check last 10 minutes
aws logs tail "/aws/lambda/geojson-data-processor" --since 10m --format short

# Check all recent logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/geojson-data-processor" \
  --start-time $(($(date +%s) - 600))000 \
  --query 'events[*].[timestamp,message]' \
  --output text | head -20
```

## Step 5: Verify S3 Event Configuration

```bash
aws s3api get-bucket-notification-configuration --bucket geojson-dev-data-pipeline-2024
```

Run these commands and share all outputs!

