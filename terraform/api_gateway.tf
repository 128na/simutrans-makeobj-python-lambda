data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

# API Gatewayリソースへのアクセス権限
data "aws_iam_policy_document" "http_api_gateway_policy" {
  statement {
    effect = "Allow"
    actions = [
      "execute-api:Invoke"
    ]
    resources = ["${aws_apigatewayv2_api.http_api.execution_arn}/*"]
  }
}

# Assume Role Policy（API Gatewayによるロールの引き受け）
resource "aws_iam_role" "api_gateway_role" {
  name               = "${var.app_name}-api-gateway-role"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
}
# Lambda実行権限のアタッチ
resource "aws_iam_role_policy_attachment" "api_gateway_policy_lambda" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}
# CloudWatchLogs書き込み権限のアタッチ
resource "aws_iam_role_policy_attachment" "api_gateway_logs_attachment" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy" "http_api_invoke_policy" {
  role   = aws_iam_role.api_gateway_role.id
  policy = data.aws_iam_policy_document.http_api_gateway_policy.json
}

# API
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.app_name}-http-api"
  protocol_type = "HTTP"

  depends_on = [
    aws_lambda_function.lambda_auth,
    aws_lambda_function.lambda_makeobj,
  ]
}

# lambda統合設定
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_makeobj.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# APIのルート
resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST ${var.api_path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

# APIのステージ（デフォルト）
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format          = var.log_format
  }
}

# APIのログ
resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name = "/aws/api-gateway/${var.app_name}"

  retention_in_days = var.log_retention_in_days
}

# 認証用のlambda設定
resource "aws_apigatewayv2_authorizer" "auth" {
  api_id                  = aws_apigatewayv2_api.http_api.id
  authorizer_type         = "REQUEST"
  authorizer_uri          = aws_lambda_function.lambda_auth.invoke_arn
  identity_sources        = ["$request.header.Authorization"]
  name                    = "${var.app_name}-authorizer"
  enable_simple_responses = false

  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
}

# API gatewayからlambdaを呼び出す権限追加
resource "aws_lambda_permission" "func" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.app_name}-func"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
resource "aws_lambda_permission" "auth" {
  statement_id  = "AllowExecutionAuthorizerFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.app_name}-auth"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}${var.api_path}"
  description = "API エンドポイント"
}
