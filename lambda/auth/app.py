import os


def handler(event, context):
    expected_token = os.getenv("BEARER_TOKEN")
    token = event["headers"].get("Authorization") or event["headers"].get(
        "authorization"
    )

    return {
        "principalId": "*",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": (
                        "Allow" if validate_token(token, expected_token) else "Deny"
                    ),
                    "Resource": event["routeArn"],
                }
            ],
        },
    }


def validate_token(token: str | None, expected_token: str | None):

    if expected_token is None:
        print("BEARER_TOKEN 未設定")
        return False

    if token != f"Bearer {expected_token}":
        print("トークン不一致", token)
        return False

    return True
