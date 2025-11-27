variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket for GeoJSON files"
  type        = string
  default     = "geojson-pipeline-dev"
}

variable "db_name" {
  description = "PostGIS database name"
  type        = string
  default     = "gisdb"
}

variable "db_username" {
  description = "RDS database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}

variable "ecr_repository_name" {
  description = "ECR repository name for Lambda container"
  type        = string
  default     = "geojson-processor"
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  default     = "geojson-processor"
}

variable "lambda_image_tag" {
  description = "Lambda container image tag"
  type        = string
  default     = "latest"
} 