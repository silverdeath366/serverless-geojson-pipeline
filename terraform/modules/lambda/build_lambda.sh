#!/bin/bash
# Build Lambda deployment package with Python dependencies
set -e

cd "${1}" || exit 1
APP_DIR="$(pwd)/app"
BUILD_DIR="/tmp/lambda-build-${2}"
PACKAGE_DIR="$BUILD_DIR/package"
OUTPUT_ZIP="${3}"

# Convert relative path to absolute if needed
if [[ "$OUTPUT_ZIP" != /* ]]; then
  OUTPUT_ZIP="$(pwd)/$OUTPUT_ZIP"
fi

# Clean up
rm -rf "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"

# Also clean up any old zip file to ensure fresh build
rm -f "$OUTPUT_ZIP"

# Verify source files exist
if [ ! -f "$APP_DIR/lambda_handler.py" ]; then
  echo "Error: lambda_handler.py not found at $APP_DIR/lambda_handler.py"
  ls -la "$APP_DIR" || echo "APP_DIR does not exist"
  exit 1
fi
if [ ! -f "$APP_DIR/entrypoint.py" ]; then
  echo "Error: entrypoint.py not found at $APP_DIR/entrypoint.py"
  exit 1
fi
if [ ! -f "$APP_DIR/requirements-lambda.txt" ]; then
  echo "Error: requirements-lambda.txt not found at $APP_DIR/requirements-lambda.txt"
  exit 1
fi

# Copy only Lambda-specific Python files
cp "$APP_DIR/lambda_handler.py" "$PACKAGE_DIR/" || exit 1
cp "$APP_DIR/entrypoint.py" "$PACKAGE_DIR/" || exit 1

# Install Lambda-specific dependencies (psycopg2-binary, geojson, boto3)
cd "$PACKAGE_DIR" || exit 1
pip3 install -r "$APP_DIR/requirements-lambda.txt" -t . --no-cache-dir 2>&1 | grep -v "WARNING" || true

# Clean up unnecessary files
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true

# Create zip file from package directory contents (not the package directory itself)
cd "$PACKAGE_DIR" || exit 1
mkdir -p "$(dirname "$OUTPUT_ZIP")" || exit 1
zip -r "$OUTPUT_ZIP" . -q || exit 1

echo "Lambda package built successfully at $OUTPUT_ZIP"

