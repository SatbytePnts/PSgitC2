import base64
import json
import requests
import time

# ==== НАСТРОЙКИ ====
token  = "TOKEN"
owner  = "SatbytePnts"
repo   = "OutCmd"
branch = "main"
path_cmd = "logs/GetCmd.txt"
path_out = "logs/OutCmd.txt"

headers = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json",
    "User-Agent": "PythonClient"
}


def get_file_content(path):
    url = f"https://api.github.com/repos/{owner}/{repo}/contents/{path}"
    r = requests.get(url, headers=headers)
    if r.status_code == 200:
        content = r.json()["content"]
        return base64.b64decode(content).decode("utf-8").strip()
    return None

def update_github_file(path, text, message="Обновление файла"):
    url = f"https://api.github.com/repos/{owner}/{repo}/contents/{path}"
    r = requests.get(url, headers=headers)
    sha = r.json().get("sha") if r.status_code == 200 else None

    encoded_content = base64.b64encode(text.encode("utf-8")).decode("utf-8")

    body = {
        "message": message,
        "content": encoded_content,
        "branch": branch
    }
    if sha:
        body["sha"] = sha

    r = requests.put(url, headers=headers, data=json.dumps(body))
    if r.status_code in [200, 201]:
        print("✅ Команда загружена.")
    else:
        print(f"❌ Ошибка ({r.status_code}):", r.text)


while True:
    cmd = input("Введите PowerShell-команду (или 'exit' для выхода): ")
    if cmd.lower() == "exit":
        update_github_file(path_cmd, "exit", "Команда выхода")
        break


    update_github_file(path_cmd, cmd, "Отправка команды на выполнение")


    print("⌛ Ожидание результата выполнения...")
    last_result = None
    for i in range(20):
        time.sleep(1)
        result = get_file_content(path_out)
        if result and result != last_result:
            print("📥 Результат выполнения команды:\n")
            print(result)
            break
    else:
        print("⚠ Не удалось получить результат выполнения.")
