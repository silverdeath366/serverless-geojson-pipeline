variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "lambda_arn" {
  description = "Lambda function ARN"
  type        = string
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
} 