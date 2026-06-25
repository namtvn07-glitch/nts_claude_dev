---
description: Render gdd-sheet.md → gdd-sheet.html + <repo>/index.html, then git commit (no push)
---

# /publish-gdd

Render `Unity/design/gdd/gdd-sheet/gdd-sheet.md` (SSOT) qua template self-contained → ghi `gdd-sheet.html` (preview) + `<repo>/index.html`, rồi commit trong repo đích. **Không push.** Mọi git dùng `git -C <repo>` (không `cd`, không đụng repo nguồn hiện tại).

**Rule — update in-place:** nếu `index.html`/`gdd-sheet.html` đã tồn tại thì đây là thao tác UPDATE — ghi đè nội dung mới từ `.md`, **giữ nguyên template/style**, KHÔNG dựng lại từ đầu. Không đổi `.md` ⇒ skip commit.

## 1. Build  // turbo
Một script làm hết: resolve repo từ `CLAUDE.local.md` → guard → render → ghi 2 file. Fail-fast với message rõ; tự exit nếu config chưa sẵn sàng.

```bash
python - <<'PY'
import html, re, sys, pathlib
ROOT = pathlib.Path('.')
SRC  = ROOT/'Unity/design/gdd/gdd-sheet/gdd-sheet.md'
TPL  = ROOT/'.claude/templates/gdd-sheet-page.html'
OUT  = ROOT/'Unity/design/gdd/gdd-sheet/gdd-sheet.html'
from datetime import date; DATE = date.today().isoformat()

m = re.search(r'GDD publish repo:[*\s]*`([^`]+)`', (ROOT/'CLAUDE.local.md').read_text(encoding='utf-8'))  # nuốt markdown bold **
repo = pathlib.Path(m.group(1)) if m else None
if not m or m.group(1).startswith('<'):
    sys.exit("STOP: set `GDD publish repo` (real git repo path) in CLAUDE.local.md, then rerun.")
if not (repo.exists() and (repo/'.git').exists()):
    sys.exit(f"STOP: {repo} is not a git repo (run git init/clone first).")

src = SRC.read_text(encoding='utf-8')
if re.search(r'</script', src, re.I):
    sys.exit("STOP: gdd-sheet.md contains '</script>' which breaks the embed.")
tpl = TPL.read_text(encoding='utf-8')
assert tpl.count('<!--GDD_MARKDOWN-->') == 1, "template: GDD_MARKDOWN must appear exactly once"

title = (re.search(r'^#\s+(.+)$', src, re.M) or [None,'GDD Sheet'])[1].strip()
htmlout = (tpl.replace('<!--GDD_TITLE-->', html.escape(title))
              .replace('<!--GDD_GENERATED_AT-->', DATE)
              .replace('<!--GDD_MARKDOWN-->', src))  # markdown nguyên văn (trong <script type=text/markdown>)
existed = OUT.exists()
for p in (OUT, repo/'index.html'):
    p.write_text(htmlout, encoding='utf-8', newline='\n')
print(f"{'UPDATED' if existed else 'CREATED'} {len(htmlout)}B -> {OUT} + {repo/'index.html'}\nREPO={repo}")
PY
```

## 2. Commit  // turbo
Lấy `REPO` từ output bước 1. Chỉ stage `index.html`; không đổi ⇒ skip.
```bash
git -C "<REPO>" add index.html
git -C "<REPO>" diff --cached --quiet && echo "no change — skip commit" \
  || git -C "<REPO>" commit -m "docs(gdd): update GDD sheet $(date +%F)"
```

## 3. Report
1 dòng: file đã ghi · commit hash/message (hoặc "skipped") · `git -C "<REPO>" push` để đẩy tay · HTML render qua CDN marked+mermaid (cần internet).
