output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = var.lambda_role_id != "" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lambda_role_id}" : ""
}

output "pipeline_user_name" {
  description = "Pipeline user name (if created)"
  value       = var.create_manual_user ? aws_iam_user.pipeline_user[0].name : ""
}

output "pipeline_user_arn" {
  description = "Pipeline user ARN (if created)"
  value       = var.create_manual_user ? aws_iam_user.pipeline_user[0].arn : ""
}

data "aws_caller_identity" "current" {} 