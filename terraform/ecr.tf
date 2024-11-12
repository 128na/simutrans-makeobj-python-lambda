provider "aws" {
  region = "ap-northeast-1"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
resource "aws_ecr_repository" "main" {
  name         = "${var.app_name}-repo"
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "keep latest one",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

}

resource "null_resource" "build_ecr_image" {
  triggers = {
    file_content_sha1 = sha1(join("", [for f in ["makefile", "dockerfile"] : filesha1(f)], [for f in fileset("lambda-makeobj", "*") : filesha1("lambda-makeobj/${f}")]))
  }

  provisioner "local-exec" {
    command = "make publish"
    environment = {
      APP_NAME       = var.app_name
      AWS_REGION     = data.aws_region.current.name
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
  }

  depends_on = [aws_ecr_repository.main]
}
