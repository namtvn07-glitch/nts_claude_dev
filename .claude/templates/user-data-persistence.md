---
name: user-data-persistence
purpose: Abstract MonoBehaviour data-manager base + Serializable user-data POCO with load/save/autosave lifecycle
when_to_use: Any project needing a persistent user-progression store (session count, currency, unlocks) loaded once on startup
rules_ref: [prototype-code, gameplay-code]
tags: [persistence, save, data, mono]
---

## Skeleton
```csharp
// ── Base class ──────────────────────────────────────────────────────────────
public class DataManagerBase : MonoBehaviour
{
    public static bool isLoaded = false;
    public static __USERDATA__ dataBase;

    public virtual void LoadData()
    {
        if (__SAVE__.IsExitKey(__SAVE__.USER_SAVEFILE))
            dataBase = __SAVE__.LoadData<__USERDATA__>(__SAVE__.USER_SAVEFILE);

        if (dataBase == null)
        {
            dataBase = new __USERDATA__();
            SaveData();
        }
    }

    public virtual void SaveData()
    {
        if (dataBase == null) { __LOG__.Error("SaveData: dataBase is null"); return; }
        __SAVE__.SaveData(__SAVE__.USER_SAVEFILE, dataBase);
    }

    protected void OnApplicationQuit()
    {
        if (isLoaded) SaveData();
    }
}

// ── User data POCO ───────────────────────────────────────────────────────────
[Serializable]
public class __USERDATA__
{
    // Public fields are intentional for Unity serialization — NOT the same as Inspector vars on MonoBehaviours.
    public int totalPlay = 0;
    public int cash = 0;
    // Add project-specific progression fields here

    public __USERDATA__()
    {
        totalPlay = 0;
        cash = 0;
    }
}
```

## Key Patterns
- `isLoaded` static guard prevents `OnApplicationQuit` saving an uninitialised `dataBase` (null-check + flag both required).
- `LoadData`: check key → deserialise OR construct default + save immediately — never leave `dataBase == null` after load.
- `SaveData`: null-guard before write; log error via `__LOG__` if null, do NOT silently swallow.
- **DEVIATION (source):** `StorageHelper.*` → `__SAVE__.*` placeholder (project: `Core/SaveManager.cs`; key naming convention `[game]_[key]`).
- **DEVIATION (source):** `DebugHelper.LogError` → `__LOG__.Error` (project: `Core/Log.cs` `[Conditional("UNITY_EDITOR")]`).
- `public` fields on `[Serializable]` POCO are Unity serialization convention — acceptable here; differs from rule requiring `[SerializeField] private` on MonoBehaviour Inspector vars.
```
