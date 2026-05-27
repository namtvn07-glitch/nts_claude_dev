---
name: mono-singleton-base
purpose: Three-tier generic MonoBehaviour singleton base hierarchy — pick StaticInstance / Singleton / PersistentSingleton per lifetime need
when_to_use: Any manager-style MonoBehaviour that needs static access (audio, data, game state, UI manager). Choose tier by collision policy + scene survival
rules_ref: [engine-code, gameplay-code]
tags: [singleton, mono, generic, lifecycle, base-class]
---

## Skeleton
```csharp
// Tier 1 — overrides on duplicate. Good for per-scene managers that reset on reload.
public abstract class StaticInstance<T> : MonoBehaviour where T : MonoBehaviour
{
    public static T Instance { get; private set; }
    protected virtual void Awake() => Instance = this as T;

    protected virtual void OnApplicationQuit()
    {
        Instance?.StopAllCoroutines();
        Instance = null;
        Destroy(gameObject);
    }
    protected virtual void OnDestroy()
    {
        Instance?.StopAllCoroutines();
        Instance = null;
    }
}

// Tier 2 — destroys duplicates, keeps the first instance. Default choice.
public abstract class Singleton<T> : StaticInstance<T> where T : MonoBehaviour
{
    protected override void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        base.Awake();
    }
    public void SetActive(bool isActive)
    {
        if (Instance != null) Instance.gameObject.SetActive(isActive);
    }
}

// Tier 3 — survives scene loads. For audio, save, analytics, network.
public abstract class PersistentSingleton<T> : Singleton<T> where T : MonoBehaviour
{
    protected override void Awake()
    {
        base.Awake();
        if (Instance == this) DontDestroyOnLoad(gameObject);
    }
}
```

## Key Patterns
- Three tiers, pick by lifetime: `StaticInstance` (latest-wins, per-scene), `Singleton` (first-wins, per-scene), `PersistentSingleton` (first-wins, cross-scene).
- Subclass with `public class __NAME__ : Singleton<__NAME__>` — generic self-reference enables strongly-typed `Instance` without cast at call site.
- Always `protected override void Awake()` in subclass; call `base.Awake()` AFTER subclass guards but BEFORE field caching that depends on `Instance`.
- In `Singleton<T>.Awake`, `Destroy(gameObject); return;` — early-return prevents `base.Awake()` from overwriting the surviving `Instance`.
- In `PersistentSingleton<T>.Awake`, guard `DontDestroyOnLoad` with `if (Instance == this)` — the duplicate's `Destroy(gameObject)` is queued for end-of-frame, so without the guard the duplicate marks itself persistent before dying (rare but real edge).
- `Instance?.StopAllCoroutines()` on teardown — leak guard for coroutines started against the static reference; required because subclasses commonly fire-and-forget coroutines.
- `Instance = this as T` is safe: generic constraint `where T : MonoBehaviour` + subclass passes itself as `T`, cast cannot fail.
- Do NOT add `FindObjectOfType<T>()` fallback in `Instance` getter — violates project's no-Find rule and hides scene-setup bugs. Force explicit scene placement.
- Do NOT expose a public `Instance` setter or a `ResetInstance()` test hook here — if needed, override `OnDestroy` in the concrete subclass.
- Subscriptions on `Instance` events must unsubscribe in subscriber's `OnDisable`/`OnDestroy` — base teardown only stops coroutines, it does not clear delegates.
