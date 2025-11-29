# Lambda Diagnosis - No Logs Appearing

## Problem Summary
- ✅ Lambda is being invoked (DLQ has 3 messages)
- ✅ Lambda code is updated (19MB with dependencies)
- ✅ Security groups are correct (Lambda can reach RDS)
- ✅ NAT Gateways are available
- ❌ No logs appearing in CloudWatch
- ❌ Lambda is failing (messages going to DLQ)

## Possible Causes

### 1. Lambda Can't Reach CloudWatch Logs
Lambda in VPC needs either:
- NAT Gateway (✅ we have this)
- VPC Endpoint for CloudWatch Logs (❓ need to check)

### 2. Lambda Timing Out
VPC cold starts can take 10-30 seconds. Check if timeout is sufficient.

### 3. Database Connection Failing
Even though security groups allow it, connection might be timing out.

## Solutions to Try

### Solution 1: Add CloudWatch Logs VPC Endpoint (Recommended)

This allows Lambda to write logs without going through NAT Gateway.

```bash
cd terraform
# Check if VPC endpoint exists
aws ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values=vpc-0eb5a8389cbde2d96' --query 'VpcEndpoints[*].[VpcEndpointType,ServiceName]' --output table
```

### Solution 2: Test Lambda with Simple Payload

Create a test that doesn't require database:

```bash
# Test if Lambda can at least start
aws lambda invoke \
  --function-name geojson-data-processor \
  --cli-binary-format raw-in-base64-out \
  --payload '{"test":"simple"}' \
  /tmp/test_simple.json

cat /tmp/test_simple.json
```

### Solution 3: Check Lambda Execution Role

Ensure Lambda has CloudWatch Logs permissions:

```bash
aws iam get-role-policy \
  --role-name dev-lambda-role \
  --policy-name AWSLambdaBasicExecutionRole
```

### Solution 4: Increase Lambda Timeout Temporarily

```bash
aws lambda update-function-configuration \
  --function-name geojson-data-processor \
  --timeout 600
```

## Next Steps

1. Check if VPC endpoint for CloudWatch Logs exists
2. If not, we may need to add it to Terraform
3. Or test if logs appear after waiting longer (VPC cold start)

Run these diagnostic commands and share outputs!

