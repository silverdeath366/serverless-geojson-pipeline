variable "aws_region" {
  description = "AWS region for the backend bucket"
  type        = string
  default     = "us-east-1"
}

variable "backend_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique)"
  type        = string
  default     = "geojson-dev-terraform-state-2024"
}

