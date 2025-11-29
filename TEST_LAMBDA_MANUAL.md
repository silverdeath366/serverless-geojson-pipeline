# Manual Lambda Test - Check VPC Connectivity

The Lambda is in a VPC, which means it needs NAT Gateway to access:
- CloudWatch Logs (to write logs)
- S3 (to download files)
- Internet (for package downloads)

## Step 1: Check NAT Gateway Status

```bash
aws ec2 describe-nat-gateways \
  --filter 'Name=vpc-id,Values=vpc-0eb5a8389cbde2d96' \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' \
  --output table
```

## Step 2: Check DLQ for Failed Messages

```bash
aws sqs get-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/648126036223/dev-geojson-data-processor-dlq \
  --attribute-names ApproximateNumberOfMessages \
  --query 'Attributes.ApproximateNumberOfMessages' \
  --output text
```

If there are messages, check them:
```bash
aws sqs receive-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/648126036223/dev-geojson-data-processor-dlq \
  --max-number-of-messages 1
```

## Step 3: Wait and Check Metrics Again

S3 events can take 1-2 minutes to propagate. Wait 2 minutes after upload, then:

```bash
# Check invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=geojson-data-processor \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --output table

# Check errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=geojson-data-processor \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --output table
```

## Step 4: Upload Another File and Wait Longer

```bash
# Upload new file
aws s3 cp /tmp/test_manual.geojson s3://geojson-dev-data-pipeline-2024/test_data/test_manual3.geojson

# Wait 2 full minutes
sleep 120

# Check metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=geojson-data-processor \
  --start-time $(date -u -d '3 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --output table
```

Run these commands and share outputs!

