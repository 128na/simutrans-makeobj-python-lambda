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
  name               = "simutrans-makeobj-python-lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_lambda_function" "main" {
  function_name = "simutrans-makeobj-python-lambda_func"
  role          = aws_iam_role.iam_for_lambda.arn
  image_uri     = data.terraform_remote_state.ecr.outputs.ecr_image_uri
  package_type  = "Image"
  memory_size   = 1024 # 1GB
  timeout       = 300  # 5min
  description   = "渡されたファイルに対してmakeobj listを実行する"

}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/simutrans-makeobj-python-lambda_func"
  retention_in_days = 14
}
