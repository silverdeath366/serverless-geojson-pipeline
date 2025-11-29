# Clone Working Version and Compare

## Steps

1. **Clone the working version:**
   ```bash
   cd /home/silver
   git clone <your-git-repo-url> geojson-pipeline-working
   cd geojson-pipeline-working
   ```

2. **Compare key files:**
   - `app/lambda_handler.py` - Check line endings, imports
   - `app/entrypoint.py` - Check line endings, lazy imports
   - `terraform/modules/lambda/main.tf` - Check handler path
   - `terraform/modules/s3_trigger/main.tf` - Check permission

3. **Test the working version:**
   - Deploy to AWS
   - Upload a test file
   - Check if logs appear

4. **Apply our fixes to working version:**
   - Fix line endings
   - Apply security updates
   - Update dependencies
   - Test again

## What to Share

Please provide:
- Git repository URL (or if it's local, the path)
- Any specific branch/tag that works
- Any environment-specific configs needed

