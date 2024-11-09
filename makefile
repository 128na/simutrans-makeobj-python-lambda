include .env

publish: build push 

build:
	docker build -t $(APP_NAME) .
	docker tag $(APP_NAME):latest $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APP_NAME):latest

push:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APP_NAME):latest

server:
	docker run -d -v ~/.aws-lambda-rie:/aws-lambda -p 9000:8080 \
	--entrypoint /aws-lambda/aws-lambda-rie \
		$(APP_NAME):latest \
		/usr/local/bin/python -m awslambdaric app.handler

# 該当コンテナがないとエラーになる
server-stop:
	docker rm $$(docker stop $$(docker ps -a -q --filter ancestor=$(APP_NAME)))

server-log:
	docker logs $$(docker ps -a -q --filter ancestor=$(APP_NAME))

invoke:
	curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'

# ローカルでinvokeするためのエミュレーターインストール
install-emu:
	mkdir -p ~/.aws-lambda-rie && \
    curl -Lo ~/.aws-lambda-rie/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
    chmod +x ~/.aws-lambda-rie/aws-lambda-rie
