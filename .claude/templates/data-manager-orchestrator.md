---
name: data-manager-orchestrator
purpose: Concrete singleton DataManager that owns multiple ScriptableObject data-asset references, instantiates them on load, persists each via separate save key, and provides a currency-change queue with static Action broadcast
when_to_use: Project-level data orchestrator that aggregates multiple typed data collections and a UserData base; called once from a bootstrap/loading scene
rules_ref: [gameplay-code, prototype-code]
tags: [singleton, data, orchestrator, persistence]
---

## Skeleton
```csharp
public class __NAME__ : DataManagerBase
{
    // ── Inspector refs (source SO assets — never mutate directly) ────────────
    [SerializeField] private __DATAS_A__ _datasA;
    [SerializeField] private __DATAS_B__ _datasB;

    // ── Runtime instances (Instantiate clones — safe to mutate) ─────────────
    public static __DATAS_A__ datasA;
    public static __DATAS_B__ datasB;

    // ── Singleton ────────────────────────────────────────────────────────────
    public static __NAME__ Instance;
    private void Awake()
    {
        if (Instance == null) { Instance = this; DontDestroyOnLoad(gameObject); }
        else Destroy(gameObject);
    }

    // ── Bootstrap coroutine (called from loading scene) ──────────────────────
    public IEnumerator DoLoad()
    {
        isLoaded = false;
        LoadData();
        isLoaded = true;
        yield return new WaitForEndOfFrame();
    }

    public override void LoadData()
    {
        // KEY INVARIANT: Instantiate SOs so save-delta never mutates source asset.
        datasA = Instantiate(_datasA);
        datasB = Instantiate(_datasB);

        if (__SAVE__.IsExitKey(__SAVE__.DATAS_A_SAVEFILE))
            datasA.UpdateFromSaveData(__SAVE__.LoadData<__DATAS_A_SAVE__>(__SAVE__.DATAS_A_SAVEFILE));
        else
            SaveDatasA();

        // repeat pattern for datasB …
        base.LoadData(); // loads UserDataBase
    }

    public void SaveDatasA()
    {
        if (datasA == null) { __LOG__.Error("SaveDatasA: null"); return; }
        __SAVE__.SaveData(__SAVE__.DATAS_A_SAVEFILE, datasA.GetSaveData());
    }

    public void ResetData()
    {
        // Delete per-collection keys then user key
        __SAVE__.DeleteKey(__SAVE__.DATAS_A_SAVEFILE);
        __SAVE__.DeleteKey(__SAVE__.DATAS_B_SAVEFILE);
        __SAVE__.DeleteKey(__SAVE__.USER_SAVEFILE);
        __SAVE__.DeleteAll(); // project SaveManager wrapper — NOT raw PlayerPrefs.DeleteAll
    }

    // ── Currency queue (zero-alloc: Queue pre-allocated, drain via coroutine) ─
    private readonly Queue<int> _currencyQueue = new Queue<int>();
    private bool _isDrainingCurrency;
    public static Action<int, bool> OnCurrencyChanged;

    public void OnCashChanged(int amount, bool playSound = true)
    {
        _currencyQueue.Enqueue(amount);
        if (!_isDrainingCurrency) StartCoroutine(DrainCurrencyQueue(playSound));
    }

    private IEnumerator DrainCurrencyQueue(bool playSound)
    {
        _isDrainingCurrency = true;
        while (_currencyQueue.Count > 0)
        {
            dataBase.cash += _currencyQueue.Dequeue();
            OnCurrencyChanged?.Invoke(dataBase.cash, playSound);
            yield return null;
        }
        _isDrainingCurrency = false;
    }
}
```

## Key Patterns
- **KEY INVARIANT:** `Instantiate(_datasA)` before `UpdateFromSaveData` — runtime clone absorbs save-delta; source SO asset stays pristine in project. Never skip this step.
- `DoLoad` coroutine is the external entry point; callers `yield return StartCoroutine(DoLoad())` from a bootstrap/loading scene — do not call `LoadData` directly at scene start.
- Currency queue drains one entry per frame — prevents single-frame spike when bulk rewards fire. `_isDrainingCurrency` flag guards against double-coroutine starts.
- `OnCurrencyChanged` is `static Action` — subscribers must unsubscribe in `OnDisable`/`OnDestroy` to avoid leaks across scene reloads.
- **DEVIATION (source):** `PlayerPrefs.DeleteAll()` in `ResetData` violates wrapper rule — replaced with `__SAVE__.DeleteAll()` (project: `Core/SaveManager.cs`).
- **DEVIATION (source):** `DebugHelper.LogError` → `__LOG__.Error` (project: `Core/Log.cs` `[Conditional("UNITY_EDITOR")]`).
- `public static __DATAS_A__ datasA` is a runtime-populated static ref, not an Inspector field — acceptable; Inspector source refs use `[SerializeField] private`.
```
