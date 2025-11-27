# S3 bucket notification configuration
resource "aws_s3_bucket_notification" "lambda_notification" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = var.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".geojson"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# Lambda permission to allow S3 to invoke the function
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
} 