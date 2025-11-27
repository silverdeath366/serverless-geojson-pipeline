# 🚀 AWS Account Setup Guide

This guide will help you set up this project on a **new AWS account**.

## Prerequisites

1. **AWS CLI installed and configured**
   ```bash
   aws --version
   aws configure
   ```
   Enter your:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., `us-east-1`)
   - Default output format (e.g., `json`)

2. **Terraform installed** (>= 1.0)
   ```bash
   terraform version
   ```

3. **Docker installed** (for local development)

## Step 1: Create Terraform Backend S3 Bucket

The Terraform state needs to be stored in S3. Create a bucket first:

```bash
# Replace with your unique bucket name (must be globally unique)
BACKEND_BUCKET="your-name-geojson-terraform-state"
REGION="us-east-1"

# Create the bucket
aws s3 mb s3://$BACKEND_BUCKET --region $REGION

# Enable versioning (recommended)
aws s3api put-bucket-versioning \
  --bucket $BACKEND_BUCKET \
  --versioning-configuration Status=Enabled

# Enable encryption (recommended)
aws s3api put-bucket-encryption \
  --bucket $BACKEND_BUCKET \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access (security best practice)
aws s3api put-public-access-block \
  --bucket $BACKEND_BUCKET \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

## Step 2: Configure Terraform Backend

Edit `terraform/main.tf` and uncomment the backend block:

```hcl
backend "s3" {
  bucket = "your-terraform-state-bucket-name"  # Use the bucket from Step 1
  key    = "geojson-pipeline/terraform.tfstate"
  region = "us-east-1"
  encrypt = true
}
```

## Step 3: Create Terraform Variables File

Copy the example file and customize it:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform/terraform.tfvars` with your values:

```hcl
# AWS Configuration
aws_region = "us-east-1"  # Change if needed
environment = "dev"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]  # Adjust for your region

# Database Configuration
db_name     = "gisdb"
db_username = "postgres"
db_password = "CHANGE-THIS-TO-SECURE-PASSWORD"  # ⚠️ IMPORTANT: Use a strong password!

# S3 Configuration
# ⚠️ IMPORTANT: S3 bucket names must be globally unique!
# Use something like: yourname-geojson-pipeline-2024
s3_bucket_name = "your-unique-geojson-bucket-name"

# Lambda Configuration
lambda_function_name = "geojson-processor"
lambda_timeout       = 300
lambda_memory_size   = 512

# RDS Configuration
db_instance_class    = "db.t3.micro"  # Free tier eligible
db_allocated_storage = 20
db_engine_version    = "15.4"
```

**Important Notes:**
- ⚠️ **S3 bucket names must be globally unique** - use your name/company + random suffix
- ⚠️ **Database password** - use a strong password, store it securely
- ⚠️ **Availability zones** - check which zones are available in your region

## Step 4: Initialize Terraform

```bash
cd terraform
terraform init
```

If you configured the backend, Terraform will ask if you want to migrate state. Type `yes`.

## Step 5: Review Terraform Plan

Before deploying, review what will be created:

```bash
terraform plan
```

This will show you:
- Resources that will be created
- Estimated costs
- Any configuration issues

**Review carefully!** This will create:
- VPC and networking resources
- RDS PostGIS database (costs money)
- S3 bucket
- Lambda function
- IAM roles and policies
- CloudWatch logs

## Step 6: Deploy Infrastructure

If the plan looks good:

```bash
terraform apply
```

Type `yes` when prompted. This will take 10-15 minutes.

## Step 7: Build and Push Lambda Container

After infrastructure is deployed:

```bash
# Get ECR repository URL from Terraform output
cd terraform
terraform output ecr_repository_url

# Or if using the main terraform setup, build and push manually
cd ../app
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build the image
docker build -t geojson-processor:latest .

# Tag for ECR
docker tag geojson-processor:latest <ecr-repo-url>:latest

# Push to ECR
docker push <ecr-repo-url>:latest
```

## Step 8: Update Lambda Function Code

If your Lambda uses container images, update it:

```bash
# Trigger Lambda update (if using container images)
aws lambda update-function-code \
  --function-name geojson-processor \
  --image-uri <ecr-repo-url>:latest
```

## Step 9: Test the Pipeline

1. **Upload a test GeoJSON file to S3:**
   ```bash
   aws s3 cp app/geojson_sample/sample.geojson s3://your-bucket-name/
   ```

2. **Check Lambda logs:**
   ```bash
   aws logs tail /aws/lambda/geojson-processor --follow
   ```

3. **Query the database:**
   ```bash
   # Get RDS endpoint from Terraform
   terraform output db_endpoint
   
   # Connect (you'll need to set up a bastion or use AWS Systems Manager)
   psql -h <db-endpoint> -U postgres -d gisdb
   ```

## Troubleshooting

### Terraform Backend Issues

If you get errors about the backend bucket:
- Make sure the bucket exists
- Check your AWS credentials: `aws sts get-caller-identity`
- Verify bucket region matches your configuration

### S3 Bucket Name Already Exists

S3 bucket names are globally unique. If you get an error:
- Try a different name with your name/company prefix
- Add random numbers: `yourname-geojson-2024-12345`

### RDS Connection Issues

- RDS is in private subnets by default (security best practice)
- You'll need a bastion host or VPN to connect
- Or temporarily allow your IP in the security group

### Lambda Timeout

- Increase timeout in `terraform.tfvars`
- Check CloudWatch logs for errors
- Verify database connection strings

## Cost Estimation

**Approximate monthly costs (us-east-1):**
- RDS db.t3.micro: ~$15/month
- Lambda: Free tier (1M requests/month free)
- S3: ~$0.023/GB storage
- Data transfer: Varies
- **Total: ~$15-20/month for dev environment**

## Cleanup

To destroy all resources and stop costs:

```bash
cd terraform
terraform destroy
```

**⚠️ Warning:** This will delete everything including the database and all data!

## Next Steps

- Set up CI/CD pipeline
- Add monitoring and alerts
- Configure backup strategy for RDS
- Set up staging environment
- Add API Gateway for REST API access

## Security Best Practices

1. ✅ Never commit `terraform.tfvars` to git (it's in .gitignore)
2. ✅ Use AWS Secrets Manager for sensitive values
3. ✅ Enable RDS encryption at rest
4. ✅ Use least-privilege IAM policies
5. ✅ Enable CloudTrail for audit logging
6. ✅ Regular security updates for dependencies

