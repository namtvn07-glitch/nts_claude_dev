---
name: game-state-machine
purpose: Singleton MonoBehaviour game-state base with optional countdown timer, UnityEvents, and virtual lifecycle hooks
when_to_use: Any gameplay scene that needs a central game-state controller (start/pause/resume/win/lose) with optional timer
rules_ref: [gameplay-code, engine-code]
tags: [gameplay, singleton, state-machine, mono]
---

## Skeleton
```csharp
public class __NAME__ : Singleton<__NAME__>
{
    [Header("Configuration")]
    [SerializeField] private bool _isDebug = true;
    [SerializeField] private bool _useTiming = true;
    [SerializeField] private float _maxTime = 30f;

    [Header("Events")]
    public UnityEvent onGameStart, onGameLose, onGameComplete, onGamePause, onGameResume;

    // Prefer enum GameState over 4 bool flags (see Key Patterns)
    private bool _isGameStart, _isGamePause, _isGameComplete, _isGamePlaying;

    private float _timerValue;
    private float Timer
    {
        get => _timerValue;
        set { _timerValue = value; OnTimerUpdate(); }
    }

    protected virtual void Start() => StartCoroutine(InitGame());

    protected virtual void Update()
    {
        if (!_isGameStart || _isGameComplete || _isGamePause || !_isGamePlaying) return;
        if (_useTiming) { if (Timer > 0) { Timer -= Time.deltaTime; UpdateGameFunction(); } else OnOverTime(); }
        else UpdateGameFunction();
    }

    protected virtual void FixedUpdate()
    {
        if (!_isGameStart || _isGameComplete || _isGamePause || !_isGamePlaying) return;
        FixUpdateFunction();
    }

    protected virtual IEnumerator InitGame()
    {
        yield return new WaitForSeconds(0.25f);
        OnInitGame();
    }

    protected virtual void OnInitGame()  { /* reset all flags, Timer = _maxTime */ }
    public virtual void OnStartGame()    { _isGameStart = _isGamePlaying = true; onGameStart?.Invoke(); }
    public virtual void OnPauseGame()    { _isGamePlaying = false; _isGamePause = true; onGamePause?.Invoke(); }
    public virtual void OnResumeGame()   { _isGamePlaying = true; _isGamePause = false; onGameResume?.Invoke(); }
    public virtual void OnCompleteGame() { _isGameComplete = true; _isGamePlaying = false; onGameComplete?.Invoke(); }
    public virtual void OnLose()         { _isGameComplete = true; _isGamePlaying = false; onGameLose?.Invoke(); }

    protected virtual void UpdateGameFunction() { }
    protected virtual void FixUpdateFunction()  { }
    protected virtual void OnTimerUpdate()      { }
    protected virtual void OnOverTime()         { __LOG__.Info(nameof(OnOverTime)); }

    private void SendLog(string msg) { if (_isDebug) __LOG__.Info($"{GetType().Name} {msg}"); }
}
```

## Key Patterns
- Timer property setter auto-fires `OnTimerUpdate()` — never set `_timerValue` directly.
- Virtual hooks (`UpdateGameFunction`, `FixUpdateFunction`, `OnOverTime`) are the only override points; do NOT override `Update`/`FixedUpdate` in subclasses without calling `base`.
- **DEVIATION (source):** Source uses 4 `public bool` state flags — template uses `private`. Refine further to `enum GameState` for exhaustiveness and zero flag-drift.
- **DEVIATION (source):** Source has `[HideInInspector] public int currentIndex, orderIndex` — replaced with `[SerializeField] private` + property if Inspector access needed.
- **DEVIATION (source):** `DebugHelper.Log` → `__LOG__.Info` placeholder (project: `Core/Log.cs` `[Conditional("UNITY_EDITOR")]`).
- **STRIPPED:** Lines 183–239 of source (`PlayerController`, `CheckDeathConditions`, `OnJump/Attack/PlayerChanged/Weapon`, `BackToMainScene`, `TriggerCheckpoint/Finish`) are domain code — do NOT include in derived classes without project-specific justification.
- UnityEvents on `public` field is acceptable here (Inspector wiring); do not apply `[SerializeField] private` to UnityEvents meant for Inspector drag-and-drop.
```
