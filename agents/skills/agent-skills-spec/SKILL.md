---
name: agent-skills-spec
type: reference
description: >
  Reference: the Agent Skills specification (agentskills.io): SKILL.md layout, front matter fields, scripts/references/assets folders. Use when writing, validating or reviewing a skill's structure.
---

# Agent Skills Spec Reference

Source: https://agentskills.io/docs/specification

## Directory structure

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources
└── ...               # Any additional files or directories
```

## Frontmatter fields

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | Max 64 chars. Lowercase `[a-z0-9-]`. No leading/trailing/consecutive hyphens. Must match parent directory name. |
| `description` | Yes | Max 1024 chars. Non-empty. What it does + when to use it. |
| `license` | No | License name or reference to bundled file. |
| `compatibility` | No | Max 500 chars. Environment requirements. |
| `metadata` | No | Arbitrary key-value map (string keys, string values). |
| `allowed-tools` | No | Space-separated tool names. Experimental. |

## Name validation rules

- 1-64 characters
- Lowercase alphanumeric + hyphens only
- No leading/trailing hyphen
- No consecutive hyphens (`--`)
- Must match parent directory name

## Progressive disclosure (token budgets)

| Level | What | Budget |
|-------|------|--------|
| Metadata | `name` + `description` | ~100 tokens (loaded at startup for ALL skills) |
| Instructions | Full SKILL.md body | < 5000 tokens recommended (< 500 lines) |
| Resources | scripts/, references/, assets/ | Loaded on demand only |

## File references

- Use relative paths from skill root
- Keep references one level deep from SKILL.md
- No deeply nested reference chains

## Key rules

- Body under 500 lines. Move detailed reference material to separate files.
- Description determines activation. Include specific keywords matching how users phrase requests.
- Scripts should be self-contained, include error messages, handle edge cases.
- Keep individual reference files focused. Smaller files = less context usage.

## Validation tool

The `skills-ref` reference library validates SKILL.md files programmatically:

```bash
pip install skills-ref
skills-ref validate ./my-skill
```

Checks: name format, description length, directory name match, allowed frontmatter fields.
Source: https://github.com/agentskills/agentskills/tree/main/skills-ref
