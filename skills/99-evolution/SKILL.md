---
name: makepad-evolution
description: Self-improving skill system for Makepad development. Features self-evolution (accumulate knowledge), self-correction (fix errors automatically), self-validation (verify accuracy), usage feedback (track pattern health), version adaptation (multi-branch support), and personalization (adapt to project style).
---

# Makepad Skills Evolution

This skill enables makepad-skills to self-improve continuously during development.

## Quick Navigation

| Topic | Description |
|-------|-------------|
| [Collaboration Guidelines](references/collaboration.md) | **Contributing to makepad-skills** |
| [Hooks Setup](#hooks-based-auto-triggering) | Auto-trigger evolution with hooks |
| [When to Evolve](#when-to-evolve) | Triggers and classification |
| [Evolution Process](#evolution-process) | Step-by-step guide |
| [Self-Correction](#self-correction) | Auto-fix skill errors |
| [Self-Validation](#self-validation) | Verify skill accuracy |
| [Version Adaptation](#version-adaptation) | Multi-branch support |

---

## Hooks-Based Auto-Triggering

For reliable automatic triggering, use Claude Code hooks. Copy the hooks to your project:

```bash
# Copy hooks to your project
cp -r .claude/skills/99-evolution/hooks your-project/.claude/skills/hooks
chmod +x your-project/.claude/skills/hooks/*.sh
```

Then merge `hooks/settings.example.json` into your `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/skills/hooks/pre-tool.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/skills/hooks/post-bash.sh \"$TOOL_OUTPUT\" \"$EXIT_CODE\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/skills/hooks/session-end.sh"
          }
        ]
      }
    ]
  }
}
```

### What Hooks Do

| Hook | Trigger Event | Action |
|------|---------------|--------|
| `pre-tool.sh` | Before Bash/Write/Edit | Detect Makepad version from Cargo.toml |
| `post-bash.sh` | After Bash command fails | Detect Makepad errors, suggest fixes |
| `session-end.sh` | Session ends | Prompt to capture learnings |

---

## When to Evolve

Trigger skill evolution when any of these occur during development:

| Trigger | Target Skill | Priority |
|---------|--------------|----------|
| New widget pattern discovered | 04-patterns | High |
| Shader technique learned | 03-graphics | High |
| Compilation error solved | 06-reference/troubleshooting | High |
| Layout solution found | 06-reference/adaptive-layout | Medium |
| Build/packaging issue resolved | 05-deployment | Medium |
| New project structure insight | 00-getting-started | Low |
| Core concept clarified | 01-core | Low |

---

## Evolution Process

### Step 1: Identify Knowledge Worth Capturing

Ask yourself:
- Is this a reusable pattern? (not project-specific)
- Did it take significant effort to figure out?
- Would it help other Makepad developers?
- Is it not already documented in makepad-skills?

### Step 2: Classify the Knowledge

```
Widget/Component Pattern     → 04-patterns/
Shader/Visual Effect         → 03-graphics/
Error/Debug Solution         → 06-reference/troubleshooting.md
Layout/Responsive Design     → 06-reference/adaptive-layout.md
Build/Deploy Issue           → 05-deployment/SKILL.md
Project Structure            → 00-getting-started/
Core Concept/API             → 01-core/
```

### Step 3: Format the Contribution

**For Patterns**:
```markdown
## Pattern N: [Pattern Name]

Brief description of what this pattern solves.

### live_design!
```rust
live_design! {
    // DSL code
}
```

### Rust Implementation
```rust
// Rust code
```
```

**For Troubleshooting**:
```markdown
### [Error Type/Message]

**Symptom**: What the developer sees

**Cause**: Why this happens

**Solution**:
```rust
// Fixed code
```
```

### Step 4: Mark Evolution (NOT Version)

Add an evolution marker above new content:

```markdown
<!-- Evolution: 2024-01-15 | source: my-app | author: @zhangsan -->
```

### Step 5: Submit via Git

```bash
# Create branch for your contribution
git checkout -b evolution/add-loading-pattern

# Commit your changes
git add 04-patterns/widget-patterns.md
git commit -m "evolution: add loading state pattern from my-app"

# Push and create PR
git push origin evolution/add-loading-pattern
```

---

## Self-Correction

When skill content causes errors, automatically correct it.

### Trigger Conditions

```
User follows skill advice → Code fails to compile/run → Claude identifies skill was wrong
                                                      ↓
                                         AUTO: Correct skill immediately
```

### Correction Flow

1. **Detect** - Skill advice led to an error
2. **Verify** - Confirm the skill content is wrong
3. **Correct** - Update the skill file with fix

### Correction Marker Format

```markdown
<!-- Correction: YYYY-MM-DD | was: [old advice] | reason: [why it was wrong] -->
```

---

## Self-Validation

Periodically verify skill content is still accurate.

### Validation Checklist

```markdown
## Validation Report

### Code Examples
- [ ] All `live_design!` examples parse correctly
- [ ] All Rust code compiles
- [ ] All patterns work as documented

### API Accuracy
- [ ] Widget names exist in makepad-widgets
- [ ] Method signatures are correct
- [ ] Event types are accurate
```

### Validation Prompt

> "Please validate makepad-skills against current Makepad version"

---

## Version Adaptation

Provide version-specific guidance for different Makepad branches.

### Supported Versions

| Branch | Status | Notes |
|--------|--------|-------|
| main | Stable | Production ready |
| dev | Active | Latest features, may break |
| rik | Legacy | Older API style |

### Version Detection

Claude should detect Makepad version from:

1. **Cargo.toml branch reference**:
   ```toml
   makepad-widgets = { git = "...", branch = "dev" }
   ```

2. **Cargo.lock content**

3. **Ask user if unclear**

---

## Personalization

Adapt skill suggestions to project's coding style.

### Style Detection

Claude analyzes the current project to detect:

| Aspect | Detection Method | Adaptation |
|--------|------------------|------------|
| Naming convention | Scan existing widgets | Match snake_case vs camelCase |
| Code organization | Check module structure | Suggest matching patterns |
| Comment style | Read existing comments | Match documentation style |
| Widget complexity | Count lines per widget | Suggest appropriate patterns |

---

## Quality Guidelines

### DO Add
- Generic, reusable patterns
- Common errors with clear solutions
- Well-tested shader effects
- Platform-specific gotchas
- Performance optimizations

### DON'T Add
- Project-specific code
- Unverified solutions
- Duplicate content
- Incomplete examples
- Personal preferences without rationale

---

## Skill File Locations

```
skills/
├── 00-getting-started/    ← Project setup
├── 01-core/               ← Layout, widgets, events, styling
├── 02-components/         ← Widget gallery
├── 03-graphics/           ← Shaders, SDF, animations
│   ├── _base/             ← Official (DO NOT modify)
│   └── community/         ← Community contributions
├── 04-patterns/           ← Production patterns
│   ├── _base/             ← Official (DO NOT modify)
│   └── community/         ← Community contributions
├── 05-deployment/         ← Build & packaging
├── 06-reference/          ← Troubleshooting, code quality
└── 99-evolution/          ← This file + hooks
    ├── hooks/             ← Auto-trigger hooks
    ├── references/        ← Detailed guides
    └── templates/         ← Contribution templates
```

---

## Auto-Evolution Prompts

Use these prompts to trigger self-evolution:

### After Solving a Problem
> "This solution should be added to makepad-skills for future reference."

### After Creating a Widget
> "This widget pattern is reusable. Let me add it to makepad-patterns."

### After Debugging
> "This error and its fix should be documented in makepad-troubleshooting."

### After Completing a Feature
> "Review what I learned and update makepad-skills if applicable."

---

## Continuous Improvement Checklist

After each Makepad development session, consider:

- [ ] Did I discover a new widget composition pattern?
- [ ] Did I solve a tricky shader problem?
- [ ] Did I encounter and fix a confusing error?
- [ ] Did I find a better way to structure layouts?
- [ ] Did I learn something about packaging/deployment?
- [ ] Would any of this help other Makepad developers?

If yes to any, evolve the appropriate skill!

## References

- [makepad-skills repository](https://github.com/project-robius/makepad-skills)
- [Makepad documentation](https://github.com/makepad/makepad)
- [Project Robius](https://github.com/project-robius)
