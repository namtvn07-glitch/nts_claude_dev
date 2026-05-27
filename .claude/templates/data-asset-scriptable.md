---
name: data-asset-scriptable
purpose: Paired triplet — runtime entity TData, slim TSaveData POCO, ScriptableObject TDatas collection with ForceData/GetSaveData/UpdateFromSaveData and CustomEditor button
when_to_use: Any unlockable/configurable entity list (characters, weapons, levels, etc.) that needs source-asset protection and per-item save-delta
rules_ref: [data-files, gameplay-code]
tags: [scriptable-object, data, editor, serialization]
---

## Skeleton
```csharp
// ── 1. Runtime entity ────────────────────────────────────────────────────────
[Serializable]
public class __TYPE__Data : IDataBase
{
    // Public fields: Unity serialization convention for data POCOs — acceptable.
    public bool __CUSTOM_FIELD__;
}

// ── 2. Slim save POCO ────────────────────────────────────────────────────────
[Serializable]
public class __TYPE__SaveData
{
    public int index;
    public int saveValue;
    public bool isOwner;
}
[Serializable]
public class __TYPE__SaveDatas
{
    public List<__TYPE__SaveData> data = new List<__TYPE__SaveData>();
}

// ── 3. ScriptableObject collection ──────────────────────────────────────────
// ⚠ VIOLATION IN SOURCE: `using UnityEditor;` was unguarded at file top.
// MUST split editor class into a separate file under Editor/ folder OR guard as shown below.
[CreateAssetMenu(fileName = "__TYPE__Datas", menuName = "DataAsset/__TYPE__Datas")]
public class __TYPE__Datas : ScriptableObject
{
    public List<__TYPE__Data> data = new List<__TYPE__Data>();

    public void ForceData()
    {
        // Seed/normalise: assign sequential index + default name to each entry
        for (int i = 0; i < data.Count; i++) { data[i].index = i; data[i].name = "__TYPE__ " + (i + 1); }
    }

    public __TYPE__SaveDatas GetSaveData()
    {
        // Project save fields → slim save POCO list
        var result = new __TYPE__SaveDatas();
        foreach (var d in data) result.data.Add(new __TYPE__SaveData { index = d.index, saveValue = d.saveValue, isOwner = d.isOwner });
        return result;
    }

    public void UpdateFromSaveData(__TYPE__SaveDatas savedata)
    {
        // merge runtime ← save by index; skip out-of-range entries
        if (savedata?.data == null) return;
        foreach (var s in savedata.data) { if (s.index >= 0 && s.index < data.Count) { data[s.index].saveValue = s.saveValue; data[s.index].isOwner = s.isOwner; } }
    }
}

// ── 4. Paired CustomEditor — place in Editor/ folder ────────────────────────
#if UNITY_EDITOR
// using UnityEditor; — put this at top of the Editor-only file, NOT in the runtime file
[CustomEditor(typeof(__TYPE__Datas))]
[CanEditMultipleObjects]
public class __TYPE__DatasEditor : Editor
{
    public override void OnInspectorGUI()
    {
        var t = (__TYPE__Datas)target;
        if (GUILayout.Button("Force Data")) { t.ForceData(); EditorUtility.SetDirty(t); }
        DrawDefaultInspector();
    }
}
#endif
```

## Key Patterns
- **CRITICAL VIOLATION IN SOURCE:** `using UnityEditor;` appears at file top **unguarded** in `CharacterDatas.cs`/`WeaponDatas.cs` — causes Android build failure. Fix: move `CustomEditor` class to a file under `Editor/` folder (preferred) OR wrap both `using UnityEditor;` and the editor class in `#if UNITY_EDITOR`.
- `ForceData()`: editor-only seed — normalises indices so runtime indexing is always stable; call via Inspector button, never at runtime.
- `Instantiate` the SO before calling `UpdateFromSaveData` (done in orchestrator, not here) — never mutate the source asset with save-delta.
- `GetSaveData` / `UpdateFromSaveData` form the serialise/deserialise contract — keep them symmetric.
- `public` fields on `[Serializable]` POCOs (`IDataBase`, `__TYPE__Data`, `__TYPE__SaveData`) are Unity serialization convention — NOT the same case as Inspector vars on MonoBehaviours.
```
