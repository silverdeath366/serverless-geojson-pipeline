# 🚀 Deployment Guide

Complete guide for deploying the GeoJSON Pipeline to AWS.

## Prerequisites

- AWS CLI installed and configured
- Terraform >= 1.0
- AWS account with appropriate permissions

## Quick Start

1. **Configure AWS:**
   ```bash
   aws configure
   ```

2. **Bootstrap Terraform Backend:**
   ```bash
   cd terraform/bootstrap
   terraform init
   terraform apply
   ```

3. **Configure Variables:**
   ```bash
   cd ../..
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

4. **Deploy Infrastructure:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

## Detailed Setup

See [SETUP_AWS.md](SETUP_AWS.md) for comprehensive setup instructions.

## Verification

After deployment, verify everything works:

```bash
# Get infrastructure details
cd terraform
BUCKET=$(terraform output -raw s3_bucket_name)
LAMBDA=$(terraform output -raw lambda_function_name)

# Upload test file
cat > /tmp/test.geojson << 'EOF'
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "properties": {"name": "Test"},
    "geometry": {"type": "Point", "coordinates": [-74.006, 40.7128]}
  }]
}
EOF

aws s3 cp /tmp/test.geojson s3://$BUCKET/test_data/

# Check logs
sleep 15
aws logs tail /aws/lambda/$LAMBDA --since 5m
```

See [TEST_AND_VERIFY.md](TEST_AND_VERIFY.md) for complete verification steps.

