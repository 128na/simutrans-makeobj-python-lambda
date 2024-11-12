data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "archive_file" "lambda_auth" {
  type        = "zip"
  source_dir  = "lambda-auth"
  output_path = "lambda-auth.zip"
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.app_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "lambda_makeobj" {
  function_name = "${var.app_name}-func"
  role          = aws_iam_role.lambda_role.arn
  image_uri     = "${aws_ecr_repository.main.repository_url}:latest"
  package_type  = "Image"
  memory_size   = 1024 # 1GB pakファイル操作するので多めに確保
  timeout       = 300  # 5min ゆっくりしていってね！
  description   = "渡されたファイルに対してmakeobj listを実行する"
  architectures = ["x86_64"]

  depends_on = [null_resource.build_ecr_image]
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_makeobj.function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_lambda_function" "lambda_auth" {
  function_name    = "${var.app_name}-auth"
  filename         = data.archive_file.lambda_auth.output_path
  source_code_hash = data.archive_file.lambda_auth.output_base64sha256
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  handler          = "app.handler"
  description      = "API Bearerトークン認証"
  architectures    = ["arm64"]

  environment {
    variables = {
      BEARER_TOKEN = random_string.bearer_token.result
    }
  }
}
output "api_bearer_token" {
  value       = random_string.bearer_token.result
  description = "API Bearerトークン"
}

# 認証トークン（固定値）
resource "random_string" "bearer_token" {
  length  = 32
  special = false
}

resource "aws_cloudwatch_log_group" "auth_lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.lambda_auth.function_name}"

  retention_in_days = var.log_retention_in_days
}
