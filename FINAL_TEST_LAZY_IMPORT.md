# ✅ Lazy Import Fix Applied

## What Changed

**Moved `psycopg2` import inside function** (lazy import):
- Before: `import psycopg2` at module level (line 7)
- After: `import psycopg2` inside `get_db_conn()` function

**Why:** This allows Lambda to start even if psycopg2 fails to import, so we can see the actual error in logs.

## Test Now

```bash
# Upload test file
aws s3 cp /tmp/test_manual.geojson s3://geojson-dev-data-pipeline-2024/test_data/test_lazy_import.geojson

# Wait 30 seconds
sleep 30

# Check for log streams (SHOULD APPEAR NOW!)
aws logs describe-log-streams \
  --log-group-name '/aws/lambda/geojson-data-processor' \
  --max-items 5

# Check logs (should show actual error if psycopg2 fails)
aws logs tail "/aws/lambda/geojson-data-processor" --since 2m --format short
```

## Expected Results

### ✅ If Log Streams Appear:
- **Success!** Lambda can now start
- Check logs for:
  - If psycopg2 import fails → will see ImportError
  - If psycopg2 works → will see normal execution
  - If database connection fails → will see connection error

### ❌ If Still No Log Streams:
- Something else is crashing before Lambda can start
- May need to check handler path or other imports

## Next Steps Based on Logs

1. **If psycopg2 ImportError** → Use Lambda Layer for psycopg2
2. **If database connection error** → Fix connection parameters or network
3. **If works!** → Re-enable VPC config and add VPC endpoint for CloudWatch Logs

