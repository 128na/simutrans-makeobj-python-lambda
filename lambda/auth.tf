
data "archive_file" "auth_py" {
  type        = "zip"
  source_dir  = "auth"
  output_path = "auth.zip"
}

resource "aws_lambda_function" "auth_py" {
  function_name    = "simutrans-makeobj-auth"
  filename         = data.archive_file.auth_py.output_path
  source_code_hash = data.archive_file.auth_py.output_base64sha256
  runtime          = "python3.12"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "app.handler"
  description      = "API Bearerトークン認証"
  architectures    = ["arm64"]

  environment {
    variables = {
      BEARER_TOKEN = random_string.bearer_token.result
    }
  }
}

# 認証トークン（固定値）
resource "random_string" "bearer_token" {
  length  = 32
  special = false
}

# ログ
resource "aws_cloudwatch_log_group" "auth_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.auth_py.function_name}"
  retention_in_days = 14
}

# API gatewayで参照するためのARN
output "auth_function_arn" {
  value = aws_lambda_function.main.invoke_arn
}
