---
paths:
  - "prototypes/*/Scripts/Networking/**"
  - "Unity/*/Assets/Scripts/Networking/**"
---

# Network Code Rules

- Server is AUTHORITATIVE for all gameplay-critical state — never trust the client
- Client predicts locally, reconciles with server — implement rollback for mispredictions
- Handle disconnection, reconnection, and host migration gracefully
- Rate-limit all network logging to prevent log flooding
- All networked values must specify replication strategy: reliable/unreliable, frequency, interpolation
- Security: validate all incoming packet sizes and field ranges
