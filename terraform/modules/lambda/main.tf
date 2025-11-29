# Build Lambda deployment package with dependencies
resource "random_id" "build_id" {
  byte_length = 4
}

resource "null_resource" "lambda_build" {
  triggers = {
    app_hash         = filemd5("${path.root}/../app/lambda_handler.py")
    requirements_hash = filemd5("${path.root}/../app/requirements-lambda.txt")
    entrypoint_hash   = filemd5("${path.root}/../app/entrypoint.py")
    build_id         = random_id.build_id.hex
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/build_lambda.sh ${path.root}/.. ${random_id.build_id.hex} ${path.root}/${path.module}/lambda_function.zip"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-lambda-role"
  }
}

# IAM policy for Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM policy for VPC access
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom IAM policy for S3 and RDS access
resource "aws_iam_role_policy" "lambda_custom" {
  name = "${var.environment}-lambda-custom-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}"
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = ["*"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${var.db_resource_id}/*"
      }
    ]
  })
}

# Dead Letter Queue for failed Lambda invocations
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.environment}-${var.function_name}-dlq"
  message_retention_seconds = 1209600  # 14 days
  receive_wait_time_seconds  = 20       # Long polling

  tags = {
    Name = "${var.environment}-${var.function_name}-dlq"
  }
}

# Lambda function
resource "aws_lambda_function" "main" {
  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = fileexists("${path.module}/lambda_function.zip") ? filebase64sha256("${path.module}/lambda_function.zip") : null
  function_name    = var.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_handler.lambda_handler"
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size

  # Temporarily disable VPC to allow internet access (for CloudWatch Logs)
  # This is a diagnostic step to test if VPC connectivity is blocking logs
  # Uncomment below to re-enable VPC access (needed for RDS)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [1] : []
    content {
      subnet_ids         = var.vpc_config.subnet_ids
      security_group_ids = var.vpc_config.security_group_ids
    }
  }

  environment {
    variables = var.environment_variables
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  reserved_concurrent_executions = var.reserved_concurrent_executions

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  tags = {
    Name = "${var.environment}-${var.function_name}"
  }

  depends_on = [
    null_resource.lambda_build,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy.lambda_custom,
    aws_iam_role_policy.lambda_dlq
  ]
}

# IAM policy for DLQ access
resource "aws_iam_role_policy" "lambda_dlq" {
  name = "${var.environment}-lambda-dlq-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.dlq.arn
      }
    ]
  })
}

# CloudWatch log group is created by the monitoring module to avoid duplicates

data "aws_region" "current" {}
data "aws_caller_identity" "current" {} 