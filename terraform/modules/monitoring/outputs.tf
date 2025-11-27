output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "error_alarm_name" {
  description = "Lambda error alarm name"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name
}

output "duration_alarm_name" {
  description = "Lambda duration alarm name"
  value       = aws_cloudwatch_metric_alarm.lambda_duration.alarm_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
} 