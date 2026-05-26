---
paths:
  - "prototypes/*/Scripts/Core/**"
---

# Core Engine Code Rules (Unity)

- ZERO allocations in hot paths (`FixedUpdate`, `Update`) — pre-allocate, pool, reuse
- Core systems must NEVER depend on gameplay code (strict dependency direction: core <- gameplay)
- Use standard Unity component lifecycle (`Awake` for references, `Start` for initialization)
- Profile before AND after every optimization — document the measured numbers
- Every public API must have usage examples in its doc comment
- Use deterministic cleanup for all resources (`OnDestroy`, `OnDisable`)

## Examples

**Correct** (zero-alloc hot path):

```csharp
// Pre-allocated list reused each frame
private List<GameObject> _nearbyCache = new List<GameObject>(16);

private void FixedUpdate()
{
    _nearbyCache.Clear();  // Reuse, don't reallocate
    _spatialGrid.QueryRadius(transform.position, _radius, _nearbyCache);
}
```

**Incorrect** (allocating in hot path):

```csharp
private void FixedUpdate()
{
    var nearby = new List<GameObject>();  // VIOLATION: allocates every frame
    nearby = GameObject.FindGameObjectsWithTag("Enemy").ToList();  // VIOLATION: expensive query every frame
}
```
