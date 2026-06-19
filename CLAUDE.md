# TRG36 — Unity Hyper-Casual Mobile

> Hyper-casual mobile game (`trg36-bubbleshoot`) chạy theo quy trình `/plan` → review → `/execute` → `/finish`. Production-grade C#, ship soft-launch APK.

## Stack

- **Unity**: `6000.1.17f1` (Unity 6, URP) — xem [ProjectVersion.txt](Unity/trg36-bubbleshoot/ProjectSettings/ProjectVersion.txt)
- **Build target**: Android (Hyper-Casual mobile, portrait, 60 FPS)
- **Input**: New Input System ([InputSystem_Actions](Unity/trg36-bubbleshoot/Assets/InputSystem_Actions.inputactions))
- **Host OS**: Windows 11 + PowerShell — dùng cú pháp PowerShell (`$null`, `$env:VAR`, backtick `` ` ``). Bash có sẵn qua Bash tool cho POSIX scripts.

## Layout

| Path | Purpose |
|------|---------|
| [Unity/trg36-bubbleshoot/](Unity/trg36-bubbleshoot/) | Unity project (Library/Temp/UserSettings đã ignore) |
| [.claude/rules/](.claude/rules/) | Code rules theo path-glob — **luôn reference, không inline** |
| [.claude/agents/dev.md](.claude/agents/dev.md) | Senior Unity subagent (extract templates + code feature) |
| [.claude/templates/](.claude/templates/) | Reusable code skeletons do `@dev` sinh ra |
| [.claude/commands/](.claude/commands/) | Slash commands (plan/execute/finish/commit/debug/review/teach) |
| [brain/](brain/) | Per-task working state: `task.md` + `implementation_plan.md` |
| [production/session-logs/](production/session-logs/) | Hook output (ignored) |

## Slash commands

| Command | Khi dùng |
|---------|---------|
| `/plan` | Lên kế hoạch feature mới — SMART POLE → `task.md` + `implementation_plan.md` |
| `/execute` | Implement theo plan, layer-by-layer (Data → Logic → UI), checkpoint sau mỗi layer |
| `/finish` | Đóng task, trích learnings, viết `walkthrough.md` |
| `/debug` | Bug-fix có kỷ luật (Hard/Simple routing) |
| `/review` | Code review trước commit (Unity C# convention, perf, leak) |
| `/commit` | Conventional Commits + chờ user xác nhận 1/2/3 |
| `/teach` | Debrief 9-phần kiểu "giảng bài bên cafe" |
| `/publish-gdd` | Sinh `gdd-sheet.html`/`index.html` từ `gdd-sheet.md` → commit lên repo publish local (path ở `CLAUDE.local.md`, không push) |

## Subagent

- `@dev` — Senior Unity developer. Hai chế độ: **(A)** Extract reusable template từ C# vào `.claude/templates/`; **(B)** Code feature ưu tiên template match → rules → convention. Có quyền `mcp__UnityMCP__*` để thao tác Editor trực tiếp.

## Code rules — đọc theo path glob (KHÔNG inline ở đây)

`.claude/rules/` chứa rule files có frontmatter `paths:`. Auto-load khi file working khớp glob. Tóm tắt mapping:

| Rule file | Áp dụng cho |
|-----------|------------|
| [prototype-code.md](.claude/rules/prototype-code.md) | `Unity/*/Assets/Scripts/**` + `prototypes/**` — baseline production rules (clean arch, event-driven, persistence wrapper, log discipline) |
| [gameplay-code.md](.claude/rules/gameplay-code.md) | `Unity/*/Assets/Scripts/Gameplay/**` + `prototypes/*/Scripts/Gameplay/**` |
| [engine-code.md](.claude/rules/engine-code.md) | `Unity/*/Assets/Scripts/Core/**` + `prototypes/*/Scripts/Core/**` — zero-alloc hot path |
| [ui-code.md](.claude/rules/ui-code.md) | `Unity/*/Assets/Scripts/UI/**` + `prototypes/*/Scripts/UI/**` |
| [ai-code.md](.claude/rules/ai-code.md) | `Unity/*/Assets/Scripts/AI/**` + `prototypes/*/Scripts/AI/**` |
| [shader-code.md](.claude/rules/shader-code.md) | `Unity/*/Assets/**/*.{shader,hlsl,cginc}` + `assets/shaders/**` |
| [network-code.md](.claude/rules/network-code.md) | `Unity/*/Assets/Scripts/Networking/**` + `prototypes/*/Scripts/Networking/**` |
| [test-standards.md](.claude/rules/test-standards.md) | `Unity/*/Assets/Scripts/Tests/**` + `prototypes/*/Scripts/Tests/**` |
| [data-files.md](.claude/rules/data-files.md) | `Unity/*/Assets/{Resources/Data,Data}/**` + `assets/data/**` |
| [design-docs.md](.claude/rules/design-docs.md) | `design/gdd/gdd.md` |
| [narrative.md](.claude/rules/narrative.md) | narrative/dialog files |

**Hard rules áp dụng toàn dự án (lặp lại ở đây vì cross-cutting):**

- `[SerializeField] private` cho Inspector vars — KHÔNG `public` field.
- KHÔNG `FindObjectOfType` / `GameObject.Find` / `GetComponent` trong `Update`/`FixedUpdate`. Cache trong `Awake`.
- Zero alloc trong hot path — pre-allocate, pool, reuse.
- Subscribe trong `OnEnable`, **unsubscribe trong `OnDisable`/`OnDestroy`** (leak guard, kill tweens).
- `PlayerPrefs.*` chỉ qua `Core/SaveManager.cs`. Naming key: `[game]_[key]`.
- Log qua `Core/Log.cs` (`[Conditional("UNITY_EDITOR")]`) — KHÔNG `Debug.Log` thô trong Gameplay/UI.
- KHÔNG `using UnityEditor;` trong `Scripts/Gameplay/` hoặc `Scripts/UI/` (build target Android).

## Workflow conventions

- **Mỗi task** → 1 thư mục trong `brain/<task-slug>/` chứa `task.md` (checklist) + `implementation_plan.md` (Data → Logic → UI/Gameplay) + `walkthrough.md` (do `/finish` sinh).
- **Layer order** khi `/execute`: Data → Core Logic → Gameplay/UI → Tests. Sau mỗi layer ép save `task.md` để khôi phục được khi gián đoạn.
- **Trước commit**: chạy `/review`. Commit message theo Conventional Commits (`/commit` sẽ chờ user chọn 1/2/3 trước khi push).
- **MCP**: UnityMCP đăng ký tại [.mcp.json](.mcp.json) (`http://127.0.0.1:8080/mcp`). Cần Unity Editor mở + MCP server chạy mới gọi được `mcp__UnityMCP__*`.

## Personal overrides

Ghi chú cá nhân / preference không share team đặt ở [CLAUDE.local.md](CLAUDE.local.md) (đã trong `.gitignore`).
