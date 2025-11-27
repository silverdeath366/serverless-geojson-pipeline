# ✅ Test & Verify - LinkedIn Readiness Checklist

## 🎉 Deployment Successful!

Your infrastructure is deployed. Now let's verify everything works.

## Step 1: Get Infrastructure Details

```bash
cd terraform

# Get all outputs
terraform output

# Get specific values
terraform output -json | jq
```

**Save these values:**
- S3 bucket name
- Lambda function name
- RDS endpoint
- Database name

## Step 2: Test the Pipeline

### 2.1 Upload a Test GeoJSON File

```bash
# Upload sample file to S3
aws s3 cp ../app/geojson_sample/sample.geojson s3://geojson-dev-data-pipeline-2024/

# Or create a test file
cat > test.geojson << 'EOF'
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"name": "LinkedIn Test Point"},
      "geometry": {
        "type": "Point",
        "coordinates": [-74.006, 40.7128]
      }
    }
  ]
}
EOF

aws s3 cp test.geojson s3://geojson-dev-data-pipeline-2024/
```

### 2.2 Check Lambda Execution

```bash
# Watch Lambda logs in real-time
aws logs tail /aws/lambda/geojson-data-processor --follow

# Or check recent logs
aws logs tail /aws/lambda/geojson-data-processor --since 5m
```

**What to look for:**
- ✅ Lambda function invoked
- ✅ File downloaded from S3
- ✅ GeoJSON processed successfully
- ✅ Features inserted into database
- ✅ No errors

### 2.3 Verify Lambda Metrics

```bash
# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=geojson-data-processor \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## Step 3: Verify Database

### 3.1 Check Database Connection

**Note**: RDS is in a private subnet, so you'll need to:
- Use AWS Systems Manager Session Manager
- Or set up a bastion host
- Or temporarily allow your IP in security group

```bash
# Get database endpoint
terraform output db_endpoint

# If you have access, connect:
psql -h <db-endpoint> -U geojson_admin -d geojson_production_db
```

### 3.2 Query Data (if connected)

```sql
-- Check if data was inserted
SELECT * FROM geo_data ORDER BY uploaded_at DESC LIMIT 10;

-- Count features
SELECT COUNT(*) FROM geo_data;

-- Check PostGIS extension
SELECT PostGIS_version();
```

## Step 4: Verify S3 Trigger

```bash
# Check S3 bucket notification configuration
aws s3api get-bucket-notification-configuration \
  --bucket geojson-dev-data-pipeline-2024

# List files in bucket
aws s3 ls s3://geojson-dev-data-pipeline-2024/
```

## Step 5: Check CloudWatch Dashboard

1. Go to AWS Console → CloudWatch → Dashboards
2. Find: `dev-geojson-pipeline-dashboard`
3. Verify metrics are showing

## Step 6: Test Error Handling

```bash
# Upload an invalid file to test error handling
echo '{"invalid": "json"}' > invalid.json
aws s3 cp invalid.json s3://geojson-dev-data-pipeline-2024/invalid.geojson

# Check logs for error handling
aws logs tail /aws/lambda/geojson-data-processor --follow
```

## Step 7: Performance Test

```bash
# Upload multiple files
for i in {1..5}; do
  aws s3 cp ../app/geojson_sample/sample.geojson \
    s3://geojson-dev-data-pipeline-2024/test-$i.geojson
done

# Monitor Lambda concurrency
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name ConcurrentExecutions \
  --dimensions Name=FunctionName,Value=geojson-data-processor \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Maximum
```

## Step 8: Screenshots for LinkedIn

Take screenshots of:

1. **Terraform Output**
   ```bash
   terraform output > terraform-outputs.txt
   ```

2. **AWS Console Screenshots:**
   - Lambda function (showing successful invocations)
   - S3 bucket with files
   - CloudWatch dashboard
   - RDS database status
   - CloudWatch logs showing successful processing

3. **Architecture Diagram:**
   - Use AWS Architecture Icons
   - Show: S3 → Lambda → RDS flow

## Step 9: Final Verification Checklist

- [ ] Terraform apply completed successfully
- [ ] S3 bucket created and accessible
- [ ] Lambda function deployed
- [ ] S3 trigger configured
- [ ] Test file uploaded to S3
- [ ] Lambda executed successfully
- [ ] CloudWatch logs show successful processing
- [ ] Database connection works (if accessible)
- [ ] CloudWatch dashboard shows metrics
- [ ] No errors in logs
- [ ] Infrastructure outputs saved
- [ ] Screenshots taken

## Step 10: LinkedIn Post Preparation

### Key Metrics to Highlight:

1. **Architecture:**
   - Serverless (Lambda)
   - Event-driven (S3 triggers)
   - Infrastructure as Code (Terraform)
   - Spatial database (PostGIS)

2. **Technologies:**
   - AWS (Lambda, S3, RDS, CloudWatch)
   - Terraform
   - Python 3.11
   - PostGIS

3. **Features:**
   - Fully automated pipeline
   - Scalable architecture
   - Production-ready security
   - Complete monitoring

### Post Template:

```
🚀 Just deployed a production-ready serverless GeoJSON processing pipeline on AWS!

✅ Event-driven architecture (S3 → Lambda → PostGIS)
✅ Infrastructure as Code (Terraform)
✅ Fully automated processing
✅ Production-grade security & monitoring

Tech Stack:
• AWS Lambda (Python 3.11)
• RDS PostGIS (Spatial Database)
• Terraform (IaC)
• CloudWatch (Monitoring)

Features:
• Automatic file processing on S3 upload
• Spatial data validation & storage
• Complete error handling
• Real-time monitoring

Check it out: [GitHub link]

#AWS #Serverless #Terraform #PostGIS #DevOps #CloudArchitecture
```

## Troubleshooting

If something doesn't work:

1. **Lambda not triggered:**
   ```bash
   # Check S3 event configuration
   aws s3api get-bucket-notification-configuration --bucket <bucket-name>
   ```

2. **Lambda errors:**
   ```bash
   # Check detailed logs
   aws logs tail /aws/lambda/geojson-data-processor --follow
   ```

3. **Database connection issues:**
   - RDS is in private subnet (by design)
   - Use AWS Systems Manager or bastion host
   - Or temporarily allow your IP in security group

## Success Criteria

✅ **Pipeline is LinkedIn-ready when:**
- All infrastructure deployed
- Test file processed successfully
- Lambda logs show success
- No errors in CloudWatch
- Screenshots captured
- Documentation complete

**You're ready to post! 🎉**

