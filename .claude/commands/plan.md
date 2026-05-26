---
description: Create an implementation plan for a new feature
---

# Plan Workflow

> Create an implementation plan for a new feature.
> Flow: `/plan` → review → `/execute` → `/finish`

## Step 1: Understand the Feature Request
Ask clarifying questions if needed:
- What is the main objective?
- Which module(s) are affected? (Gameplay, UI, Audio, Data, Editor)
- Any reference files or existing patterns to follow?

## Step 2: Collect SMART POLE Context Atoms
> **Reference**: Read the `smart-pole-context-analyzer` skill (global) before proceeding.

Before research, scan for **SP-Flaws** (missing atoms):

### 🔴 CORE (Mandatory - Ask user if missing!)
- [ ] **Aim (A)**: Specific objective? Success criteria?
- [ ] **Outline (O)**: Scope (include/exclude)? Desired structure?

### 🟡 CONTEXTUALIZER (Auto-fill from codebase research)
- [ ] **Locale (L)**: Which platform? Which tech stack? (Unity Version?)
- [ ] **Resource (R)**: Tools available? Constraints? (3D/2D, Plugins?)
- [ ] **Mastery (M)**: Does user need detailed or high-level explanation?

### 🟢 ACCELERATOR (Optional - enhance quality)
- [ ] **Example (E)**: Reference implementation?
- [ ] **Style (S)**: Desired output format?
- [ ] **Time (T)**: Deadline? Duration?

> [!CAUTION]
> **If Aim or Outline is missing, MUST ask user before continuing!**
> Do not assume scope — this leads to rework.

## Step 3: Design Exploration (If Needed)
> **Trigger**: If the feature is ambiguous, has multiple viable approaches,
> or involves architecture decisions — invoke the `brainstorming` skill FIRST.

Checklist - skip to Step 4 if ALL are "No":
- [ ] Is the scope ambiguous? (user said "make X better" without specifics)
- [ ] Are there 2+ valid approaches? (e.g. ScriptableObjects vs JSON saving)
- [ ] Is this a new capability with no existing pattern?

If ANY is "Yes" → activate `brainstorming` skill → get validated design → THEN continue to Step 4.

## Step 4: Research Codebase
// turbo
Read relevant context files (SSOT):
- Game Design Doc: `Docs/GDD.md` (if exists)
- Project Architecture: `Docs/Architecture.md` (if exists)
- Stack-specific: `docs/learned/` (relevant file)

Search codebase for similar implementations:

| Type | Location |
|------|----------|
| Logic | `Assets/Scripts/Managers/` |
| UI | `Assets/Scripts/UI/` |
| Data | `Assets/Scripts/Data/` |

## Step 5: Create Task & Plan Artifacts

Create 2 artifacts (auto-saved to `brain/<conversation-id>/`):

### 5.1 Create `task.md` (checklist tracking):
```markdown
# Task: [Feature Name]
> Created: [YYYY-MM-DD]

## Checklist (Remove inapplicable items)
- [ ] Research codebase
- [ ] Plan approved
- [ ] Data Layer (ScriptableObjects/JSON)
- [ ] Core Logic Layer
- [ ] UI/Gameplay Layer
- [ ] Tests passed in Editor
- [ ] Learnings extracted
```

### 5.2 Create `implementation_plan.md` (detailed plan):
```markdown
# [Feature Name]

Brief description of the feature and its objective.

## User Review Required
> [!IMPORTANT]
> [Key decisions requiring user approval]

## Proposed Changes

### Data Layer
#### [NEW/MODIFY] ScriptableObject / Model class
- Description

### Core Logic Layer
#### [MODIFY] Manager / Controller
- Description

### Gameplay/UI Layer
#### [MODIFY] View / MonoBehaviour
- Description

## Verification Plan
### Automated Tests
- Unity Test Runner (if applicable)

### Manual Verification
- Step 1: Enter Play Mode...
- Step 2: Click on X...
- Step 3: Verify Y in Console...
```

## Step 6: Self-Review Plan ⚠️ NEVER TRUST YOUR FIRST PLAN!
Before presenting to user, MUST verify:

### Checklist:
- [ ] **Completeness**: Have I covered all affected files?
- [ ] **Consistency**: Do patterns match existing codebase conventions?
- [ ] **Performance**: Will this cause memory leaks? (Check `Update` loops)
- [ ] **Edge Cases**: What if components are missing? How to handle nulls?
- [ ] **Existing Code**: Did I check for similar existing implementations to reuse?

### Final Check:
1. Re-read plan as if you're a skeptical reviewer
2. Search for at least ONE more related file you might have missed
3. Double-check all file paths exist
4. Verify Unity C# conventions (No `public` fields for Inspector, use `[SerializeField]`)

> [!CAUTION]
> If plan feels "too simple", you probably missed something. Dig deeper!

## Step 7: Request User Review
Present `implementation_plan.md` to user:
- Summarize the plan and key decisions
- Ask user to approve or request changes
- **STOP. Wait for user approval before continuing.**

## Step 8: After Approval
User can:
- Call `/execute` to implement the plan
- Or call `/execute` right after `/plan` (implicit approval)
