# Fix Lambda Invoke and Check for Stuck Resources

## Issue: Lambda invoke failed with "Invalid base64"

The `--payload file://` expects base64, but we need raw JSON. Use this instead:

## Step 1: Test Lambda with Proper Payload

```bash
aws lambda invoke \
  --function-name geojson-data-processor \
  --cli-binary-format raw-in-base64-out \
  --payload '{"Records":[{"s3":{"bucket":{"name":"geojson-dev-data-pipeline-2024"},"object":{"key":"test_data/test_manual2.geojson"}}}]}' \
  /tmp/lambda_response.json

cat /tmp/lambda_response.json
```

## Step 2: Check for Stuck Resources

```bash
# Check Lambda functions
aws lambda list-functions --query 'Functions[*].[FunctionName,State,LastUpdateStatus]' --output table

# Check RDS instances
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' --output table

# Check S3 buckets
aws s3 ls | grep geojson

# Check if any resources are stuck deleting
aws cloudformation list-stacks --stack-status-filter DELETE_IN_PROGRESS --query 'StackSummaries[*].[StackName,StackStatus]' --output table
```

## Step 3: Check Terraform State

```bash
cd terraform

# List all resources in state
terraform state list

# Check if state is consistent
terraform plan
```

## Step 4: If Resources Are Stuck

If you find stuck resources:

1. **For RDS**: Wait for deletion to complete (can take 10-20 minutes)
2. **For Lambda**: Check if it's in "Pending" state
3. **For S3**: Check if bucket deletion is in progress

## Step 5: Verify Current Infrastructure

```bash
# Check Lambda
aws lambda get-function --function-name geojson-data-processor --query 'Configuration.[State,CodeSize,LastUpdateStatus]' --output table

# Check RDS
aws rds describe-db-instances --db-instance-identifier dev-postgis-db --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' --output table

# Check S3
aws s3 ls s3://geojson-dev-data-pipeline-2024/
```

Run these commands and share outputs!

