data "terraform_remote_state" "ecr" {
  backend = "local"
  config = {
    path = "../ecr/terraform.tfstate"
  }
}

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

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "simutrans-makeobj-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_lambda_function" "main" {
  function_name = "simutrans-makeobj-func"
  role          = aws_iam_role.iam_for_lambda.arn
  image_uri     = data.terraform_remote_state.ecr.outputs.ecr_image_uri
  package_type  = "Image"
  memory_size   = 1024 # 1GB pakファイル操作するので多めに確保
  timeout       = 300  # 5min ゆっくりしていってね！
  description   = "渡されたファイルに対してmakeobj listを実行する"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_cloudwatch_policy,
    aws_cloudwatch_log_group.lambda_log_group,
  ]
}

# ログ
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/simutrans-makeobj-func"
  retention_in_days = 14
}

# API gatewayで参照するためのARN
output "function_arn" {
  value = aws_lambda_function.main.invoke_arn
}
