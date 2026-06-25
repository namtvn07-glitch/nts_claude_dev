---
paths:
  - "prototypes/**"
  - "Unity/*/Assets/Scripts/**"
---

# Production Code Rules

> Filename kept as `prototype-code.md` for path-glob stability. Content applies to all gameplay code shipped under `prototypes/**`.

This team enforces **PRODUCTION STANDARDS** so the codebase can ship to soft-launch as an APK and migrate cleanly into the Full Studio workflow later.

## What is REQUIRED

- **Clean Architecture:** Decouple Core, Gameplay, and UI components.
- **Event-Driven:** Use C# Events/Actions for cross-communication; avoid direct coupling (especially Gameplay -> UI).
- **Inspector Configuration:** Expose variables via `[SerializeField]` in the Unity Inspector instead of hardcoding them inside methods.
- **Robust References:** Avoid `FindObjectOfType` / `GameObject.Find` / `GetComponent` in `Update()`/`FixedUpdate()`. Cache components in `Awake()`.
- **Event lifecycle:** Subscribe in `OnEnable`, **unsubscribe in `OnDisable`/`OnDestroy`**; kill DOTween tweens on disable/destroy (leak guard).
- **Singleton-event subscription (init-order safe):** When subscribing to ANOTHER singleton/manager's static event (e.g. `GameStateMachine.Instance.OnStateChanged`), the publisher's `Instance` may be null at your `OnEnable` (Awake/OnEnable order across objects — even components on the same GameObject — is NOT guaranteed). NEVER subscribe with a bare `if (X.Instance != null) X.Instance.Evt += …` in `OnEnable` only — if the publisher isn't ready yet it **silently never subscribes** and the feature dies with no error. REQUIRED pattern: a guarded `TrySubscribe()` (idempotent via a `_subscribed` flag) called from BOTH `OnEnable` AND `Start` (Start runs after all Awakes), and unsubscribe in `OnDisable`. (Reference impls: `HubScreen`, `MiniGameManager`, `OverlayController`.) Same applies to reading another singleton's `Instance` for setup — retry in `Start`, don't assume `OnEnable` ordering.
- **Hot-path allocation:** Zero per-frame GC alloc in `Update`/input/spawn paths — pre-allocate, pool repeated objects (bubbles, particles, slices, drops), reuse.
- **Documentation:** Every prototype folder MUST have a `README.md` defining the hypothesis, how to run, and the findings.
- **Error Handling:** Code must be robust and handle missing references gracefully (use null checks).
- **Persistence wrapper:** All persistence (`PlayerPrefs.*`, Easy Save `ES3.*`, file IO) MUST go through `Core/SaveManager.cs`. Gameplay/UI/MiniGames never call the persistence backend directly.
- **Plugin dependencies (STOP-and-warn):** When a template or task needs a third-party plugin (see the template's `requires_plugins` frontmatter — e.g. DOTween for tweens, Easy Save for persistence), **verify the plugin is imported** in the project (search `Assets/Plugins`, DLLs, or asmdef references) BEFORE writing code. If it is missing → **STOP and warn the user to import it**; do NOT stub it, inline-reimplement it, or silently fall back. Also flag the asmdef gotcha: a plugin whose source lives in `Assembly-CSharp` is invisible to an asmdef — it needs its own asmdef + an explicit reference (and any package refs it relies on, e.g. `Unity.VisualScripting.Core`).
- **Logging discipline:** Use `Core/Log.cs` with `[Conditional("UNITY_EDITOR")]` methods instead of raw `Debug.Log`. This strips logs from the shipping APK automatically.
- **Build readiness:** Code MUST compile against `BuildTarget.Android` with no errors. No editor-only API (`using UnityEditor;`) in `Scripts/Gameplay/`, `Scripts/UI/`, or `Scripts/MiniGames/`.
- **UX flow completeness:** Every UI screen (Menu, Pause, Settings, GameOver) MUST have a working back/forward path. No dead-end screens.

## What is FORBIDDEN

- Spaghetti code and massive monolithic classes (the "God Object" anti-pattern).
- Hardcoded magic numbers inside game logic calculations.
- Direct UI manipulation from Gameplay scripts.
- Singletons used as a crutch for bad architecture (unless specifically for a Manager system like `GameManager`).
- Direct persistence calls (`PlayerPrefs.*`, `ES3.*`, file IO) outside `Core/SaveManager.cs`.
- Stubbing / inline-reimplementing a missing third-party plugin instead of stopping to warn the user (see Plugin dependencies).
- **Coroutine-as-lifecycle**: `IEnumerator Start()` / `IEnumerator OnEnable()` (Unity magic-method coroutines). Use a normal `void Start()` that calls `StartCoroutine(NamedRoutine())` with a separate named `IEnumerator` — named routines are referenceable and `StopCoroutine`-able, the magic-method form is neither and silently swallows exceptions on disable.
- `using UnityEditor;` in any file under `Scripts/Gameplay/` or `Scripts/UI/`.
- Raw `Debug.Log` calls in `Scripts/Gameplay/` or `Scripts/UI/` (use wrapped `Log.Info/Warn/Error` from `Core/Log.cs`).
- Development Build flag set ON when producing the shipping APK.

> Note: prototypes here are small in scope, but the quality of the C# scripts must remain high — the APK is shipped to real users in soft-launch.
