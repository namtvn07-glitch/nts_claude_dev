---
description: Code review before commit - check patterns and conventions
---

# Code Review Workflow

> Review code against project conventions before committing.
> Ensure compliance with patterns in GEMINI.md and learned docs.

## Trigger
User calls:
- `/review` → Review changed files (git diff)
- `/review [file_path]` → Review specific file
- `/review [module]` → Review entire module

## Step 1: Identify Scope
// turbo

### 1.1 If no argument:
```bash
# Get list of changed files
git diff --name-only HEAD
git diff --name-only --staged

# IMPORTANT: Also check untracked files (new files)
git status --short
```

### 1.2 If file path provided:
Review that specific file

### 1.3 If module name provided:
Review by module path

## Step 2: Load Review Checklist
// turbo
Load rules from:
1. `.agents/rules/GEMINI.md` → Code Patterns, Critical Rules
2. `docs/learned/` (relevant stack file)

## Step 3: Review Code
// turbo

### 3.1 Unity C# Review:
| Check | Rule |
|-------|------|
| Encapsulation | Use `[SerializeField] private` instead of `public` for Inspector exposure. |
| Unity Methods | Avoid `Update()` if possible. Use Events/Delegates. |
| Performance | Cache `GetComponent`, don't use it in `Update()`. No `FindObjectOfType` in runtime. |
| Object Pooling| Avoid `Instantiate`/`Destroy` frequently in gameplay. Use Object Pooling. |
| Memory Leaks | Unsubscribe events (`-=`) in `OnDisable` or `OnDestroy`. |
| Naming | PascalCase for Classes/Methods, camelCase for private vars, PascalCase for properties. |

### 3.2 Scene & Asset Review:
| Check | Rule |
|-------|------|
| .meta files | Never ignore `.meta` files when committing Unity assets. |
| Prefabs | Prefer modifying Prefabs over Scene instances. |

### 3.3 Security Review:
- No hardcoded API keys or tokens in Scripts.
- Validate input for UI fields.

### 3.4 System Impact Analysis:
// turbo
```bash
grep -rl "ChangedClassName" Assets/Scripts/
```
| Check | Action |
|-------|--------|
| **Shared Managers** | Grep callers — other scripts using it? |
| **Data Models** | Modifying ScriptableObject fields might break existing instances in editor. |

> [!CAUTION]
> Modifying shared utilities or Core Managers → MUST review ALL callers.

### 3.5 Skill-Based Review Lenses (apply when relevant)

#### Architecture Lens
- [ ] Does it violate Single Responsibility Principle?
- [ ] Is UI logic mixed with Core Game Logic? (Should be separated)
- [ ] Are dependencies injected or hardcoded?

#### Concurrency/Async Lens
- [ ] Coroutines: Are they properly stopped when the object is disabled?
- [ ] Async/Await: Are `CancellationToken`s used to cancel tasks when Unity objects are destroyed?

### 3.6 Compile Gate (if C# files in scope)
Wait for user to verify no compilation errors in Unity Editor Console.

## Step 4: Generate Report
Output format:
```markdown
# 📋 Code Review Report

## Summary
- **Files reviewed**: X
- **Issues found**: Y (Z critical)
- **Status**: ✅ Ready / ⚠️ Needs fixes / ❌ Major issues

---

## Issues Found

### 🔴 Critical
1. **[file.cs:123]**: [description]
   - **Rule violated**: [rule from GEMINI.md]
   - **Suggested fix**: [how to fix]

### 🟡 Warning
1. **[file.cs:45]**: [description]
   - **Suggestion**: [improvement]

### 🟢 Info/Style
1. **[file.cs:78]**: [minor note]

---

## Approved ✅
- [file1.cs] - No issues

---

## Checklist Summary
| Category | Status |
|----------|--------|
| C# Patterns | ✅/❌ |
| Unity Perf | ✅/❌ |
| Memory/Events | ✅/❌ |
| Architecture | ✅/❌ |
```

## Step 5: Offer Fix
If issues were found:
```markdown
> Would you like me to auto-fix the issues above?
> - `yes` - Fix all
> - `yes critical` - Fix critical only
> - `no` - No thanks, I'll fix manually
```

---

## Quick Commands

| Command | Action |
|---------|--------|
| `/review` | Review uncommitted changes |
| `/review --staged` | Review staged changes only |
| `/review path/to/file.cs` | Review specific file |
