include ../.env

# ビルドしてプッシュ
publish: build push 

# イメージビルド
build:
	docker build -t $(APP_NAME) .
	docker tag $(APP_NAME):latest $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APP_NAME)_repo:latest

# イメージをリポジトリへプッシュ
push:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APP_NAME)_repo:latest

# lambda実行用の権限設定
setup-lambda:
	aws iam create-role --role-name $(APP_NAME)_role \
		--assume-role-policy-document file://<(echo '{
			"Version": "2012-10-17",
			"Statement": [
				{
					"Effect": "Allow",
					"Principal": {
						"Service": "lambda.amazonaws.com"
					},
					"Action": "sts:AssumeRole"
				}
			]
		}')
	aws iam attach-role-policy \
		--role-name $(APP_NAME)_role \
		--policy-arn arn:aws:iam::aws:policy/service-role/$(APP_NAME)_policy
	aws lambda create-function \
		--function-name $(APP_NAME)_func \
		--package-type Image \
		--code ImageUri=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APP_NAME)_repo:latest \
		--role arn:aws:iam::$(AWS_ACCOUNT_ID):role/service-role$(APP_NAME)_policy \
		--timeout 300 \
		--memory-size 1024 \
		--ephemeral-storage '{"Size": 512}' \
		--architectures x86_64 \
		--tracing-config Mode=PassThrough

deploy-lambda:
	aws lambda update-function-code \
		--function-name $(APP_NAME)_func \
		--image-uri $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APP_NAME)_repo:latest
