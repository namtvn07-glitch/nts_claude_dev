---
name: menu-manager
purpose: Singleton MonoBehaviour managing dialog ObjectPool (UnityEngine.Pool), active-dialog stack (List push/pop), canvas sorting order, and off-screen start-position calculation.
when_to_use: Scene needs a central registry that creates, pools, stacks, and sorts dialogs. Pairs with dialog-pooled.md.
rules_ref: [ui-code, engine-code]
tags: [ui, singleton, pool, stack, dialog, mono]
---

## Skeleton
```csharp
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;

namespace __NAMESPACE__
{
    public class MenuManager : MonoBehaviour
    {
        public static MenuManager Instance { get; private set; }

        [SerializeField] private Camera _mainCamera;
        [SerializeField] private Dialog[] _dialogPrefabs;   // Inspector-assigned prefabs

        private RectTransform _selfRect;
        private readonly List<Dialog> _activeDialogs = new();
        private readonly Dictionary<Type, ObjectPool<Dialog>> _pools = new();
        private int _sortingOrder = 100;

        public Camera MainCamera => _mainCamera;

        private void Awake()
        {
            Instance = this;
            if (_mainCamera == null) _mainCamera = Camera.main;
            _selfRect = GetComponent<RectTransform>();
        }

        private void OnDestroy()
        {
            Instance = null;
            foreach (var pool in _pools.Values) pool.Dispose();
            _pools.Clear();
        }

        // ── Pool ─────────────────────────────────────────────────────────────
        public T CreateDialog<T>() where T : Dialog
        {
            var type = typeof(T);
            if (!_pools.ContainsKey(type))
            {
                var prefab = FindPrefab<T>();
                _pools[type] = new ObjectPool<Dialog>(
                    createFunc:      () => { var i = Instantiate(prefab, transform); i.name = prefab.name; return i; },
                    actionOnGet:     d => d.gameObject.SetActive(true),
                    actionOnRelease: d => { d.isShow = false; if (d.CanvasGroup != null) d.CanvasGroup.alpha = 0f; d.gameObject.SetActive(false); },
                    actionOnDestroy: d => Destroy(d.gameObject),
                    defaultCapacity: 4
                );
            }
            return (T)_pools[type].Get();
        }

        // ── Stack ─────────────────────────────────────────────────────────────
        public void OpenDialog(Dialog instance)
        {
            Dialog prev = TopDialog();
            if (_activeDialogs.Contains(instance)) _activeDialogs.Remove(instance);
            _activeDialogs.Add(instance);
            if (prev != null && prev != instance)
                prev.Hide(() => { if (prev.CanvasGroup != null) { prev.CanvasGroup.interactable = false; prev.CanvasGroup.blocksRaycasts = false; } });
            instance.OnDialogBecameVisible();
        }

        public void CloseDialog(Dialog instance)
        {
            if (instance == null || !_activeDialogs.Contains(instance)) return;
            _activeDialogs.Remove(instance);
            var type = instance.GetType();
            if (_pools.TryGetValue(type, out var pool)) pool.Release(instance);
        }

        // ── Helpers ───────────────────────────────────────────────────────────
        public int GetNextSortingOrder() => ++_sortingOrder;

        public Vector2 GetStartPosition(RectTransform dialogRect, MoveDirection dir)
        {
            if (_selfRect == null) return Vector2.zero;
            float pw = _selfRect.rect.width, ph = _selfRect.rect.height;
            float dw = dialogRect.rect.width,  dh = dialogRect.rect.height;
            return dir switch
            {
                MoveDirection.BottomScreenEdge => new Vector2(0, -(ph / 2) - (dh / 2)),
                MoveDirection.TopScreenEdge    => new Vector2(0,  (ph / 2) + (dh / 2)),
                MoveDirection.LeftScreenEdge   => new Vector2(-(pw / 2) - (dw / 2), 0),
                MoveDirection.RightScreenEdge  => new Vector2( (pw / 2) + (dw / 2), 0),
                _                              => Vector2.zero
            };
        }

        private Dialog TopDialog()
        {
            for (int i = _activeDialogs.Count - 1; i >= 0; i--)
            {
                if (_activeDialogs[i] != null) return _activeDialogs[i];
                _activeDialogs.RemoveAt(i);
            }
            return null;
        }

        private T FindPrefab<T>() where T : Dialog
        {
            foreach (var p in _dialogPrefabs)
                if (p != null && p.GetType() == typeof(T)) return (T)p;
            throw new MissingReferenceException($"No prefab registered for {typeof(T)}");
        }
    }
}
```

## Key Patterns
- `_pools` keyed by `Type` — one `ObjectPool<Dialog>` per concrete dialog type, lazy-created on first `CreateDialog<T>`.
- `actionOnRelease` resets `isShow` + `alpha` before returning to pool — prevents stale visual state on re-get.
- `OpenDialog` hides the previous top before pushing new — auto-stacking without caller coordination.
- `OnDestroy` disposes all pools (`pool.Dispose()`) — prevents native handle leaks on scene unload.
- `GetStartPosition` relies on `_selfRect` (root canvas RectTransform on same GO) — must be placed on Canvas root.
