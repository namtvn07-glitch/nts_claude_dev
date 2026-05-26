---
paths:
  - "prototypes/**"
---

# Production Code Rules

> Filename kept as `prototype-code.md` for path-glob stability. Content applies to all gameplay code shipped under `prototypes/**`.

This team enforces **PRODUCTION STANDARDS** so the codebase can ship to soft-launch as an APK and migrate cleanly into the Full Studio workflow later.

## What is REQUIRED

- **Clean Architecture:** Decouple Core, Gameplay, and UI components.
- **Event-Driven:** Use C# Events/Actions for cross-communication; avoid direct coupling (especially Gameplay -> UI).
- **Inspector Configuration:** Expose variables via `[SerializeField]` in the Unity Inspector instead of hardcoding them inside methods.
- **Robust References:** Avoid `GameObject.Find` or `GetComponent` in `Update()` loops. Cache components in `Awake()`.
- **Documentation:** Every prototype folder MUST have a `README.md` defining the hypothesis, how to run, and the findings.
- **Error Handling:** Code must be robust and handle missing references gracefully (use null checks).
- **Persistence wrapper:** All `PlayerPrefs.*` access MUST go through `Core/SaveManager.cs` (static helper). Gameplay/UI never call `PlayerPrefs.*` directly. Key naming: `[game]_[key]` (e.g., `bubbleasmr_highscore`).
- **Logging discipline:** Use `Core/Log.cs` with `[Conditional("UNITY_EDITOR")]` methods instead of raw `Debug.Log`. This strips logs from the shipping APK automatically.
- **Build readiness:** Code MUST compile against `BuildTarget.Android` with no errors. No editor-only API (`using UnityEditor;`) in `Scripts/Gameplay/` or `Scripts/UI/`.
- **UX flow completeness:** Every UI screen (Menu, Pause, Settings, GameOver) MUST have a working back/forward path. No dead-end screens.

## What is FORBIDDEN

- Spaghetti code and massive monolithic classes (the "God Object" anti-pattern).
- Hardcoded magic numbers inside game logic calculations.
- Direct UI manipulation from Gameplay scripts.
- Singletons used as a crutch for bad architecture (unless specifically for a Manager system like `GameManager`).
- `PlayerPrefs.*` calls outside `Core/SaveManager.cs`.
- `using UnityEditor;` in any file under `Scripts/Gameplay/` or `Scripts/UI/`.
- Raw `Debug.Log` calls in `Scripts/Gameplay/` or `Scripts/UI/` (use wrapped `Log.Info/Warn/Error` from `Core/Log.cs`).
- Development Build flag set ON when producing the shipping APK.

> Note: prototypes here are small in scope, but the quality of the C# scripts must remain high — the APK is shipped to real users in soft-launch.
