---
paths:
  - "prototypes/*/Scripts/AI/**"
---

# AI Code Rules

- AI update budget: 2ms per frame maximum — profile to verify
- All AI parameters must be tunable from the Unity Inspector (`[SerializeField]`) or data files
- AI must be debuggable: implement `OnDrawGizmos` visualization hooks for all AI state (paths, perception cones)
- AI should telegraph intentions — players need time to read and react
- Prefer utility-based or behavior tree approaches over hard-coded if/else chains
- Group AI must support formation, flanking, and role assignment
- All AI state machines must log transitions for debugging (`Debug.Log`)
- Never trust AI input from the network without validation
