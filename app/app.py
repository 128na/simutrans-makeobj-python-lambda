import subprocess

def handler(event, context):
    # 実行ファイルを呼び出し
    result = subprocess.run(["makeobj"], capture_output=True, text=True)

    # 実行結果を返す
    return {
        'stdout': result.stdout,
        'stderr': result.stderr,
        'returncode': result.returncode
    }
