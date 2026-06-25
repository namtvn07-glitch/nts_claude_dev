---
name: dialog-pooled
purpose: Abstract Dialog base (RectTransform + CanvasGroup, DOTween FadeIn/SlideIn) + generic Dialog<T> with static Open/Close API and canvas sorting via MenuManager.
when_to_use: Any full-screen or panel dialog that needs pooled lifecycle, stack management via MenuManager, and type-safe static accessors.
rules_ref: [ui-code]
tags: [ui, dotween, dialog, pool, generic, singleton, stack, animation]
requires_plugins: [DOTween]   # verify imported before use; STOP-and-warn if missing
---

## Skeleton
```csharp
using System;
using DG.Tweening;
using UnityEngine;

namespace __NAMESPACE__
{
    // ── Enums (DialogHelper.cs or same file) ────────────────────────────────
    public enum UIAnimType { None, SlideIn, FadeIn }
    public enum MoveDirection { BottomScreenEdge, TopScreenEdge, LeftScreenEdge, RightScreenEdge }

    // ── Abstract base ────────────────────────────────────────────────────────
    [RequireComponent(typeof(RectTransform))]
    public abstract class Dialog : MonoBehaviour
    {
        protected RectTransform rectTransform;
        protected CanvasGroup canvasGroup;
        public CanvasGroup CanvasGroup => canvasGroup;

        public UIAnimType animationIn = UIAnimType.FadeIn;
        public Ease easeIn = Ease.OutCubic;
        public MoveDirection positionStart = MoveDirection.LeftScreenEdge;
        [Range(0f,10f)] public float timeAnimationIn = 0.25f;
        [Range(0f,10f)] public float timeDelayIn;

        public UIAnimType animationOut = UIAnimType.FadeIn;
        public Ease easeOut = Ease.InCubic;
        public MoveDirection positionOut = MoveDirection.RightScreenEdge;
        [Range(0f,10f)] public float timeAnimationOut = 0.175f;
        [Range(0f,10f)] public float timeDelayOut;

        public bool isShow = false;
        public bool IsPooled { get; private set; } = false;
        private Action _onHideComplete;

        protected virtual void Awake()
        {
            rectTransform = GetComponent<RectTransform>();
            if (!TryGetComponent(out canvasGroup))
                canvasGroup = gameObject.AddComponent<CanvasGroup>();
        }

        protected virtual void OnEnable()
        {
            IsPooled = false;
            canvasGroup.interactable = false;
            canvasGroup.blocksRaycasts = false;
            canvasGroup.alpha = 0f;
        }

        protected virtual void OnDisable() => IsPooled = true;

        public virtual void OnDialogBecameVisible() { }
        protected virtual void _OnShowCompleted() { }
        protected virtual void _OnHideStart() { }

        public virtual void Show(Action onStart = null, Action onComplete = null, Action onHide = null)
        {
            if (isShow) { onStart?.Invoke(); onComplete?.Invoke(); _OnShowCompleted(); return; }
            isShow = true;
            _onHideComplete = onHide;
            rectTransform.anchoredPosition = Vector2.zero;
            rectTransform.DOKill(complete: true);
            canvasGroup.DOKill(complete: true);
            onStart?.Invoke();
            // FadeIn or SlideIn based on animationIn — see impl
        }

        public virtual void Hide(Action onComplete = null)
        {
            if (!isShow) { onComplete?.Invoke(); _onHideComplete?.Invoke(); _onHideComplete = null; return; }
            _OnHideStart();
            isShow = false;
            canvasGroup.interactable = false;
            canvasGroup.blocksRaycasts = false;
            rectTransform.DOKill(complete: true);
            canvasGroup.DOKill(complete: true);
            // FadeOut or SlideOut based on animationOut — see impl
            // NEVER call SetActive(false) here — pool handles release
        }
    }

    // ── Generic accessor layer ───────────────────────────────────────────────
    public abstract class Dialog<T> : Dialog where T : Dialog<T>
    {
        public static T Instance { get; private set; }

        protected override void OnEnable() { base.OnEnable(); Instance = (T)this; }
        protected virtual void OnDestroy() { if (Instance == this) Instance = null; }

        public static void Open(Action onStart = null, Action onComplete = null, Action onHide = null)
        {
            T inst = (Instance != null && Instance.IsPooled) ? Instance
                     : MenuManager.Instance.CreateDialog<T>();
            inst.ConfigureCanvas();
            MenuManager.Instance.OpenDialog(inst);
            inst.Show(onStart, onComplete, onHide);
        }

        public static void Close(Action onHideComplete = null)
        {
            if (Instance == null) return;
            T toClose = Instance;
            Instance = null;
            toClose.Hide(() => { onHideComplete?.Invoke(); MenuManager.Instance?.CloseDialog(toClose); });
        }

        public void ConfigureCanvas()
        {
            if (TryGetComponent<Canvas>(out var c))
            {
                c.renderMode = RenderMode.ScreenSpaceCamera;
                c.worldCamera = MenuManager.Instance.MainCamera;
                c.overrideSorting = true;
                c.sortingOrder = MenuManager.Instance.GetNextSortingOrder();
            }
        }
    }
}
```

## Key Patterns
- `Dialog<T>` is ONLY the accessor/lifecycle layer; all animation logic lives in `Dialog` base — keep them separate files.
- `Instance` is set in `OnEnable` (pool re-get), cleared in `OnDestroy` — never trust it between frames outside dialog scope.
- `Hide` must NOT call `SetActive(false)` — `MenuManager.CloseDialog` releases to pool which triggers `OnDisable`.
- Pairs with `menu-manager.md`; `MenuManager.Instance` must be present in scene before any `Open` call.
