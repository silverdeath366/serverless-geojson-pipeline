#!/bin/bash
# Script to clone working version and compare

set -e

WORKING_DIR="/home/silver/geojson-pipeline-working"
CURRENT_DIR="/home/silver/geojson-pipeline"

echo "=== Clone Working Version ==="
echo ""
echo "Please provide:"
echo "1. Git repository URL (or local path)"
echo "2. Branch/tag name (optional, default: main/master)"
echo ""
read -p "Git URL: " GIT_URL
read -p "Branch/Tag (press Enter for default): " GIT_BRANCH

if [ -z "$GIT_BRANCH" ]; then
    GIT_BRANCH="main"
fi

# Clone
echo ""
echo "Cloning to $WORKING_DIR..."
cd /home/silver
if [ -d "$WORKING_DIR" ]; then
    rm -rf "$WORKING_DIR"
fi

if [[ "$GIT_URL" == /* ]] || [[ "$GIT_URL" == .* ]]; then
    # Local path
    echo "Copying from local path: $GIT_URL"
    cp -r "$GIT_URL" "$WORKING_DIR"
else
    # Git URL
    git clone -b "$GIT_BRANCH" "$GIT_URL" "$WORKING_DIR"
fi

cd "$WORKING_DIR"

echo ""
echo "=== Comparing Key Files ==="
echo ""

# Check line endings
echo "1. Line Endings:"
find app -name "*.py" -exec file {} \; | grep -E "CRLF|CR" && echo "  ⚠️  Found CRLF line endings!" || echo "  ✅ All files have LF line endings"

# Check Lambda handler
echo ""
echo "2. Lambda Handler:"
if [ -f "app/lambda_handler.py" ]; then
    echo "  ✅ lambda_handler.py exists"
    head -5 app/lambda_handler.py
else
    echo "  ❌ lambda_handler.py not found"
fi

# Check Terraform config
echo ""
echo "3. Terraform Lambda Config:"
if [ -f "terraform/modules/lambda/main.tf" ]; then
    grep -A 2 "handler" terraform/modules/lambda/main.tf | head -3
fi

# Check S3 trigger
echo ""
echo "4. S3 Trigger Permission:"
if [ -f "terraform/modules/s3_trigger/main.tf" ]; then
    grep -A 5 "aws_lambda_permission" terraform/modules/s3_trigger/main.tf
fi

echo ""
echo "=== Comparison Complete ==="
echo ""
echo "Working version cloned to: $WORKING_DIR"
echo "Current version at: $CURRENT_DIR"
echo ""
echo "Next steps:"
echo "1. Review differences"
echo "2. Apply fixes from current version"
echo "3. Test deployment"

