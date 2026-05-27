---
description: Execute the implementation plan
---

# Execute Workflow

> Execute the approved implementation plan.
> Flow: `/plan` → review → `/execute` → `/finish`

## Trigger
User calls:
- `/execute` → Auto-detect task from conversation and execute
- `/execute [task_name]` → Execute specific task
- `/execute --step [N]` → Execute only step N of the plan

## Step 1: Locate Task Context
Find task context from the current conversation:

### 1.1 If user did NOT provide task_name:
1. Find `task.md` and `implementation_plan.md` created in this conversation
2. Check conversation content to identify the feature
3. Ask for confirmation if uncertain

### 1.2 If user DID provide task_name:
Find task context in the current conversation's `implementation_plan.md`

## Step 2: Validate Task State
Verify the task is ready to execute:

```markdown
✅ Conditions to proceed:
- [ ] Task file exists
- [ ] implementation_plan.md has "Proposed Changes" section
- [ ] User has approved plan (or implicit approval via /execute)

❌ Block if:
- Task already completed
- Plan has not been created
```

> [!TIP]
> If user calls `/execute` right after `/plan`, treat as implicit approval.

## Step 3: Execute Implementation

### 3.1 Read plan from "Proposed Changes" in implementation_plan.md:
// turbo
- Data Layer (ScriptableObjects, Models)
- Core Logic Layer (Managers, Controllers)
- Gameplay/UI Layer (MonoBehaviours, Views)

### 3.2 Execute in order:
// turbo
```
1. Data Layer (Define data structures, ScriptableObjects)
   ↓
2. Core Logic (Implement Managers, singleton setup, logic controllers)
   ↓
3. Gameplay/UI (Implement components attached to Prefabs, hook up UI)
```

### 3.2.1 Route Unity scripts through @dev Mode B (MANDATORY):
For any file being created/modified under these paths, **delegate to `@dev` subagent in Mode B** (feature request flow) instead of editing directly:
- `Unity/*/Assets/Scripts/UI/**`
- `Unity/*/Assets/Scripts/Gameplay/**`
- `Unity/*/Assets/Scripts/Core/**`
- `Unity/*/Assets/Scripts/AI/**`
- `Unity/*/Assets/Scripts/Networking/**`
- `prototypes/*/Scripts/{UI,Gameplay,Core,AI,Networking}/**`

`@dev` will grep `.claude/templates/` for matching `purpose`/`tags`, load `rules_ref`, then implement. This is the **only** way to enforce template + rule consistency — main agent editing these paths directly is forbidden under `/execute`.

Files outside those paths (Editor scripts, data files, test scaffolding without behavior) may be edited directly.

### 3.3 Critical Unity C# Reminders:
- **Encapsulation**: Use `[SerializeField] private` instead of `public` for Inspector variables.
- **Performance**: DO NOT use `GameObject.Find`, `FindObjectOfType`, or `GetComponent` in `Update()`. Cache them in `Awake()` or `Start()`.
- **Events**: Always unsubscribe from events/actions in `OnDisable()` or `OnDestroy()` to prevent memory leaks.
- **Object Pooling**: Prefer Object Pooling over frequent `Instantiate`/`Destroy` during gameplay.

### 3.4 Checkpoint after each layer (MANDATORY):
// turbo
After completing each layer, **force-save `task.md`** before continuing:

```
✅ Data done → save task.md (mark Data [x]) → continue Logic
✅ Logic done → save task.md (mark Logic [x]) → continue UI
✅ UI done → save task.md (mark UI [x]) → continue Tests
```

> [!IMPORTANT]
> If interrupted mid-execution, the next `/execute` will read `task.md`,
> see which layers are already `[x]` → skip them, only execute remaining `[ ]` layers.

## Step 4: Run Tests
Ask the user to enter Play Mode in the Unity Editor and verify the functionality, checking the Console for any errors or warnings.

## Step 5: Update task.md
Update `task.md` in brain/:
- Mark completed checklist items as `[x]`
- Record files changed and test results
- Record results in implementation_plan.md verification section

## Step 6: Report to User
```markdown
✅ **Executed**: [task_name]

### Changes Made:
| File | Action |
|------|--------|
| file1.cs | MODIFY |
| file2.cs | NEW |

### Next Steps:
1. Please test in Unity Play Mode.
2. Call `/finish` when verification is done and no errors appear.
```

---

## Quick Commands

| Command | Action |
|---------|--------|
| `/execute` | Execute current task |
| `/execute task_name` | Execute specific task |
| `/execute --step 1` | Execute only step 1 |
| `/execute --dry-run` | Show what would be done without executing |
