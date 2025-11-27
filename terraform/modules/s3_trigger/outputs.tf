output "notification_id" {
  description = "S3 bucket notification ID"
  value       = aws_s3_bucket_notification.lambda_notification.id
}

output "lambda_permission_id" {
  description = "Lambda permission ID"
  value       = aws_lambda_permission.allow_bucket.id
} 