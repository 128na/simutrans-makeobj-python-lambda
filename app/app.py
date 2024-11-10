import subprocess
import json
import re
import base64
from requests_toolbelt import MultipartDecoder
from requests_toolbelt.multipart import decoder
from aws_lambda_typing import context as context_, events

TMP_DIR = "/tmp/"


def handler(event: events.APIGatewayProxyEventV2, context: context_.Context):
    try:
        handle_event(event)
        result = handle_makeobj()

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "isBase64Encoded": False,
            "body": json.dumps(result),
        }
    except FileException:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "isBase64Encoded": False,
            "body": json.dumps({"error": "ファイル保存に失敗しました"}),
        }
    except MakeobException:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "isBase64Encoded": False,
            "body": json.dumps({"error": "makeobj実行に失敗しました"}),
        }


def handle_event(event: events.APIGatewayProxyEventV2):
    try:
        multipart_data = get_body(event)
        save_files(multipart_data)
    except Exception as e:
        print(e)
        raise FileException


def get_body(event: events.APIGatewayProxyEventV2):
    content_type = event["headers"].get("Content-Type") or event["headers"].get(
        "content-type"
    )

    if event.get("isBase64Encoded"):
        body = base64.b64decode(event["body"])
    else:
        body = event["body"]

    return decoder.MultipartDecoder(body, content_type)


def save_files(multipart_data: MultipartDecoder):
    for part in multipart_data.parts:
        content_disposition = part.headers.get(b"Content-Disposition", b"").decode()

        # ファイル以外は除外
        if "filename=" not in content_disposition:
            continue

        file_name = content_disposition.split("filename=")[-1].strip('"')
        file_content = part.content
        file_path = f"{TMP_DIR}{file_name}"
        with open(file_path, "wb") as file:
            file.write(file_content)


def handle_makeobj():
    try:
        raw = subprocess.run(
            ["makeobj", "LIST", f"{TMP_DIR}*.pak"], capture_output=True, text=True
        )
        print("raw", raw)
        res = parse_result(raw.stdout)
        print("res", res)
        return res

    except Exception as e:
        print(e)
        raise MakeobException


def parse_result(raw: str):
    sections = re.split(r"(?=Contents of file)", raw)
    result = {"message": sections.pop(0), "files": []}

    for section in sections:
        print("section", section)
        data = parse_section(section)
        print("data", data)
        data["list"] = parse_lines(section.splitlines())

        result.files.append(data)
    return result


def parse_section(section: str):
    match = re.search(r"Contents of file (.+?) \(pak version (\d+)\):", section)

    result = {
        "file_name": match.group(1).replace(TMP_DIR, ""),
        "pak_version": match.group(2),
        "list": [],
    }

    return result


def parse_lines(lines: list[str]):
    result = []
    skip = True
    for line in lines:
        if line.startswith("---"):
            skip = False
            continue

        if skip == False:
            match = re.match(r"^(\S+)\s+(.+?)\s+(\d+)\s+(\d+)$", line)
            result.append(
                {
                    "type": match.group(1),
                    "name": match.group(2).strip(),
                    "nodes": int(match.group(3)),
                    "size": int(match.group(4)),
                }
            )
    return result


class FileException(Exception):
    pass


class MakeobException(Exception):
    pass
