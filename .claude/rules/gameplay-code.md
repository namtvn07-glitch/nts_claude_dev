---
paths:
  - "prototypes/*/Scripts/Gameplay/**"
  - "Unity/*/Assets/Scripts/Gameplay/**"
---

# Gameplay Code Rules (Unity)

- ALL gameplay values MUST be exposed via `[SerializeField]`, NEVER hardcoded in the method body
- Use `Time.deltaTime` for ALL time-dependent calculations in `Update` (and `Time.fixedDeltaTime` in `FixedUpdate`)
- NO direct references to UI code — use C# `Action` or UnityEvents for cross-system communication
- Avoid `FindObjectOfType` or `GameObject.Find` — use inspector references or dependency injection
- State machines must have explicit transition logic with documented states
- Write clean and decoupled logic, isolating data from presentation

## Examples

**Correct** (data-driven):

```csharp
using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    [SerializeField] private float _baseSpeed = 10f;
    [SerializeField] private StatsResource _statsResource;

    private void Update()
    {
        float speed = _statsResource.MovementSpeed * _baseSpeed * Time.deltaTime;
        transform.Translate(Vector3.forward * speed);
    }
}
```

**Incorrect** (hardcoded):

```csharp
using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    private void Update()
    {
        float speed = 25.0f;   // VIOLATION: hardcoded gameplay value inside method
        speed = 5.0f;          // VIOLATION: not exposed, not using delta time
        transform.Translate(Vector3.forward * speed);
    }
}
```
