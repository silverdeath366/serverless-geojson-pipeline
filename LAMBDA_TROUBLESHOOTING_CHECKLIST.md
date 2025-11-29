# Lambda Troubleshooting Checklist - For Tomorrow

## 🎯 Goal: Get Lambda Working or Move to EKS

If Lambda doesn't work after these steps → **Switch to geojson-ingestion-saas (EKS)**

## 📋 Step-by-Step Troubleshooting Plan

### Step 1: Rebuild Lambda Package ✅ FIRST THING

The improvements we made today need to be packaged:

```bash
cd terraform/modules/lambda

# Clean previous build
rm -f lambda_function.zip

# Rebuild with new code (includes Shapely, better error handling)
./build_lambda.sh

# Verify package contents
unzip -l lambda_function.zip | grep -E "shapely|entrypoint|lambda_handler" | head -20

# Check package size (should be ~40-50MB with Shapely)
ls -lh lambda_function.zip
```

### Step 2: Update Lambda Function Code

```bash
cd terraform

# Update Lambda with new package
terraform apply -target=module.lambda

# Verify update succeeded
aws lambda get-function --function-name <your-lambda-name> --query 'Configuration.LastUpdateStatus'
```

### Step 3: Test with Manual Invocation

**This is the KEY test - if manual invocation works, S3 trigger will work:**

```bash
# Create test event
cat > /tmp/test-event.json << 'EOF'
{
  "Records": [
    {
      "s3": {
        "bucket": {"name": "your-s3-bucket"},
        "object": {"key": "test/test.geojson"}
      }
    }
  ]
}
EOF

# Invoke Lambda manually
aws lambda invoke \
  --function-name <your-lambda-name> \
  --payload file:///tmp/test-event.json \
  --log-type Tail \
  /tmp/response.json

# Check response
cat /tmp/response.json

# Check logs (should appear immediately with manual invoke)
aws logs tail "/aws/lambda/<your-lambda-name>" --since 5m --format short
```

### Step 4: Check CloudWatch Logs

**If logs appear now (after improvements) → Lambda is working!**

```bash
# List log streams (should see new ones)
aws logs describe-log-streams \
  --log-group-name "/aws/lambda/<your-lambda-name>" \
  --order-by LastEventTime \
  --descending \
  --max-items 5

# Tail logs in real-time
aws logs tail "/aws/lambda/<your-lambda-name>" --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name "/aws/lambda/<your-lambda-name>" \
  --filter-pattern "ERROR" \
  --max-items 20
```

### Step 5: Test with S3 Upload

```bash
# Upload test file to S3
aws s3 cp app/geojson_sample/sample.geojson \
  s3://your-bucket/test/test-$(date +%s).geojson

# Wait 30 seconds
sleep 30

# Check logs
aws logs tail "/aws/lambda/<your-lambda-name>" --since 2m

# Check DLQ (should be empty if working)
aws sqs get-queue-attributes \
  --queue-url <your-dlq-url> \
  --attribute-names ApproximateNumberOfMessages
```

### Step 6: Verify Database Insertion

```bash
# Connect to RDS and check
psql -h <your-rds-endpoint> -U <your-user> -d <your-db> -c "
  SELECT COUNT(*) FROM geo_data;
  SELECT name, uploaded_at FROM geo_data ORDER BY uploaded_at DESC LIMIT 5;
"
```

## 🔍 If Still No Logs Appear

### Check 1: Lambda Execution Role

```bash
# Get Lambda role
ROLE_NAME=$(aws lambda get-function-configuration \
  --function-name <your-lambda-name> \
  --query 'Role' --output text | awk -F'/' '{print $NF}')

# Check CloudWatch Logs permissions
aws iam get-role-policy \
  --role-name $ROLE_NAME \
  --policy-name <policy-name> \
  --query 'PolicyDocument'
```

Should have:
- `logs:CreateLogGroup`
- `logs:CreateLogStream`
- `logs:PutLogEvents`

### Check 2: Lambda Handler Path

```bash
# Verify handler is correct
aws lambda get-function-configuration \
  --function-name <your-lambda-name> \
  --query 'Handler'

# Should be: lambda_handler.lambda_handler
# If not, update it
```

### Check 3: Lambda Package Structure

```bash
# Extract and inspect
cd /tmp
unzip <path-to-lambda_function.zip> -d lambda-inspect

# Check structure
ls -la lambda-inspect/

# Should see:
# - lambda_handler.py (at root)
# - entrypoint.py (at root)
# - shapely/ (directory)
# - psycopg2/ (directory)
# - etc.
```

### Check 4: VPC Configuration

**If Lambda is in VPC, it might not reach CloudWatch Logs:**

```bash
# Check if Lambda is in VPC
aws lambda get-function-configuration \
  --function-name <your-lambda-name> \
  --query 'VpcConfig'

# If VpcConfig has subnets, Lambda is in VPC
# This can prevent CloudWatch Logs access

# Option: Remove from VPC temporarily for testing
# (RDS must allow public access or use VPC endpoint)
```

### Check 5: Lambda Runtime & Memory

```bash
# Check configuration
aws lambda get-function-configuration \
  --function-name <your-lambda-name> \
  --query '{Runtime:Runtime,Memory:MemorySize,Timeout:Timeout}'

# Runtime should be: python3.11
# Memory should be: >= 512 MB (with Shapely)
# Timeout should be: >= 60 seconds
```

## 🚨 Critical Issues to Check

### Issue 1: Import Errors

If Lambda crashes on import, logs won't appear. Check manually:

```bash
# Create minimal test handler
# lambda_handler_test.py
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("TEST: Handler invoked")
    try:
        from entrypoint import process_geojson
        logger.info("TEST: Import successful")
        return {"statusCode": 200, "body": "Import OK"}
    except Exception as e:
        logger.error(f"TEST: Import failed: {e}")
        return {"statusCode": 500, "body": str(e)}
```

Deploy this test handler, invoke manually, check logs.

### Issue 2: psycopg2 Compatibility

```bash
# Check if psycopg2-binary is compatible
# Lambda uses Amazon Linux 2
# psycopg2-binary should work, but might need Lambda Layer

# Alternative: Use Lambda Layer for psycopg2
# https://github.com/jetbridge/psycopg2-lambda-layer
```

### Issue 3: Shapely Size

Shapely is large. If package > 50MB, consider:
- Using Lambda Layers for Shapely
- Or removing Shapely (use basic validation)

## ✅ Success Indicators

You'll know Lambda is working when:

- [ ] Manual invocation returns success
- [ ] CloudWatch Logs show execution logs
- [ ] S3 upload triggers Lambda (check logs)
- [ ] Database shows new records
- [ ] DLQ is empty or not increasing

## 🔄 Decision Point

**After 2-3 hours of troubleshooting:**

### If Lambda Works:
- ✅ Great! Continue with Lambda
- ✅ Monitor for a few days
- ✅ Document what fixed it

### If Lambda Still Doesn't Work:
- ✅ **Switch to geojson-ingestion-saas (EKS)**
- ✅ Use `MIGRATION_TO_EKS_GUIDE.md`
- ✅ Deploy via Docker Compose first (test locally)
- ✅ Then deploy to EKS

## 🎯 Time-Boxed Approach

**Suggested timeline:**

1. **9:00 AM** - Rebuild Lambda package
2. **9:30 AM** - Test manual invocation
3. **10:00 AM** - Test S3 trigger
4. **10:30 AM** - Debug any issues
5. **11:30 AM** - If not working → **Switch to EKS**
6. **12:00 PM** - Start EKS deployment
7. **1:00 PM** - EKS should be working

**Don't spend more than 2-3 hours on Lambda if it's not working!**

The EKS project is fixed and ready. It's better to have a working solution than to keep debugging Lambda.

## 📝 What to Document

When troubleshooting, document:

1. What you tried
2. What logs/errors you saw (or didn't see)
3. Lambda configuration (VPC, memory, timeout)
4. Package size and structure
5. Manual invocation results

This helps if we need to revisit Lambda later or help others.

---

## 🆘 Quick Reference Commands

```bash
# Rebuild Lambda
cd terraform/modules/lambda && ./build_lambda.sh

# Deploy Lambda
cd terraform && terraform apply -target=module.lambda

# Invoke manually
aws lambda invoke --function-name <name> --payload '{"Records":[]}' /tmp/out.json

# Check logs
aws logs tail "/aws/lambda/<name>" --since 10m

# Check DLQ
aws sqs get-queue-attributes --queue-url <url> --attribute-names ApproximateNumberOfMessages

# Test locally (Docker)
cd geojson-ingestion-saas && docker-compose up
```

**Good luck tomorrow!** 🚀

