---
paths:
  - "prototypes/*/Scripts/Tests/**"
---

# Test Standards (Unity / NUnit)

- Test naming: `Test_[System]_[Scenario]_[ExpectedResult]` pattern
- Every test must have a clear Arrange / Act / Assert structure
- Unit tests must not depend on external state (filesystem, network, database)
- Integration tests must clean up after themselves (use `[TearDown]`)
- Test data must be defined in the test or in dedicated fixtures, never shared mutable state
- Mock external dependencies — tests should be fast and deterministic
- Use NUnit assertions (`Assert.AreEqual`, `Assert.IsTrue`)

## Examples

**Correct** (proper naming + Arrange/Act/Assert):

```csharp
using NUnit.Framework;

[TestFixture]
public class HealthSystemTests
{
    [Test]
    public void Test_HealthSystem_TakeDamage_ReducesHealth()
    {
        // Arrange
        var health = new HealthComponent();
        health.MaxHealth = 100;
        health.CurrentHealth = 100;

        // Act
        health.TakeDamage(25);

        // Assert
        Assert.AreEqual(75, health.CurrentHealth);
    }
}
```

**Incorrect**:

```csharp
using NUnit.Framework;

[TestFixture]
public class HealthSystemTests
{
    [Test]
    public void Test1() // VIOLATION: no descriptive name
    {
        var h = new HealthComponent();
        h.TakeDamage(25); // VIOLATION: no arrange step, no clear assert
        Assert.IsTrue(h.CurrentHealth < 100); // VIOLATION: imprecise assertion
    }
}
```
