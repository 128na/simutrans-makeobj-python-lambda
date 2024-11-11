data "terraform_remote_state" "lambda" {
  backend = "local"
  config = {
    path = "../lambda/terraform.tfstate"
  }
}

# Assume Role Policy（API Gatewayによるロールの引き受け）
resource "aws_iam_role" "api_gateway_role" {
  name               = "simutrans-makeobj-api-gateway-role"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
}

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

resource "aws_iam_role_policy" "http_api_invoke_policy" {
  role   = aws_iam_role.api_gateway_role.id
  policy = data.aws_iam_policy_document.http_api_gateway_policy.json
}

# HTTP APIリソースのARN取得
resource "aws_apigatewayv2_api" "http_api" {
  name          = "simutrans-makeobj-http-api"
  protocol_type = "HTTP"
}
output "http_api_execution_arn" {
  value = aws_apigatewayv2_api.http_api.execution_arn
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = data.terraform_remote_state.lambda.outputs.function_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format          = "$context.requestId $context.identity.sourceIp $context.identity.userAgent $context.requestTime $context.integrationErrorMessage $context.authorizer.error"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name = "/aws/api-gateway/simutrans-makeobj"

  retention_in_days = 14
}

resource "aws_apigatewayv2_authorizer" "auth" {
  api_id                  = aws_apigatewayv2_api.http_api.id
  authorizer_type         = "REQUEST"
  authorizer_uri          = data.terraform_remote_state.lambda.outputs.auth_function_arn
  identity_sources        = ["$request.header.Authorization"]
  name                    = "simutrans-makeobj-authorizer"
  enable_simple_responses = false

  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
}

# API gatewayからlambdaを呼び出せるようにする
resource "aws_lambda_permission" "func" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "simutrans-makeobj-func"
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API. the last one indicates where to send requests to.
  # see more detail https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html
  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
resource "aws_lambda_permission" "auth" {
  statement_id  = "AllowExecutionAuthorizerFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "simutrans-makeobj-auth"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
