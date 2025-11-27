terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC and Networking
module "vpc" {
  source = "../../modules/vpc"
  
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

# S3 Bucket for GeoJSON files
module "s3" {
  source = "../../modules/s3"
  
  environment = var.environment
  bucket_name = var.s3_bucket_name
}

# RDS PostGIS Database
module "rds" {
  source = "../../modules/rds"
  
  environment     = var.environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  db_name        = var.db_name
  db_username    = var.db_username
  db_password    = var.db_password
  security_group_id = module.vpc.rds_security_group_id
}

# ECR Repository for Lambda container
module "ecr" {
  source = "../../modules/ecr"
  
  environment = var.environment
  repository_name = var.ecr_repository_name
}

# Lambda Function
module "lambda" {
  source = "../../modules/lambda"
  
  environment      = var.environment
  function_name    = var.lambda_function_name
  ecr_repository_url = module.ecr.repository_url
  ecr_image_tag    = var.lambda_image_tag
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  security_group_id = module.vpc.lambda_security_group_id
  rds_endpoint    = module.rds.endpoint
  rds_username    = var.db_username
  rds_password    = var.db_password
  rds_database    = var.db_name
}

# S3 Event Trigger
module "s3_trigger" {
  source = "../../modules/s3_trigger"
  
  bucket_name = module.s3.bucket_name
  lambda_function_arn = module.lambda.function_arn
  lambda_function_name = module.lambda.function_name
} 