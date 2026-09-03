import os
import sys
import json
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

client = OpenAI(
    api_key=os.environ.get("DEEPSEEK_API_KEY"),
    base_url=os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com"),
)

# 对话历史：每个元素是一条消息 {"role": ..., "content": ...}
messages = []

def save_history():
    """把当前对话历史保存成 JSON 文件，文件名带时间戳"""
    history_dir = Path(__file__).resolve().parent / "history"
    history_dir.mkdir(exist_ok=True)
    filename = history_dir / datetime.now().strftime("chat_%Y%m%d_%H%M%S.json")
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(messages, f, ensure_ascii=False, indent=2)
    print(f"\n对话历史已保存到：{filename}")


print("多轮对话已启动。输入 exit 或 quit 退出；输入 /save 随时保存。\n")

try:
    while True:
        user_input = input("你：").strip()

        # 退出：保存历史后结束程序
        if user_input.lower() in {"exit", "quit", "q", "退出"}:
            if messages:
                save_history()
            print("再见！")
            break

        # 中途手动保存（不退出）
        if user_input.lower() == "/save":
            if messages:
                save_history()
            else:
                print("还没有任何对话，没什么可保存的。")
            continue

        # 空输入直接跳过，避免白发一次请求
        if not user_input:
            continue

        # 1) 把用户这句话追加进历史
        messages.append({"role": "user", "content": user_input})

        # 2) 把完整历史发给模型，保证它能记住前面的对话
        try:
            response = client.chat.completions.create(
                model="deepseek-v4-flash",
                messages=messages,
            )
        except Exception as e:
            # 请求失败：把刚追加的问题撤掉，历史保持完整
            messages.pop()
            print(f"请求失败：{e}\n")
            continue

        # 3) 把 AI 的回答转成普通字典存进历史，再显示给用户
        reply = response.choices[0].message.content
        messages.append({"role": "assistant", "content": reply})
        print(f"AI：{reply}\n")

except KeyboardInterrupt:
    # 用户按 Ctrl+C：同样保存历史再退出
    print("\n检测到 Ctrl+C")
    if messages:
        save_history()
    print("再见！")



