# 从项目根目录的 .env 文件读取配置（.env 已被 .gitignore 忽略，不会提交）
import os
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI




load_dotenv(Path(__file__).resolve().parent.parent / ".env")

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise SystemExit(
        "未找到 DEEPSEEK_API_KEY：请在项目根目录的 .env 文件中写入 "
        "DEEPSEEK_API_KEY=sk-你的key"
    )

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com")

response = client.chat.completions.create(
    model="deepseek-v4-pro",
    messages=[
        {"role": "system", "content": "You are a helpful assistant"},
        {"role": "user", "content": "Hello"},
    ],
    stream=False,
    reasoning_effort="high",
    extra_body={"thinking": {"type": "enabled"}}
)

print(response.choices[0].message.content)













