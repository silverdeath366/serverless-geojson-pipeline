variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_function_arn" {
  description = "Lambda function ARN"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alerts (optional, will create one if not provided)"
  type        = string
  default     = ""
}

variable "dlq_name" {
  description = "Dead Letter Queue name for alarm"
  type        = string
  default     = ""
}
