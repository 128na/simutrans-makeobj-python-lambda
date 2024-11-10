include .env

# ビルドしてプッシュ
publish: build push 

# ECR プライベートリポジトリの作成
repo:
	aws ecr create-repository --repository-name $(APP_NAME) --region $(AWS_REGION)

# イメージビルド
build:
	docker build -t $(APP_NAME) .
	docker tag $(APP_NAME):latest $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APP_NAME):latest

# イメージをリポジトリへプッシュ
push:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APP_NAME):latest
