resource "aws_lambda_function" "etl_processor" {
  function_name = "hids-etl-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "etl_processor.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  filename         = "${path.module}/../lambda/dist/etl_processor.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/dist/etl_processor.zip")

  environment {
    variables = {
      DEST_BUCKET = "hids-logs"
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.etl_processor.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.log_bucket.arn
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = aws_s3_bucket.log_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.etl_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "suricata-logs/"
    filter_suffix       = ".json"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.etl_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "falco-logs/"
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_function" "ai_hids_inference" {
  function_name = "ai-hids-inference"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_inference.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  filename         = "${path.module}/../lambda/dist/lambda_inference.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/dist/lambda_inference.zip")

  environment {
    variables = {
      DEST_BUCKET = "hids-logs"
  }
}
}

resource "aws_lambda_permission" "hids-inference" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_hids_inference.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.log_bucket.arn
}

resource "aws_s3_bucket_notification" "log_trigger" {
  bucket = aws_s3_bucket.log_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ai_hids_inference.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "suricata-logs/"
    filter_suffix       = ".json"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.ai_hids_inference.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "falco-logs/"
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

