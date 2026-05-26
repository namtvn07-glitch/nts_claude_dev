---
description: Product-level blueprint — break a new product request into a feature tree + detailed plans, ready for /execute & @dev
---

# Blueprint Workflow

> Plan at the **product level** when receiving a new implementation request (new game mode, new prototype, large refactor).
> Flow: `/blueprint` → user approves → `/plan` (refine per-feature, optional) → `/execute` → `/finish`
>
> **Difference from `/plan`**: `/plan` is for **1 feature**. `/blueprint` is for **1 product with N features** — splits the feature tree, sequences dependencies, and pre-generates an `implementation_plan.md` per feature so each can be `/execute`-d independently.
>
> **Does NOT invoke `@dev` itself** — it only prepares artifacts. The user calls `/execute` (which uses `@dev` internally) when ready.

## Step 1: Identify the product request

If the user only says "build game X", ask before researching:

- **Product Aim**: which core problem does this product solve? (1 sentence)
- **Player loop**: what is the 30-second gameplay loop?
- **Build target**: Android / iOS / both? Min SDK? Portrait/landscape? Target FPS?
- **Scope tier**: prototype (1–3 days) / vertical-slice (1–2 weeks) / soft-launch (1–2 months)?
- **Reference**: any reference game / mood-board / GDD?

> [!CAUTION]
> If Aim or Player loop is missing → STOP and ask. Do NOT hallucinate.

## Step 2: SMART POLE at product level

> Unlike `/plan` (atom-level), check **product-level** atoms here:

### 🔴 CORE (Mandatory)
- [ ] **Aim (A)**: Product objective + success metric (e.g. D1 retention ≥ 30%, session ≥ 90s)
- [ ] **Outline (O)**: IN list (MVP features) + OUT list (hard cut) — required by `.claude/rules/design-docs.md` § Release Scope

### 🟡 CONTEXTUALIZER
- [ ] **Locale (L)**: Unity `6000.1.17f1` URP, Android, portrait, 60 FPS (see [CLAUDE.md](../../CLAUDE.md))
- [ ] **Resource (R)**: assets available? plugins? art pipeline?
- [ ] **Mastery (M)**: terse vs step-by-step (see [CLAUDE.local.md](../../CLAUDE.local.md))

### 🟢 ACCELERATOR
- [ ] **Example (E)**: specific reference game
- [ ] **Style (S)**: visual style (low-poly, 2D pixel, hyper-casual flat?)
- [ ] **Time (T)**: soft-launch deadline

## Step 3: Research codebase before decomposition

// turbo
Read SSOT files first to avoid duplicate patterns and missed coverage:

- [Unity/trg36-bubbleshoot/Assets/](../../Unity/trg36-bubbleshoot/Assets/) — existing scenes/prefabs
- `prototypes/*/` (if any) — reusable older patterns
- [.claude/templates/](../../.claude/templates/) — templates already extracted by `@dev`
- [.claude/rules/](../../.claude/rules/) — which rule globs apply to which feature
- `design/gdd/gdd.md` (if exists) — verify the 6 mandatory sections

## Step 4: Decompose into a Feature tree

**Feature splitting rules** (each feature must satisfy all 3):
1. **Atomic** — once implemented, it can be demoed independently; does NOT require another feature to run.
2. **1–3 days** of effort. Larger → split further. Smaller → merge into a parent feature.
3. **Maps to 1 rule file** (gameplay/ui/engine/ai/data…). If it spans multiple layers → still 1 feature but split steps by layer Data → Logic → UI.

**Priority (MoSCoW):**
- `P0 / Must`: without it there is no game (core loop, input, win/lose, persistence)
- `P1 / Should`: quality lift (SFX, VFX, juice, pause/settings)
- `P2 / Could`: nice-to-have (achievements, themes, daily reward)
- `OUT`: explicitly excluded (IAP, ads, multiplayer…) — listed in Release Scope

**Dependencies**: draw a DAG — feature B depends on A if it needs A's types/events/scene. Features without dependencies → parallelizable later.

## Step 5: Generate artifacts

Create the following under `brain/<product-slug>/`:

### 5.1 `brain/<product-slug>/product_plan.md` (overview)

```markdown
# Product Blueprint: <Product Name>
> Created: <YYYY-MM-DD> | Tier: <prototype|vertical-slice|soft-launch>

## Aim & Success Metric
<1-sentence Aim + 1–3 measurable metrics>

## Player Loop (30s)
1. Player sees …
2. Player taps/swipes …
3. Game responds …
4. Win/Lose → loop again

## Release Scope (per design-docs.md)
- **IN (MVP)**: Splash, Menu, Pause, Settings, GameOver, persistence, ≥1 SFX, ≥1 VFX, <…P0 features>
- **OUT**: IAP, ads, analytics, leaderboard, localization, multi-mode

## Feature Tree
| ID  | Feature              | Priority | Layer(s)         | Rule ref               | Depends on | Est. |
|-----|----------------------|----------|------------------|------------------------|------------|------|
| F01 | Core Input + Aim     | P0       | Gameplay         | gameplay-code          | —          | 0.5d |
| F02 | Bubble Spawn & Grid  | P0       | Data + Gameplay  | data-files, gameplay   | F01        | 1d   |
| F03 | Match-3 Detect       | P0       | Engine           | engine-code            | F02        | 1d   |
| F04 | Score & Win/Lose     | P0       | Core             | gameplay-code          | F03        | 0.5d |
| F05 | UI HUD               | P1       | UI               | ui-code                | F04        | 0.5d |
| …   |                      |          |                  |                        |            |      |

## Dependency Graph (DAG)
```
F01 → F02 → F03 → F04 → F05
              └──> F06 (VFX, parallel)
```

## Milestones
- **M1 (MVP playable)**: F01–F04 — full level playable
- **M2 (Juice + UI)**: F05–F08 — good feel, HUD in place
- **M3 (Polish)**: F09+ — SFX, VFX, settings

## Risks & Unknowns
- <e.g. flood-fill algorithm for match-3 unclear — spike F03 first>
- <e.g. art not ready, use placeholder shapes>

## @dev assignment hint (per feature)
> When `/execute` runs a feature, `@dev` auto-matches templates in `.claude/templates/`.
> The list below is a hint — not binding.

| Feature | Suggested template       | Rules glob                                    |
|---------|--------------------------|-----------------------------------------------|
| F01     | `input-handler`          | `gameplay-code.md`                            |
| F02     | `pool-spawner` + `so-data` | `gameplay-code.md`, `data-files.md`         |
| F03     | (none yet — `@dev` extracts after coding) | `engine-code.md`           |
| …       |                          |                                               |

## User Review Required
> [!IMPORTANT]
> Before generating per-feature `implementation_plan.md`, user must approve:
> 1. Is the feature tree correctly scoped?
> 2. Is the MoSCoW priority correct?
> 3. Are milestones realistic against the deadline?
```

### 5.2 `brain/<product-slug>/features/<FID>-<slug>/implementation_plan.md`

One folder per feature, schema **identical** to `/plan` output (so `/execute` consumes it as-is):

```markdown
# F0X · <Feature Name>
> Parent: [product_plan.md](../../product_plan.md) | Depends on: F0Y | Est: <Xd>

## Aim
<1 sentence — copy from Feature Tree>

## Acceptance Criteria
- [ ] <specific behavior observable in Play Mode>
- [ ] <specific log / inspector state>

## Proposed Changes

### Data Layer
#### [NEW/MODIFY] <ScriptableObject / Model>
- …

### Core Logic Layer
#### [NEW/MODIFY] <Manager / Controller>
- …

### Gameplay/UI Layer
#### [NEW/MODIFY] <MonoBehaviour / View>
- …

## Verification Plan
- Step 1: Enter Play Mode
- Step 2: …
- Step 3: Check Console is clean

## @dev hint
- Try template match: `<template-name>` (or "none yet — extract later")
- Rules apply: `<rule files>`
```

### 5.3 `brain/<product-slug>/task.md` (master checklist)

```markdown
# Product Task: <Product Name>
> Created: <YYYY-MM-DD>

## Blueprint
- [x] Product plan approved
- [ ] All features have implementation_plan.md

## Features
- [ ] F01 · Core Input + Aim
- [ ] F02 · Bubble Spawn & Grid
- [ ] F03 · Match-3 Detect
- [ ] F04 · Score & Win/Lose
- [ ] F05 · UI HUD
- [ ] …

## Milestones
- [ ] M1 MVP playable
- [ ] M2 Juice + UI
- [ ] M3 Polish

## Closeout
- [ ] /review pass
- [ ] /finish → walkthrough.md
```

## Step 6: Self-review the blueprint ⚠️

Before presenting to the user, check:

- [ ] **Atomic test**: can each feature be demoed independently?
- [ ] **DAG test**: any cycles in the dependency graph?
- [ ] **Scope test**: IN list ≤ 2× the number of P0 features? (larger → scope creep)
- [ ] **Release Scope** has all 6 sections per [design-docs.md](../rules/design-docs.md)?
- [ ] **Rules coverage**: each feature mapped to exactly 1 rule file?
- [ ] **Template reuse**: grepped `.claude/templates/` for reuse suggestions?
- [ ] **Hard rules** ([CLAUDE.md](../../CLAUDE.md)): no feature violates them (direct PlayerPrefs, raw Debug.Log, UnityEditor in runtime…)

> [!CAUTION]
> If the blueprint "looks too simple" → re-check for scope creep or missing P0 features.

## Step 7: Present to user

Short output:

```markdown
✅ **Blueprint created**: brain/<product-slug>/

### Summary
- **Aim**: <…>
- **Features**: <N> features (<x> P0, <y> P1, <z> P2)
- **Milestones**: M1 (<n features>) → M2 → M3
- **Risks**: <top 1–2>

### Next
1. Review `product_plan.md` — approve feature tree & priority
2. Review each `features/<FID>/implementation_plan.md` — edit if needed
3. Call `/execute F01` to start the first feature (or `/plan F0X` to refine first)
```

**STOP. Wait for user approval before doing anything else.**

## Step 8: After user approval

User may:
- `/execute F01` — `@dev` implements F01 per its `implementation_plan.md`
- `/plan F0X` — refine feature X's plan (e.g. when ambiguity surfaces mid-build)
- Manually edit `product_plan.md` then `/blueprint --refresh` (regenerate per-feature plans from the updated tree — not yet implemented; tracked as a follow-up)

---

## Quick reference

| Command                  | Effect                                              |
|--------------------------|-----------------------------------------------------|
| `/blueprint`             | Take a product request → feature tree + N plans    |
| `/blueprint <name>`      | Provide an explicit product slug instead of auto   |
| `/plan F0X`              | Refine feature X's implementation_plan             |
| `/execute F0X`           | Implement feature X (invokes `@dev` internally)    |
| `/finish`                | Close task, extract learnings, walkthrough         |
