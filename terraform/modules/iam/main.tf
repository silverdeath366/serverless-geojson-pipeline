# Additional IAM policies for enhanced security
# Note: Basic CloudWatch logs access is already provided by AWSLambdaBasicExecutionRole
# These are additional policies if needed

# Policy for CloudWatch Logs access (only if role is provided)
resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = var.lambda_role_id != "" ? 1 : 0
  name  = "${var.environment}-cloudwatch-logs-policy"
  role  = var.lambda_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Policy for Secrets Manager access (if using secrets)
resource "aws_iam_role_policy" "secrets_manager" {
  count = var.use_secrets_manager && var.lambda_role_id != "" ? 1 : 0
  name  = "${var.environment}-secrets-manager-policy"
  role  = var.lambda_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })
}

# Policy for X-Ray tracing (optional)
resource "aws_iam_role_policy" "xray" {
  count = var.enable_xray && var.lambda_role_id != "" ? 1 : 0
  name  = "${var.environment}-xray-policy"
  role  = var.lambda_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# User for manual access (optional)
resource "aws_iam_user" "pipeline_user" {
  count = var.create_manual_user ? 1 : 0
  name  = "${var.environment}-pipeline-user"

  tags = {
    Name = "${var.environment}-pipeline-user"
  }
}

resource "aws_iam_user_policy" "pipeline_user_policy" {
  count = var.create_manual_user ? 1 : 0
  name  = "${var.environment}-pipeline-user-policy"
  user  = aws_iam_user.pipeline_user[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunction"
        ]
        Resource = "arn:aws:lambda:*:*:function:${var.lambda_function_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
} 