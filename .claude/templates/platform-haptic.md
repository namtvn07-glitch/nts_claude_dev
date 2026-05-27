---
name: platform-haptic
purpose: Cross-platform vibration/haptic static wrapper — lazy JNI init on Android (API ≥26 VibrationEffect), DllImport on iOS, user-pref gate
when_to_use: Mobile game needs haptic feedback with Android API-level split and iOS native haptic, controlled by a user toggle
rules_ref: [engine-code]
tags: [haptic, android, ios, jni, platform, static]
---

## Skeleton
```csharp
public static class __NAME__
{
#if UNITY_IOS
    [DllImport("__Internal")]
    private static extern void triggerHapticFeedback(float intensity);
#endif

#if UNITY_ANDROID
    private static AndroidJavaObject _vibrator;
    private static AndroidJavaClass  _vibrationEffect; // API ≥26 only
#endif

    private static bool _initialized;

    public static void Init()
    {
        if (_initialized) return;
#if UNITY_ANDROID
        if (Application.isMobilePlatform)
        {
            var player  = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
            var activity = player.GetStatic<AndroidJavaObject>("currentActivity");
            _vibrator = activity.Call<AndroidJavaObject>("getSystemService", "vibrator");
            if (AndroidVersion >= 26)
                _vibrationEffect = new AndroidJavaClass("android.os.VibrationEffect");
        }
#endif
        _initialized = true;
    }

    public static void Vibrate(long ms)
    {
        if (!__PREF_GATE__) return;   // e.g. SettingsManager.Instance.IsHapticEnabled()
        if (!Application.isMobilePlatform) return;
        Init();
#if UNITY_ANDROID
        if (AndroidVersion >= 26)
            _vibrator.Call("vibrate", _vibrationEffect.CallStatic<AndroidJavaObject>("createOneShot", ms, -1));
        else
            _vibrator.Call("vibrate", ms);
#elif UNITY_IOS
        triggerHapticFeedback(0.6f);
#endif
    }

    public static void Vibrate(long[] pattern, int repeat)
    {
        if (!__PREF_GATE__) return;
        if (!Application.isMobilePlatform) return;
        Init();
#if UNITY_ANDROID
        if (AndroidVersion >= 26)
            _vibrator.Call("vibrate", _vibrationEffect.CallStatic<AndroidJavaObject>("createWaveform", pattern, repeat));
        else
            _vibrator.Call("vibrate", pattern, repeat);
#endif
    }

    public static void VibratePop()  => Vibrate(50L);
    public static void VibratePeek() => Vibrate(100L);

    private static int AndroidVersion
    {
        get
        {
            if (Application.platform != RuntimePlatform.Android) return 0;
            var os = SystemInfo.operatingSystem;
            int pos = os.IndexOf("API-", StringComparison.Ordinal);
            return pos >= 0 && int.TryParse(os.Substring(pos + 4, 2), out int v) ? v : 0;
        }
    }
}
```

## Key Patterns
- Lazy `Init()`: guard `_initialized` flag; call `Init()` at top of each public method — never in static constructor (JNI unsafe there).
- `Application.isMobilePlatform` gate before ALL JNI calls — crashes in Editor otherwise.
- API-26 split: `AndroidVersion >= 26` → `VibrationEffect.createOneShot/createWaveform`; else legacy `vibrator.Call("vibrate", ms)`.
- `__PREF_GATE__` placeholder: user-pref check MUST NOT be hardcoded to `SoundManager.Instance.IsVibrationEnabled()` — bind to whichever settings system the project uses (haptic ≠ audio concern).
- iOS: single `[DllImport("__Internal")]` extern; intensity float maps to UIImpactFeedbackStyle on native side.
- `AndroidVersion` property: parse `SystemInfo.operatingSystem` string for `"API-"` prefix; use `int.TryParse` not `int.Parse` to avoid throw on malformed strings (source bug).
- DEVIATION (source violates): `Debug.Log` / `Debug.LogWarning` must be replaced with `Log.Warn(...)` (`Core/Log.cs`) if any logging is added.
- DEVIATION (source violates): `isVibrationEnabled` was stored via raw `PlayerPrefs` in source — gate MUST route through `Core/SaveManager.cs` wrapper (`__SAVE__.GetInt/SetInt`).
