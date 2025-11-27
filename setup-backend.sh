#!/bin/bash

# Script to create Terraform backend S3 bucket
# Run this before terraform init

BUCKET_NAME="geojson-dev-terraform-state-2024"
REGION="us-east-1"

echo "Creating Terraform backend bucket: $BUCKET_NAME"

# Create the bucket
aws s3 mb s3://$BUCKET_NAME --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Bucket created successfully"
    
    # Enable versioning
    echo "Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket $BUCKET_NAME \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    echo "Enabling encryption..."
    aws s3api put-bucket-encryption \
        --bucket $BUCKET_NAME \
        --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    
    # Block public access
    echo "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket $BUCKET_NAME \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    echo ""
    echo "✅ Backend bucket setup complete!"
    echo "You can now run: cd terraform && terraform init"
else
    echo "❌ Failed to create bucket. Check your AWS credentials and permissions."
    exit 1
fi

