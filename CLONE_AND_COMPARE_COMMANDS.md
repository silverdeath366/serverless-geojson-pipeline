# Commands to Clone and Compare Working Version

## Step 1: Clone the Working Version

```bash
cd /home/silver/geojson-pipeline

# Remove existing working-version if it exists
rm -rf working-version

# Clone the working repository
git clone https://github.com/silverdeath366/geojson-ingestion-saas.git working-version
```

## Step 2: Quick Comparison Commands

```bash
cd /home/silver/geojson-pipeline

# Check line endings in both versions
echo "=== Current Version Line Endings ==="
find app -name "*.py" -exec file {} \; | grep -E "CRLF|CR" || echo "All files have LF"

echo ""
echo "=== Working Version Line Endings ==="
find working-version/app -name "*.py" -exec file {} \; | grep -E "CRLF|CR" || echo "All files have LF"

# Compare Lambda handlers
echo ""
echo "=== Lambda Handler Comparison ==="
diff -u working-version/app/lambda_handler.py app/lambda_handler.py | head -50

# Compare entrypoint
echo ""
echo "=== Entrypoint Comparison ==="
diff -u working-version/app/entrypoint.py app/entrypoint.py | head -50

# Compare Terraform Lambda config
echo ""
echo "=== Terraform Lambda Config ==="
echo "Working version handler:"
grep -A 1 "handler" working-version/terraform/modules/lambda/main.tf | grep handler

echo "Current version handler:"
grep -A 1 "handler" terraform/modules/lambda/main.tf | grep handler

# Check S3 trigger permission
echo ""
echo "=== S3 Trigger Permission ==="
if [ -f working-version/terraform/modules/s3_trigger/main.tf ]; then
    echo "Working version has S3 trigger module"
    grep -A 5 "aws_lambda_permission" working-version/terraform/modules/s3_trigger/main.tf
else
    echo "No S3 trigger module in working version"
fi
```

## Step 3: After Comparison - Clean Up

```bash
# After you're done comparing and fixing, delete the working version
rm -rf working-version
```

