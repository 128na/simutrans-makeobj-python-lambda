resource "aws_ecr_repository" "main" {
  name         = "simutrans-makeobj-python-lambda_repo"
  force_delete = true
}
output "ecr_image_uri" {
  value = "${aws_ecr_repository.main.repository_url}:latest"
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

resource "null_resource" "build_image" {
  triggers = {
    file_content_sha1 = sha1(join("", [for f in ["../.env", "makefile", "dockerfile"] : filesha1(f)], [for f in fileset("app", "*") : filesha1("app/${f}")]))
  }

  provisioner "local-exec" {
    command = "make publish"
  }
}
