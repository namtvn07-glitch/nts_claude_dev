---
description: Mark task as complete and extract learnings
---

# Finish Workflow

> Complete the task and extract learnings.
> Flow: `/plan` → `/execute` → `/finish`

## Trigger
User calls:
- `/finish` → Auto-detect task from current conversation
- `/finish [task_name]` → Specify a particular task
- `/finish --no-learnings` → Skip learnings extraction

## Step 1: Locate Task Context

### 1.1 If user did NOT provide task_name:
Agent identifies task from conversation:
1. Find task.md and implementation_plan.md created in this conversation (in `brain/<conversation-id>/`)
2. Use conversation content to identify the feature being worked on
3. If uncertain, ask user: "Do you want to /finish task [name]?"

### 1.2 If user DID provide task_name:
Find task.md in brain/ of the current conversation

### 1.3 Fallback if NO task artifacts exist:
If the conversation has no artifacts:
1. Ask user: "No task artifacts found. Would you like me to create a mini-summary for learnings?"
2. If user agrees → Create walkthrough.md with format:
   ```markdown
   # Quick Note: [Date]
   ## Context
   [Brief description of the conversation]
   ## Learnings
   - [Learning 1]
   ```
3. Still update `.agents/rules/GEMINI.md` if there are noteworthy learnings

> [!TIP]
> The agent remembers the current task throughout the conversation so `/finish` doesn't need the task name.

## Step 2: Update Task Status
Update the task file:
- Mark completed checkboxes
- Record test results (if any)
- Record actual changes vs. the original plan

## Step 3: Extract Learnings (DEFAULT — skip if --no-learnings flag is set)

### 3.1 Analyze the completed task:
- **New patterns**: What new code patterns were used that could be reused?
- **Gotchas**: What bugs/errors were encountered? How were they fixed?
- **Best practices**: What should/shouldn't be done?
- **Reusable code**: What code snippets could be reused?

### 3.2 Decide where to update (Decision Tree):

```text
What type of learning is this?
│
├─► Universal/Global rule that applies across ALL domains?
│   └─► ✅ `.agents/rules/GEMINI.md` (Section: Critical Rules or Learned Patterns)
│       Example: "Always use absolute paths", "Never commit plain text passwords"
│
├─► Specific rule, pattern, or deep technique for a specific domain?
│   └─► ✅ `.agents/learned/[domain].md`
│       Example domains: `unity-dev.md`, `playable.md`, `art-2d.md`, `ui.md`, `game-designer.md`
│       Example learning: "Use Prefab Variants for ScriptableObjects", "Phaser 3 texture packing"
│
├─► Improvement to PLANNING or WORKFLOW processes?
│   └─► ✅ `.agents/workflows/*.md` — **⚠️ MUST ask user approval before modifying workflow!**
│
├─► Debugging insight (root cause analysis, non-obvious bug)?
│   └─► ✅ `.agents/learned/[domain].md` (relevant domain file, add "Gotchas" section)
│       Format: **[Module] [Symptom]**: Root cause was [X] because [Y]
│
└─► Only applies to this task, not reusable?
    └─► ❌ Keep in task file, no need to update rules
```

> [!TIP]
> **Dual-category tiebreaker**: When a learning fits multiple categories (e.g., both a gotcha and a pattern),
> place it in the higher-priority location. `GEMINI.md` always wins.

### 3.3 Quality Gate — Entry MUST pass ALL 3 filters

Every candidate entry must pass these 3 filters before being written. If it fails ANY filter → **do NOT write it**.

**Filter 1 — Novelty** (Was this surprising or did it cause a real bug?)
- ❌ REJECT if it's standard framework behavior documented in official Unity/engine docs
- ❌ REJECT if any competent developer would already know this (e.g., "cache GetComponent", "unsubscribe events in OnDisable", "Resources.Load needs Resources folder")
- ✅ ACCEPT only if discovered through actual debugging or unexpected behavior in THIS task

**Filter 2 — Non-Duplication** (Does this ALREADY exist somewhere?)
- Search `.agents/skills/game-dev-unity/sub-skill/*.md` for the same concept
- Search `.agents/knowledge/` for the same pattern
- Search the target `.agents/learned/*.md` file for semantically similar entries
- ❌ REJECT if covered by existing sub-skill rules (even partially)
- ❌ REJECT if an existing learned entry covers >80% of the same topic → MERGE instead of appending
- ✅ ACCEPT only if this is a genuinely NEW insight not captured anywhere

**Filter 3 — Project Specificity** (Is this tied to THIS project's codebase?)
- ❌ REJECT generic advice (e.g., "use events for decoupling", "write editor scripts for repetitive tasks")
- ❌ REJECT Unity Editor bugs that are Googleable (e.g., "GameObjectInspector NullRef on Play Mode")
- ✅ ACCEPT specific gotchas naming actual project classes (e.g., "MonsterController wrapper bypasses QuantizedAudioPlayer state")
- ✅ ACCEPT specific patterns tied to game mechanics (e.g., "AcidPool hazard: set bodyType to Static for bridge")

> [!IMPORTANT]
> **If borderline on any filter → write a 1-line condensed version**, not a paragraph.
> **Learned files are for scars, not textbooks.** Only record things that actually bit you.

### 3.4 Update priority (in order of importance):

| Priority | File | When to update | Agent reads when |
|----------|------|----------------|------------------|
| 🥇 1st | `.agents/rules/GEMINI.md` | Universal/Global rules | **Every conversation** |
| 🥈 2nd | `.agents/learned/[domain].md`| Domain-specific knowledge | When working within domain |
| 🥉 3rd | `.agents/workflows/*.md` | Process improvements | When calling workflow |

> [!IMPORTANT]
> **`.agents/rules/GEMINI.md` is the primary location** because agents ALWAYS read this file first. Keep it strict to avoid bloat.
> Only update workflows when the learning relates to PROCESS, not CODE.

### 3.5 Dedup & Compaction Check (BEFORE writing new entry)
Before appending, read the target learned file and search for semantically similar existing entries:
- If an existing entry covers >80% of the same topic → **MERGE** (update it, do not append a duplicate)
- If the file exceeds 60 entries → archive resolved gotchas to `[domain]-archive.md` and merge overlapping patterns

### 3.6 Update files:
// turbo
- Read the file to update
- Add/merge learnings to the appropriate section
- Keep formatting consistent with existing content
- Note the source of the learning (which task)

### 3.7 Re-vectorize Global Knowledge Graph
// turbo
After writing any new entries to `.agents/learned/` or `.agents/rules/`, rebuild the GraphRAG FAISS index so new learnings become immediately searchable by all skills:

```
python .agents/scripts/build_knowledge_graph.py
```

Wait for completion. Verify output shows node count significantly greater than 2.
This step **closes the learning loop** — without it, new learnings are invisible to future agent queries.

## Step 4: Create Walkthrough
// turbo

Create `walkthrough.md` in brain/ to document results:
```markdown
# Walkthrough: [Feature Name]
> Completed: [YYYY-MM-DD]

## Changes Made
| File | Action | Description |
|------|--------|-------------|
| path/to/file | MODIFY | What changed |

## What Was Tested
- [ ] Compile: Verify no errors in Unity Editor Console
- [ ] Manual verification: [steps]

## Validation Results
- Test results: ✅/❌
- Notes: [any relevant notes]
```

> [!TIP]
> walkthrough.md is auto-saved by Antigravity to `brain/<conversation-id>/` — no manual management needed.

## Step 4.5: Deeper Learning (Optional)
If the task was complex or had many valuable insights:
- Ask user: "This task had many interesting learnings. Would you like me to run `/teach` to create a detailed lesson?"
- If user agrees → run `/teach` workflow (global)
- If user skips → continue to Step 5

> [!TIP]
> `/teach` creates narrative-style lessons, different from the rules/patterns extraction in Step 3.

## Step 5: Report to User
Notify the user:
- ✅ Task completed
- 📝 Files updated (if any)
- 🧠 Learnings extracted (summary)
- 💡 Suggestion: Call `/commit` when ready to commit

---

## Example Output

```markdown
✅ **Task Completed**: [feature_name]

### Files Updated:
- `.agents/rules/GEMINI.md` or `.agents/learned/[domain].md`: Added [pattern] rule

### Learnings Extracted:
1. **Pattern**: [reusable pattern description]
2. **Gotcha**: [non-obvious issue and fix]

💡 Call `/commit` when ready to commit.
```
