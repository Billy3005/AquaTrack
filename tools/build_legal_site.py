#!/usr/bin/env python3
"""Build the public legal site from docs/legal/*.md.

Only this folder is published. GitHub Pages can serve `/docs`, but that would
put docs/interview-prep.md, docs/CONTEXT.md, docs/agent.md and the ADRs on a
search-indexable website — public in the repo is not the same as published.
So the workflow runs this instead and deploys only what it emits.

Usage: python tools/build_legal_site.py <output-dir>
"""

import pathlib
import sys

import markdown

SRC = pathlib.Path(__file__).resolve().parent.parent / "docs" / "legal"

# Order matters: the first entry becomes the landing page's first link.
PAGES = [
    ("privacy-policy", "Chính sách quyền riêng tư"),
    ("delete-account", "Xoá tài khoản"),
]

TEMPLATE = """<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} — Wafubi</title>
<style>
  :root {{
    --bg: #ffffff; --ink: #14202b; --muted: #5c6f7d;
    --rule: #dde6ec; --accent: #00779a; --code-bg: #f1f6f9;
  }}
  @media (prefers-color-scheme: dark) {{
    :root {{
      --bg: #0d1b2a; --ink: #e8f1f6; --muted: #93a8b6;
      --rule: #24435c; --accent: #35c6e4; --code-bg: #14283a;
    }}
  }}
  * {{ box-sizing: border-box; }}
  body {{
    margin: 0; background: var(--bg); color: var(--ink);
    font: 16px/1.7 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    -webkit-font-smoothing: antialiased;
  }}
  .wrap {{ max-width: 44rem; margin: 0 auto; padding: 3rem 1.25rem 5rem; }}
  nav {{ margin-bottom: 2.5rem; font-size: .9rem; }}
  nav a {{ color: var(--accent); }}
  h1 {{ font-size: 2rem; line-height: 1.2; letter-spacing: -.02em; margin: 0 0 1.5rem; }}
  h2 {{ font-size: 1.25rem; margin: 2.5rem 0 .75rem; letter-spacing: -.01em; }}
  h3 {{ font-size: 1.05rem; margin: 1.75rem 0 .5rem; }}
  p, li {{ text-wrap: pretty; }}
  hr {{ border: none; border-top: 1px solid var(--rule); margin: 2.5rem 0; }}
  a {{ color: var(--accent); text-underline-offset: 2px; }}
  code {{
    background: var(--code-bg); padding: .1em .35em; border-radius: 3px;
    font-family: ui-monospace, Consolas, monospace; font-size: .9em;
  }}
  .tablewrap {{ overflow-x: auto; }}
  table {{ border-collapse: collapse; width: 100%; min-width: 30rem; margin: 1rem 0; }}
  th, td {{ text-align: left; padding: .55rem .7rem; border-bottom: 1px solid var(--rule); vertical-align: top; }}
  th {{ font-size: .78rem; text-transform: uppercase; letter-spacing: .06em; color: var(--muted); }}
  strong {{ font-weight: 650; }}
  footer {{ margin-top: 4rem; padding-top: 1.5rem; border-top: 1px solid var(--rule);
            color: var(--muted); font-size: .85rem; }}
</style>
</head>
<body>
<div class="wrap">
<nav><a href="./">← Wafubi</a></nav>
{body}
<footer>Wafubi · <a href="./">Trang chính</a></footer>
</div>
</body>
</html>
"""

INDEX_BODY = """<h1>Wafubi</h1>
<p>Ứng dụng theo dõi lượng nước uống. Trang này chỉ chứa các tài liệu bắt buộc
công khai — mã nguồn nằm trên
<a href="https://github.com/Billy3005/AquaTrack">GitHub</a>.</p>
<ul>
{links}
</ul>
"""


def render(md_text: str) -> str:
    html = markdown.markdown(md_text, extensions=["tables", "sane_lists"])
    # Tables must scroll inside their own box, never the page body.
    return html.replace("<table>", '<div class="tablewrap"><table>').replace(
        "</table>", "</table></div>"
    )


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 2

    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)

    missing = [s for s, _ in PAGES if not (SRC / f"{s}.md").exists()]
    if missing:
        print(f"error: missing source pages: {missing}", file=sys.stderr)
        return 1

    placeholders = []
    for slug, title in PAGES:
        text = (SRC / f"{slug}.md").read_text(encoding="utf-8")

        # These have to be filled in before the site is any use — failing the
        # build is better than publishing a policy that says [ĐIỀN EMAIL].
        if "[ĐIỀN" in text:
            placeholders.append(slug)

        (out / f"{slug}.html").write_text(
            TEMPLATE.format(title=title, body=render(text)), encoding="utf-8"
        )
        print(f"  built {slug}.html")

    links = "\n".join(
        f'<li><a href="{slug}.html">{title}</a></li>' for slug, title in PAGES
    )
    (out / "index.html").write_text(
        TEMPLATE.format(title="Tài liệu", body=INDEX_BODY.format(links=links)),
        encoding="utf-8",
    )
    print("  built index.html")

    # Jekyll would otherwise try to process the output and choke on nothing.
    (out / ".nojekyll").write_text("", encoding="utf-8")

    if placeholders:
        print(
            f"error: unfilled [ĐIỀN ...] placeholders in: {', '.join(placeholders)}\n"
            "       fill in the support email and deletion URL before publishing.",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
