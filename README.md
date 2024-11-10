# Simutrans Makeobj on Python Lambda

POSTしたpakファイルに対して `makeobj LIST` を実行した結果を返すAPI。

makeobjを実行するlambda環境はECRでamazonlinux2023ベースの専用イメージを作成しています。
makeobjのハンドリングはpython3.11を使用しています。

## ECR setup
事前にAWS CLIが使用可能な状態にしてください。

setup

```bash
cp .env.example .env
make setup-repo
```

build  and  push to private ECR
```bash
make publish
```
イメージプッシュ時に古いイメージを削除するようライフサイクルを設定、または手動での削除推奨。

## Lambda setup
lambdaのコードはappディレクトリ内にあります。
pythonコードはECRイメージに含まれているため、lambdaに適用するにはデプロイするには

setup
```bash
make setup-lambda
```

deploy lambda
```bash
make publish
make deploy-lambda
```
