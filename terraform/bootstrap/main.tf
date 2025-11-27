# Bootstrap Terraform Configuration
# This creates the S3 backend bucket for the main Terraform configuration
# Run this FIRST with local backend, then use the created bucket for main config

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Use local backend for bootstrap (we're creating the S3 backend!)
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.backend_bucket_name

  tags = {
    Name        = "Terraform State Backend"
    Purpose     = "Terraform state storage"
    ManagedBy   = "Terraform Bootstrap"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output the bucket name for easy reference
output "backend_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Name of the S3 bucket created for Terraform state"
}

output "backend_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket created for Terraform state"
}

