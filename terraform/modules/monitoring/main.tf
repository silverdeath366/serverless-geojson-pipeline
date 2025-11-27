# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14

  tags = {
    Name = "${var.environment}-lambda-log-group"
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-geojson-pipeline-alerts"
  
  tags = {
    Name = "${var.environment}-geojson-pipeline-alerts"
  }
}

# CloudWatch Alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Lambda function errors detected"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : [aws_sns_topic.alerts.arn]
  ok_actions          = var.sns_topic_arn != "" ? [var.sns_topic_arn] : [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name = "${var.environment}-lambda-errors-alarm"
  }
}

# CloudWatch Alarm for Lambda duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.environment}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "250000"  # 250 seconds (83% of 300s timeout)
  alarm_description   = "Lambda function duration exceeds threshold"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : [aws_sns_topic.alerts.arn]
  ok_actions          = var.sns_topic_arn != "" ? [var.sns_topic_arn] : [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name = "${var.environment}-lambda-duration-alarm"
  }
}

# CloudWatch Alarm for DLQ messages
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.environment}-lambda-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Messages in Dead Letter Queue"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = var.dlq_name
  }

  tags = {
    Name = "${var.environment}-lambda-dlq-alarm"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-geojson-pipeline-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Lambda Function Metrics"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\"\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 100"
          region  = data.aws_region.current.name
          title   = "Lambda Function Logs"
          view    = "table"
        }
      }
    ]
  })
}

data "aws_region" "current" {} 