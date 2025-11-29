#!/bin/bash
# Clone working version, compare, apply fixes, then delete

set -e

WORKING_DIR="working-version"
CURRENT_DIR="."

echo "=== Clone Working Version for Comparison ==="
echo ""
echo "This will:"
echo "1. Clone working version to ./$WORKING_DIR"
echo "2. Compare key files"
echo "3. Apply fixes"
echo "4. Delete working version after"
echo ""

# Get Git URL
if [ -z "$1" ]; then
    read -p "Enter Git repository URL: " GIT_URL
else
    GIT_URL="$1"
fi

# Get branch (optional)
if [ -z "$2" ]; then
    read -p "Enter branch/tag (or press Enter for main/master): " GIT_BRANCH
    if [ -z "$GIT_BRANCH" ]; then
        GIT_BRANCH="main"
    fi
else
    GIT_BRANCH="$2"
fi

# Remove existing working dir
if [ -d "$WORKING_DIR" ]; then
    echo "Removing existing $WORKING_DIR..."
    rm -rf "$WORKING_DIR"
fi

# Clone
echo ""
echo "Cloning $GIT_URL (branch: $GIT_BRANCH) to $WORKING_DIR..."
if [[ "$GIT_URL" == /* ]] || [[ "$GIT_URL" == .* ]]; then
    # Local path
    cp -r "$GIT_URL" "$WORKING_DIR"
else
    # Git URL - try main first, then master
    if [ "$GIT_BRANCH" = "main" ]; then
        git clone "$GIT_URL" "$WORKING_DIR" 2>&1 || git clone -b master "$GIT_URL" "$WORKING_DIR" 2>&1
    else
        git clone -b "$GIT_BRANCH" "$GIT_URL" "$WORKING_DIR" 2>&1
    fi
fi

echo "✅ Cloned successfully!"
echo ""
echo "=== Comparison Results ==="
echo ""

# Compare line endings
echo "1. Line Endings Check:"
echo "   Current version:"
find app -name "*.py" -exec file {} \; 2>/dev/null | grep -E "CRLF|CR" | wc -l | xargs -I {} echo "     Files with CRLF: {}"
echo "   Working version:"
find "$WORKING_DIR/app" -name "*.py" -exec file {} \; 2>/dev/null | grep -E "CRLF|CR" | wc -l | xargs -I {} echo "     Files with CRLF: {}"

# Compare Lambda handler
echo ""
echo "2. Lambda Handler Comparison:"
if [ -f "app/lambda_handler.py" ] && [ -f "$WORKING_DIR/app/lambda_handler.py" ]; then
    echo "   Comparing handlers..."
    diff -u "$WORKING_DIR/app/lambda_handler.py" "app/lambda_handler.py" | head -30 || echo "   Files are different (see diff above)"
else
    echo "   ⚠️  One or both handler files missing"
fi

# Compare entrypoint
echo ""
echo "3. Entrypoint Comparison:"
if [ -f "app/entrypoint.py" ] && [ -f "$WORKING_DIR/app/entrypoint.py" ]; then
    echo "   Key differences:"
    diff -u "$WORKING_DIR/app/entrypoint.py" "app/entrypoint.py" | grep -E "^[\+\-]" | head -20 || echo "   Files are similar"
fi

# Compare Terraform Lambda config
echo ""
echo "4. Terraform Lambda Config:"
if [ -f "terraform/modules/lambda/main.tf" ] && [ -f "$WORKING_DIR/terraform/modules/lambda/main.tf" ]; then
    echo "   Handler paths:"
    echo "   Working: $(grep -A 1 'handler' "$WORKING_DIR/terraform/modules/lambda/main.tf" | grep handler | head -1)"
    echo "   Current:  $(grep -A 1 'handler' terraform/modules/lambda/main.tf | grep handler | head -1)"
fi

# Compare S3 trigger
echo ""
echo "5. S3 Trigger Permission:"
if [ -f "$WORKING_DIR/terraform/modules/s3_trigger/main.tf" ]; then
    echo "   Working version has S3 trigger: ✅"
    grep -A 3 "aws_lambda_permission" "$WORKING_DIR/terraform/modules/s3_trigger/main.tf" | head -5
else
    echo "   ⚠️  S3 trigger not found in working version"
fi

echo ""
echo "=== Ready for Analysis ==="
echo ""
echo "Working version at: $WORKING_DIR"
echo "Current version at: ."
echo ""
echo "Next: Review differences and apply fixes"

