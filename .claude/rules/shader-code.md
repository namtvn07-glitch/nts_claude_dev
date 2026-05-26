---
paths:
  - "assets/shaders/**"
---

# Shader Code Standards (Unity)

All shader files in `assets/shaders/` must follow these standards to maintain
visual quality, performance, and cross-platform compatibility.

## Naming Conventions
- File naming: `[type]_[category]_[name].[ext]`
  - `SG_Env_Water.shadergraph` (Unity Shader Graph)
  - `sh_env_water.shader` (HLSL/CG)
- Use descriptive names that indicate the material purpose
- Prefix with shader type: `sh_` (standard shader), `SG_` (Shader Graph)

## Code Quality
- All properties/parameters must have descriptive names and appropriate hints
- Group related parameters using `[Header]` in Shader properties
- Comment non-obvious calculations (especially math-heavy sections)
- No magic numbers — use named constants or documented property values
- Include authorship and purpose comment at the top of each shader file

## Performance Requirements
- Document the target platform and complexity budget for each shader
- Use appropriate precision: `half`/`mediump` on mobile where full precision isn't needed
- Minimize texture samples in fragment shaders
- Avoid dynamic branching in fragment shaders — use `step()`, `lerp()`, `smoothstep()`
- No texture reads inside loops
- Two-pass approach for blur effects (horizontal then vertical)

## Cross-Platform
- Test shaders on minimum spec target hardware
- Document which render pipeline the shader targets (URP, HDRP, Built-in)
- Do not mix shaders from different render pipelines in the same directory

## Variant Management
- Minimize shader variants — each variant is a separate compiled shader
- Document all keywords/variants (`#pragma multi_compile` vs `shader_feature`) and their purpose
