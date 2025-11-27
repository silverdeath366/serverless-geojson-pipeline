output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = module.database.db_endpoint
}

output "db_secret_arn" {
  description = "RDS database secret ARN"
  value       = module.database.db_secret_arn
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.storage.bucket_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.function_arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = module.monitoring.log_group_name
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = module.iam.lambda_role_arn
} 