output "db_endpoint" {
  description = "RDS database endpoint (hostname only)"
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "RDS database port"
  value       = aws_db_instance.main.port
}

output "db_identifier" {
  description = "RDS database identifier"
  value       = aws_db_instance.main.identifier
}

output "db_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

output "db_subnet_group_name" {
  description = "RDS subnet group name"
  value       = aws_db_subnet_group.main.name
}

# Note: In a production environment, you would use AWS Secrets Manager
# For this demo, we'll use the password directly
output "db_secret_arn" {
  description = "Database secret ARN (placeholder for Secrets Manager)"
  value       = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}-db-secret"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {} 