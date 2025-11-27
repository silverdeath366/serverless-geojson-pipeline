#!/bin/bash

# Comprehensive Security Scan Script
# Scans for HIGH and CRITICAL vulnerabilities

set -e

echo "🔒 Running Security Scans..."
echo "=============================="
echo ""

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo "⚠️  Trivy not found. Installing..."
    echo "Please install Trivy first:"
    echo "  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -"
    echo "  echo 'deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main' | sudo tee -a /etc/apt/sources.list.d/trivy.list"
    echo "  sudo apt-get update && sudo apt-get install trivy"
    exit 1
fi

echo "✅ Trivy found: $(trivy --version)"
echo ""

# Create reports directory
mkdir -p security-reports

echo "📦 Step 1: Scanning Python Dependencies..."
echo "-------------------------------------------"
trivy fs --severity HIGH,CRITICAL --format table --output security-reports/python-deps.txt app/ || true
trivy fs --severity HIGH,CRITICAL --format json --output security-reports/python-deps.json app/ || true
echo ""

echo "🐳 Step 2: Scanning Dockerfile..."
echo "----------------------------------"
if [ -f "app/Dockerfile" ]; then
    trivy config --severity HIGH,CRITICAL --format table --output security-reports/dockerfile.txt app/Dockerfile || true
    trivy config --severity HIGH,CRITICAL --format json --output security-reports/dockerfile.json app/Dockerfile || true
else
    echo "  ⚠️  Dockerfile not found"
fi
echo ""

echo "🏗️  Step 3: Scanning Terraform Configuration..."
echo "----------------------------------------------"
trivy config --severity HIGH,CRITICAL --format table --output security-reports/terraform.txt terraform/ || true
trivy config --severity HIGH,CRITICAL --format json --output security-reports/terraform.json terraform/ || true
echo ""

echo "📄 Step 4: Scanning All Files..."
echo "--------------------------------"
trivy fs --severity HIGH,CRITICAL --format table --output security-reports/full-scan.txt . || true
trivy fs --severity HIGH,CRITICAL --format json --output security-reports/full-scan.json . || true
echo ""

echo "📊 Summary:"
echo "==========="
echo "Reports saved to security-reports/ directory:"
ls -lh security-reports/
echo ""
echo "Review the reports and fix any HIGH or CRITICAL vulnerabilities."

