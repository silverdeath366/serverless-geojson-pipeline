terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  # Backend configuration - Configured for geojson-dev project
  # Create the bucket first: aws s3 mb s3://geojson-dev-terraform-state-2024 --region us-east-1
  backend "s3" {
    bucket = "geojson-dev-terraform-state-2024"
    key    = "geojson-dev/dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"
  
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  
  availability_zones = var.availability_zones
}

# RDS Database
module "database" {
  source = "./modules/database"
  
  environment = var.environment
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  db_name            = var.db_name
  db_username        = var.db_username
  db_password      = var.db_password
  db_instance_class  = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  
  depends_on = [module.vpc]
}

# S3 Bucket for GeoJSON files
module "storage" {
  source = "./modules/storage"
  
  environment     = var.environment
  bucket_name     = var.s3_bucket_name
}

# Lambda Function
module "lambda" {
  source = "./modules/lambda"
  
  environment = var.environment
  
  function_name = var.lambda_function_name != "" ? var.lambda_function_name : "${var.project_name}-processor"
  runtime       = var.lambda_runtime
  handler       = "lambda_handler.lambda_handler"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  s3_bucket_name = var.s3_bucket_name
  
  # Temporarily disabled VPC config to test CloudWatch Logs connectivity
  # vpc_config = {
  #   subnet_ids         = module.vpc.private_subnet_ids
  #   security_group_ids = [module.database.lambda_security_group_id]
  # }
  
  environment_variables = {
    DB_HOST     = module.database.db_endpoint
    DB_PORT     = tostring(module.database.db_port)
    DB_NAME     = var.db_name
    DB_USERNAME = var.db_username
    DB_PASSWORD = var.db_password
    S3_BUCKET   = module.storage.bucket_name
  }
  
  depends_on = [module.database, module.storage, module.vpc]
}

# Update S3 bucket policy with Lambda role ARN (after Lambda is created)
# This is separate from the storage module to avoid circular dependency
resource "aws_s3_bucket_policy" "lambda_access" {
  bucket = module.storage.bucket_id
  depends_on = [module.lambda, module.storage]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = module.lambda.role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${module.storage.bucket_arn}/*"
      }
    ]
  })
}

# S3 Event Trigger
module "s3_trigger" {
  source = "./modules/s3_trigger"
  
  bucket_name    = module.storage.bucket_name
  lambda_arn     = module.lambda.function_arn
  function_name  = module.lambda.function_name
  
  depends_on = [module.lambda, module.storage]
}

# CloudWatch Logs and Monitoring
module "monitoring" {
  source = "./modules/monitoring"
  
  environment = var.environment
  
  lambda_function_name = module.lambda.function_name
  lambda_function_arn  = module.lambda.function_arn
  dlq_name             = module.lambda.dlq_name
}

# IAM Roles and Policies
module "iam" {
  source = "./modules/iam"
  
  environment = var.environment
  
  lambda_function_name = module.lambda.function_name
  lambda_role_id       = module.lambda.role_name  # Use role name, not ARN
  s3_bucket_name      = module.storage.bucket_name
  db_secret_arn       = module.database.db_secret_arn
  
  depends_on = [module.lambda]
} 