# GeoJSON Pipeline - Problem Summary

## Project Overview

**GeoJSON Ingestion Pipeline** - AWS serverless pipeline that:
1. Accepts GeoJSON files uploaded to S3
2. Triggers Lambda function via S3 event
3. Lambda downloads file, parses GeoJSON, inserts features into PostGIS (RDS)
4. Uses Terraform for infrastructure as code

## Infrastructure Status: ✅ 100% DEPLOYED

- ✅ VPC with public/private subnets, NAT Gateways
- ✅ RDS PostgreSQL with PostGIS extension (available, accessible)
- ✅ S3 bucket with event notification configured
- ✅ Lambda function deployed (19-38MB package with dependencies)
- ✅ IAM roles and policies configured
- ✅ Security groups allow Lambda → RDS communication
- ✅ CloudWatch Log Group created
- ✅ Dead Letter Queue (DLQ) configured

## Current Problem: Lambda Failing Silently

**Symptom:** Lambda is being invoked (confirmed by DLQ messages increasing from 3→4→5), but:
- ❌ **NO log streams created** in CloudWatch Logs
- ❌ **NO logs appearing** (not even errors)
- ❌ **NO invocations showing** in CloudWatch metrics
- ✅ **DLQ receiving messages** (proves Lambda is being triggered)

## What We've Fixed

1. **Package Structure** - Fixed zip file structure:
   - Files were in `package/` subdirectory → moved to root
   - `lambda_handler.py` and `entrypoint.py` now at zip root
   - Dependencies (`psycopg2`, `boto3`, etc.) at root level
   - Removed mixed old/new structure

2. **Dependencies** - Verified all included:
   - `psycopg2-binary` (4.2MB)
   - `boto3`, `botocore`
   - `geojson`
   - All security-fixed versions

3. **IAM Permissions** - Verified correct:
   - `AWSLambdaBasicExecutionRole` (CloudWatch Logs: CreateLogGroup, CreateLogStream, PutLogEvents)
   - `AWSLambdaVPCAccessExecutionRole` (VPC access)
   - Custom policy for S3 and RDS access

4. **Code Syntax** - Verified no Python syntax errors

## What We've Tried

1. ✅ Rebuilt Lambda package multiple times
2. ✅ Fixed zip structure (files at root)
3. ✅ Verified IAM permissions
4. ✅ Checked security groups
5. ✅ Verified S3 trigger configuration
6. ✅ Tested with manual S3 uploads
7. ✅ Checked for stuck resources (none found)
8. ✅ Verified NAT Gateways available
9. ✅ Checked DLQ messages (contain S3 events, not errors)

## Key Observations

1. **Lambda IS being invoked** - DLQ messages prove S3 → Lambda trigger works
2. **Lambda crashes BEFORE logging** - No log streams = crash during import/initialization
3. **No error metrics** - CloudWatch shows 0 errors (Lambda not reporting)
4. **VPC connectivity** - NAT Gateways available, but Lambda in VPC might have issues reaching CloudWatch Logs

## Possible Root Causes

### Most Likely:
1. **VPC Connectivity Issue** - Lambda in VPC can't reach CloudWatch Logs API
   - NAT Gateway might not be routing correctly
   - Lambda might need VPC endpoint for CloudWatch Logs
   - Cold start timeout before logs can be written

2. **Import Error** - Lambda crashing during module import
   - `psycopg2-binary` might have compatibility issue with Lambda runtime
   - Missing dependency or wrong architecture
   - Python path issue

3. **Handler Not Found** - Lambda can't find `lambda_handler.lambda_handler`
   - Despite files being at root, Python might not be finding them
   - Handler path configuration issue

### Less Likely:
4. **Timeout During Cold Start** - VPC cold start taking too long
5. **Memory Issue** - Lambda running out of memory during import
6. **Runtime Mismatch** - Python 3.11 vs dependencies built for different version

## Current Configuration

- **Lambda Runtime:** `python3.11`
- **Lambda Timeout:** 300 seconds
- **Lambda Memory:** 512 MB
- **Lambda in VPC:** Yes (private subnets)
- **NAT Gateways:** 2 (available)
- **Code Size:** 38MB (includes all dependencies)
- **Handler:** `lambda_handler.lambda_handler`

## Files Structure in Zip (Current)

```
lambda_function.zip
├── lambda_handler.py (root)
├── entrypoint.py (root)
├── psycopg2/ (root)
├── boto3/ (root)
├── geojson/ (root)
└── [other dependencies at root]
```

## Next Steps to Try

1. **Add VPC Endpoint for CloudWatch Logs** - Allow Lambda to write logs without NAT
2. **Test Lambda outside VPC** - Temporarily remove VPC config to isolate issue
3. **Use Lambda Layers** - Move `psycopg2-binary` to a layer (better compatibility)
4. **Increase Lambda timeout** - Give more time for VPC cold start
5. **Check Lambda execution logs via X-Ray** - If enabled
6. **Manual invoke with test payload** - See actual error response

## Code Files

- `app/lambda_handler.py` - Lambda entry point (handles S3 events)
- `app/entrypoint.py` - Core GeoJSON processing logic
- `app/requirements-lambda.txt` - Lambda dependencies
- `terraform/modules/lambda/build_lambda.sh` - Package build script

## Environment Variables (Lambda)

```
DB_HOST=dev-postgis-db.ckdykgokqx2x.us-east-1.rds.amazonaws.com:5432
DB_PORT=5432
DB_NAME=geojson_production_db
DB_USERNAME=geojson_admin
DB_PASSWORD=CHANGE_THIS_TO_SECURE_PASSWORD_123!
S3_BUCKET=geojson-dev-data-pipeline-2024
```

## Critical Question

**Why are NO log streams created?**
- If IAM issue → would see streams with permission errors
- If code error → would see streams with import/runtime errors  
- If VPC issue → might not be able to create streams at all

**This suggests Lambda is crashing during the very first import, before it can even attempt to create a log stream.**

