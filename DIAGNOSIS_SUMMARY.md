# Lambda Diagnosis Summary

## Step 1 Results: ❌ NOT VPC-Related

**Test:** Removed Lambda from VPC (gave it direct internet access)
**Result:** Still NO log streams created
**Conclusion:** Issue is **NOT** VPC connectivity to CloudWatch Logs

## Current Status

- ✅ Lambda is being invoked (DLQ messages: 6, increasing)
- ✅ Lambda is outside VPC (has internet access)
- ✅ Package structure is correct (files at root)
- ✅ IAM permissions are correct
- ❌ **NO log streams created** (Lambda crashing before logging)

## Root Cause Analysis

Since Lambda crashes **before** it can create log streams, the issue is likely:

### Most Likely: Import Error During Module Initialization

**Problem:** `lambda_handler.py` imports `entrypoint`, which imports `psycopg2` at module level:
- `lambda_handler.py` line 9: `from entrypoint import process_geojson`
- `entrypoint.py` line 7: `import psycopg2`

If `psycopg2` fails to import, the entire module fails, and Lambda crashes before `lambda_handler()` is even called.

### Possible Causes:

1. **psycopg2-binary architecture mismatch**
   - Built for wrong CPU architecture
   - Missing system libraries (libpq, etc.)
   - Incompatible with Lambda Python 3.11 runtime

2. **Missing dependencies**
   - psycopg2-binary requires system libraries that aren't in Lambda runtime
   - Need to use Lambda Layer instead

3. **Python path issue**
   - Dependencies not in Python path
   - Import paths incorrect

## What We've Deployed

Created `lambda_handler_test.py` - a diagnostic handler that:
- Tests imports step-by-step
- Logs which import fails
- Should create log streams if it can run

**Handler:** Changed to `lambda_handler_test.lambda_handler` (temporarily)

## Next Steps

### Option 1: Wait and Check Logs (After Rate Limit Resets)

```bash
# Wait 20 minutes for rate limit
# Then check if test handler created log streams
aws logs describe-log-streams \
  --log-group-name '/aws/lambda/geojson-data-processor' \
  --max-items 5

# If streams exist, check logs
aws logs tail "/aws/lambda/geojson-data-processor" --since 10m --format short
```

### Option 2: Use Lambda Layer for psycopg2

Move `psycopg2-binary` to a Lambda Layer (better compatibility):

1. Create layer with psycopg2-binary
2. Attach to Lambda function
3. Remove from main package

### Option 3: Lazy Import psycopg2

Move `import psycopg2` inside the function, not at module level:

```python
# In entrypoint.py, change:
# import psycopg2  # Remove this

def get_db_conn():
    import psycopg2  # Add here
    # rest of function
```

This way, if psycopg2 fails to import, at least Lambda can start and log the error.

### Option 4: Check Lambda Runtime Compatibility

Verify psycopg2-binary is compatible with Python 3.11 on Lambda:
- Lambda uses Amazon Linux 2
- psycopg2-binary might need specific build

## Recommended: Try Option 3 First (Lazy Import)

This is the quickest fix - move `import psycopg2` inside the function. This will:
1. Allow Lambda to start
2. Create log streams
3. Show the actual error when trying to use psycopg2

Then we can fix the psycopg2 issue properly (Layer, or fix the import).

