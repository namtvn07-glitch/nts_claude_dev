---
name: ui-anim-base
purpose: Standalone DOTween-based UI element with Show/Hide animation (localPosition lerp + optional fade scale). No external manager dependency.
when_to_use: Any RectTransform that needs inspector-tunable animate-in / animate-out without dialog stack management.
rules_ref: [ui-code]
tags: [ui, dotween, animation, mono]
requires_plugins: [DOTween]   # verify imported before use; STOP-and-warn if missing
---

## Skeleton
```csharp
using System;
using DG.Tweening;
using UnityEngine;

namespace __NAMESPACE__
{
    public class __NAME__ : MonoBehaviour
    {
        [SerializeField] private bool _playOnEnable = false;
        [SerializeField] private bool _useFade = false;

        [Header("Anim In")]
        [SerializeField] private Ease _easeIn = Ease.OutCubic;
        [SerializeField] private float _timeIn = 0.25f;
        [SerializeField] private float _delayIn = 0f;
        [SerializeField] private Vector2 _offsetIn = Vector2.one;

        [Header("Anim Out")]
        [SerializeField] private Ease _easeOut = Ease.InCubic;
        [SerializeField] private float _timeOut = 0.175f;
        [SerializeField] private float _delayOut = 0f;
        [SerializeField] private Vector2 _offsetOut = Vector2.one;

        private RectTransform _rect;
        private Vector2 _originPos;
        private Action _onHideCompleted;

        private void Start()
        {
            _rect = GetComponent<RectTransform>();
            _originPos = _rect.localPosition;
            if (_playOnEnable) Show();
        }

        protected virtual void OnDisable() => _rect.DOKill(complete: true);

        public void Show(Action onStart = null, Action onComplete = null, Action onHide = null)
        {
            if (_rect == null) _rect = GetComponent<RectTransform>();
            gameObject.SetActive(true);
            _onHideCompleted = onHide;
            onStart?.Invoke();
            _rect.DOKill(complete: true);
            _rect.localPosition = _originPos + _offsetIn;
            if (_useFade) _rect.localScale = Vector3.zero;
            float t = 0f;
            DOTween.To(() => t, x =>
            {
                if (_useFade) _rect.localScale = Vector3.one * x;
                _rect.localPosition = Vector2.Lerp(_originPos + _offsetIn, _originPos, x);
            }, 1f, _timeIn).SetDelay(_delayIn).SetEase(_easeIn).SetUpdate(true).SetTarget(_rect)
            .OnComplete(() => { if (_useFade) _rect.localScale = Vector3.one; onComplete?.Invoke(); _OnShowCompleted(); });
        }

        public void Hide(Action onComplete = null)
        {
            if (_rect == null) _rect = GetComponent<RectTransform>();
            _rect.DOKill();
            Vector2 target = _originPos + _offsetOut;
            Vector2 start = _rect.localPosition;
            float t = 1f;
            DOTween.To(() => t, x =>
            {
                if (_useFade) _rect.localScale = Vector3.one * x;
                _rect.localPosition = Vector2.Lerp(target, start, x);
            }, 0f, _timeOut).SetDelay(_delayOut).SetEase(_easeOut).SetUpdate(true).SetTarget(_rect)
            .OnComplete(() =>
            {
                if (_useFade) _rect.localScale = Vector3.zero;
                onComplete?.Invoke();
                _onHideCompleted?.Invoke();
                _OnHideCompleted();
                gameObject.SetActive(false);
            });
        }

        public void SetHide() => gameObject.SetActive(false);

        protected virtual void _OnShowCompleted() { }
        protected virtual void _OnHideCompleted() { }
    }
}
```

## Key Patterns
- `DOKill(complete:true)` in `OnDisable` — prevents orphan tweens on pool release or scene unload.
- `SetUpdate(true)` on all tweens — animation survives `Time.timeScale = 0` (pause screens).
- `_rect` null-checked in `Show`/`Hide` — safe to call before `Start` fires (pool early-get).
- Override `_OnShowCompleted` / `_OnHideCompleted` for subclass hooks; never re-expose `Action` as `public` field.
