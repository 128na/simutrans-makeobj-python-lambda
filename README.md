# Simutrans Makeobj on Python Lambda

POSTしたpakファイルに対して `makeobj LIST` を実行した結果を返すAPIです。

makeobjを実行するlambda環境はECRに専用イメージを作成して利用しています。
makeobjのハンドリングはpythonを使用しています。

## setup
事前にmake, docker, aws-cli, terraformが使用可能な状態にしてください。

```
make -v
GNU Make 4.3
Built for x86_64-pc-linux-gnu

docker -v
Docker version 27.3.1, build ce12230

aws --version
aws-cli/2.19.4 Python/3.12.6 Linux/5.15.153.1-microsoft-standard-WSL2 exe/x86_64.ubuntu.22

terraform -v
Terraform v1.9.8
on linux_amd64
```

```bash
cd terraform
terraform plan
terraform apply
```

## API実行
APIのエンドポイント(api_endpoint)と認証トークン(api_bearer_token)は `terraform apply` または環境構築後に `terraform show` 実行、AWS管理画面から確認できます。

```bash
curl -X POST -H "Authorization: Bearer <api_bearer_token>" -F "file=@./sample.pak" https://<api_endpoint>|jq
{
  "message": "Makeobj version 60.7 for Simutrans 124.2 and higher\n(c) 2002-2012 V. Meyer, Hj. Malthaner, M. Pristovsek & Simutrans development team",
  "files": [
    {
      "file_name": "sample.pak",
      "pak_version": 1003,
      "list": [
        {
          "type": "roadsign",
          "name": "sample",
          "nodes": 4,
          "size": 4132
        }
      ]
    }
  ]
}
```

## 構成図

![構成図](./flow.png)