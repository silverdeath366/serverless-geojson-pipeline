variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "db_secret_arn" {
  description = "Database secret ARN"
  type        = string
}

variable "lambda_role_id" {
  description = "Lambda role ID"
  type        = string
  default     = ""
}

variable "use_secrets_manager" {
  description = "Whether to use AWS Secrets Manager"
  type        = bool
  default     = false
}

variable "enable_xray" {
  description = "Whether to enable X-Ray tracing"
  type        = bool
  default     = false
}

variable "create_manual_user" {
  description = "Whether to create a manual access user"
  type        = bool
  default     = false
} 