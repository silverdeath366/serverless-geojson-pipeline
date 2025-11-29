variable "environment" {
  description = "Environment name"
  type        = string
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "lambda_handler.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "vpc_config" {
  description = "VPC configuration for Lambda"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null  # Temporarily optional for VPC connectivity testing
}

variable "environment_variables" {
  description = "Environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_name" {
  description = "S3 bucket name for permissions"
  type        = string
}

variable "db_resource_id" {
  description = "RDS resource ID for IAM permissions"
  type        = string
  default     = ""
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for Lambda (0 = unreserved)"
  type        = number
  default     = 0
}

variable "enable_xray" {
  description = "Enable AWS X-Ray tracing for Lambda"
  type        = bool
  default     = false
} 