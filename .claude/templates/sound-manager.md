---
name: sound-manager
purpose: Singleton audio manager — DontDestroyOnLoad, round-robin SFX pool, dict lookup by string ID, volume tree (master × music/sfx), music fade coroutine, runtime clip add/remove
when_to_use: Game needs centralized audio with persistent volume settings, multiple simultaneous SFX, and crossfade music
rules_ref: [engine-code, prototype-code]
tags: [singleton, audio, pool, ddol, coroutine]
---

## Skeleton
```csharp
namespace __NAMESPACE__
{
    [Serializable]
    public class AudioClipData { public string id; public AudioClip clip; }

    public class __NAME__ : MonoBehaviour
    {
        public static __NAME__ Instance { get; private set; }

        [SerializeField] private List<AudioClipData> _musicClips;
        [SerializeField] private List<AudioClipData> _sfxClips;
        [Range(0f,1f)][SerializeField] private float _masterVolume = 1f;
        [Range(0f,1f)][SerializeField] private float _musicVolume  = 1f;
        [Range(0f,1f)][SerializeField] private float _sfxVolume    = 1f;

        private AudioSource _musicSource;
        private AudioSource[] _sfxPool;          // pre-allocated, size __POOL_SIZE__
        private int _poolIndex;
        private Dictionary<string, AudioClip> _musicDict = new();
        private Dictionary<string, AudioClip> _sfxDict   = new();

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
            BuildSources();   // auto-create child AudioSources + pool
            BuildDicts();     // populate dictionaries from serialized lists
            LoadVolumes();    // __SAVE__.GetFloat(key, default) — NOT raw PlayerPrefs
        }

        private void OnDestroy() => SaveVolumes(); // __SAVE__.SetFloat(key, value)

        // --- SFX ---
        public void PlaySFX(string id)
        {
            if (!_sfxDict.TryGetValue(id, out var clip)) { Log.Warn($"SFX '{id}' not found"); return; }
            var src = _sfxPool[_poolIndex++ % _sfxPool.Length]; // round-robin, zero alloc
            src.clip = clip; src.Play();
        }

        // --- Music ---
        public void PlayMusic(string id, bool fade = false)
        {
            if (!_musicDict.TryGetValue(id, out var clip)) { Log.Warn($"Music '{id}' not found"); return; }
            if (fade) StartCoroutine(FadeTo(clip, __FADE_DURATION__));
            else { _musicSource.clip = clip; _musicSource.Play(); }
        }
        private IEnumerator FadeTo(AudioClip next, float duration) { /* lerp out → swap → lerp in */ yield break; }

        // --- Volume ---
        public void SetMasterVolume(float v) { _masterVolume = Mathf.Clamp01(v); ApplyVolumes(); SaveVolumes(); }
        public void SetMusicVolume(float v)  { _musicVolume  = Mathf.Clamp01(v); ApplyVolumes(); SaveVolumes(); }
        public void SetSfxVolume(float v)    { _sfxVolume    = Mathf.Clamp01(v); ApplyVolumes(); SaveVolumes(); }

        // --- Runtime clip API ---
        public void AddClip(string id, AudioClip clip, bool isSfx) { (isSfx ? _sfxDict : _musicDict)[id] = clip; }
        public void RemoveClip(string id, bool isSfx) { (isSfx ? _sfxDict : _musicDict).Remove(id); }
    }
}
```

## Key Patterns
- Singleton guard in `Awake`: duplicate instance → `Destroy(gameObject)` immediately; `DontDestroyOnLoad` only on surviving instance.
- SFX pool: pre-allocate `AudioSource[]` in `Awake`; round-robin index `(i++ % size)` — zero alloc per play call.
- Volume tree: effective volume = `masterVolume * trackVolume`; apply to all pool sources on every volume change.
- Fade coroutine: lerp `musicSource.volume` to 0, swap clip, lerp back up — stop coroutine on `OnDisable` to avoid orphaned routines.
- DEVIATION (source violates): persistence MUST use `__SAVE__.GetFloat/SetFloat` (project `Core/SaveManager.cs`) — NOT raw `PlayerPrefs`. Replace `__SAVE__` with your SaveManager wrapper.
- DEVIATION (source violates): missing-clip warnings MUST use `Log.Warn(...)` (`Core/Log.cs`, `[Conditional("UNITY_EDITOR")]`) — NOT `Debug.LogWarning`.
- `isVibrationEnabled` flag belongs in haptic wrapper, not in audio manager — keep concerns separate.
