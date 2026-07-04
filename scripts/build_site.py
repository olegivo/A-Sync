#!/usr/bin/env python3
"""Собирает статический сайт GitHub Pages из инструкции пользователя.

Конвертирует docs/USER_GUIDE.md в _site/index.html (с адаптивным оформлением) и
копирует docs/screenshots в _site/screenshots. Запуск из корня репозитория:

    python3 scripts/build_site.py
"""
from __future__ import annotations

import shutil
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent
GUIDE = ROOT / "docs" / "USER_GUIDE.md"
SCREENSHOTS = ROOT / "docs" / "screenshots"
OUT = ROOT / "_site"

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PhotoPull — инструкция пользователя</title>
  <style>
    :root {{ color-scheme: light dark; }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.65;
      max-width: 820px;
      margin: 0 auto;
      padding: 2rem 1.25rem 4rem;
      color: #1d1d1f;
      background: #ffffff;
    }}
    @media (prefers-color-scheme: dark) {{
      body {{ color: #e8e8ea; background: #1c1c1e; }}
      a {{ color: #4aa3ff; }}
      code {{ background: #2c2c2e; }}
      blockquote {{ background: #2a2a2c; border-left-color: #4a4a4e; }}
      hr {{ border-color: #3a3a3c; }}
    }}
    h1 {{ font-size: 2rem; }}
    h2 {{ margin-top: 2.2rem; border-bottom: 1px solid rgba(128,128,128,.25); padding-bottom: .3rem; }}
    img {{ max-width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,.12); margin: .5rem 0 1rem; }}
    code {{ background: #f2f2f7; padding: .15em .4em; border-radius: 5px; font-size: .9em; }}
    blockquote {{ background: #f5f5f7; border-left: 4px solid #c7c7cc; margin: 1rem 0; padding: .6rem 1rem; border-radius: 6px; }}
    hr {{ border: none; border-top: 1px solid #e0e0e0; margin: 2rem 0; }}
    table {{ border-collapse: collapse; }}
    th, td {{ border: 1px solid rgba(128,128,128,.35); padding: .4rem .7rem; }}
  </style>
</head>
<body>
{content}
</body>
</html>
"""


def build() -> None:
    if not GUIDE.exists():
        raise SystemExit(f"Не найден файл инструкции: {GUIDE}")

    md_text = GUIDE.read_text(encoding="utf-8")
    html_body = markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "toc", "sane_lists"],
    )

    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    (OUT / "index.html").write_text(
        HTML_TEMPLATE.format(content=html_body), encoding="utf-8"
    )

    if SCREENSHOTS.exists():
        shutil.copytree(SCREENSHOTS, OUT / "screenshots")

    # .nojekyll — чтобы GitHub Pages не пытался обрабатывать сайт через Jekyll.
    (OUT / ".nojekyll").write_text("", encoding="utf-8")

    print(f"Сайт собран в {OUT}")


if __name__ == "__main__":
    build()
