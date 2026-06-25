---
paths:
  - "Unity/design/gdd/gdd.md"
---

# Design Document Rules

- The design document MUST contain the **6 standard sections**: Game Identity, Core Loop, Rules & Mechanics, Object List, Emotional Target, **Release Scope**.
- **Rules & Mechanics** must include precise win/lose conditions and scoring.
- **Object List** MUST be a comprehensive list of all visual entities required for the Artist (Characters, Environment, UI, Audio).
- **Release Scope** MUST list Build Target (platform, min SDK, orientation, session length, target FPS), full IN list (Splash + Menu + Pause + Settings + GameOver + persistence + ≥1 SFX + ≥1 VFX), and explicit OUT list (IAP, ads, analytics, leaderboards, localization, multi-mode).
- No hand-waving: "the system should feel good" is not a valid specification. Be specific about input and visual feedback.
- Balance values (if any) must be explicitly listed in the Parameters section.
- Design documents MUST be written incrementally: ask the user one question at a time and draft the sections based on user approval. Do NOT hallucinate gameplay elements not discussed with the user.

