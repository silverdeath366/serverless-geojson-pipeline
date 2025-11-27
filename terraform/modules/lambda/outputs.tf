output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.main.arn
}

output "function_invoke_arn" {
  description = "Lambda function invoke ARN"
  value       = aws_lambda_function.main.invoke_arn
}

output "role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Lambda execution role name"
  value       = aws_iam_role.lambda_role.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = "/aws/lambda/${aws_lambda_function.main.function_name}"
}

output "dlq_arn" {
  description = "Dead Letter Queue ARN"
  value       = aws_sqs_queue.dlq.arn
}

output "dlq_name" {
  description = "Dead Letter Queue name"
  value       = aws_sqs_queue.dlq.name
} 