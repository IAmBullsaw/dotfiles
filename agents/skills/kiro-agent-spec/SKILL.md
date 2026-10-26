---
name: kiro-agent-spec
type: reference
description: >
  Reference: Kiro CLI agent spec distilled from the official docs: built-in tool names and aliases, resources, hooks, steering. Use as ground truth when auditing agent configs, skills or hooks.
---

# Kiro CLI Agent Spec Reference

Distilled from official docs at https://kiro.dev/docs/cli/. Use this as ground truth
when auditing agent configs, skills, hooks, and steering files.

Source docs in `~/.kiro/references/kiro-docs/`.

---

## Built-in tool names and aliases

The canonical name is the first column. All aliases are valid in `tools`, `allowedTools`,
`toolsSettings`, and hook `matcher` fields.

| Canonical name | Aliases | Description |
|---|---|---|
| `read` | `fs_read`, `fsRead` | Read files, directories, images |
| `write` | `fs_write`, `fsWrite` | Create and edit files |
| `shell` | `execute_bash`, `execute_cmd` | Execute bash commands |
| `glob` | — | Find files by glob pattern |
| `grep` | — | Regex search in files |
| `code` | — | LSP-powered code intelligence |
| `aws` | `use_aws` | Execute AWS CLI commands |
| `subagent` | `use_subagent` | Spawn sub-agents |
| `knowledge` | — | Search knowledge bases (experimental) |
| `thinking` | — | Extended reasoning (experimental) |
| `todo` | `todo_list` | Task list management (experimental) |
| `introspect` | — | Query Kiro CLI documentation |
| `report` | — | Submit issues/feature requests |
| `web` | — | Web search and fetch |

**Key implication for auditing:** `read`/`write`/`shell` and `fs_read`/`fs_write`/`execute_bash`
are equally valid. Mixing them across agents is a style inconsistency, not a bug.
The default agent uses `fs_read`/`fs_write`/`execute_bash`; newer agents use `read`/`write`/`shell`.
Both work.

---

## toolsSettings — valid keys and options

The key in `toolsSettings` must match the tool's canonical name or alias.
Both `"write"` and `"fs_write"` work as keys.

### read / fs_read
```json
"read": {
  "allowedPaths": ["src/**", "docs/**"]
}
```

### write / fs_write
```json
"write": {
  "allowedPaths": ["src/**", "tests/**", "~/.kiro/**"]
}
```

### shell / execute_bash
```json
"shell": {
  "allowedCommands": ["git status", "npm test"],
  "deniedCommands": ["git push .*", "rm -rf .*"],
  "autoAllowReadonly": true
}
```

### aws / use_aws
```json
"aws": {
  "allowedServices": ["s3", "lambda"],
  "autoAllowReadonly": true
}
```

---

## Agent config fields

All fields are optional except the file must be valid JSON.

| Field | Type | Notes |
|---|---|---|
| `name` | string | Display name. Derived from filename if omitted. |
| `description` | string | Human-readable purpose. |
| `prompt` | string or `"file://./path.md"` | System prompt. Supports file:// URIs. |
| `model` | string | e.g. `"claude-sonnet-4"`. Falls back to default if omitted or unavailable. |
| `tools` | array | Tools available to the agent. Use `"*"` for all, `"@builtin"` for all built-ins. |
| `allowedTools` | array | Tools auto-approved without prompting. Supports wildcards (`"read_*"`, `"@server/*"`). Does NOT support `"*"` wildcard. |
| `toolsSettings` | object | Per-tool configuration. Key = tool name or alias. |
| `resources` | array | Files/skills/knowledge bases loaded at startup. |
| `mcpServers` | object | MCP server definitions. |
| `hooks` | object | Commands at lifecycle trigger points. |
| `includeMcpJson` | boolean | Whether to include MCP servers from mcp.json files. Set explicitly on every agent. Default: false. |
| `toolAliases` | object | Remap tool names (for MCP collision resolution). |
| `keyboardShortcut` | string | e.g. `"ctrl+a"`. Toggle behavior: press again to switch back. |
| `welcomeMessage` | string | Shown when switching to this agent. |

---

## Resources — URI schemes

```json
"resources": [
  "file://README.md",                          // loaded into context at startup
  "file://.kiro/steering/**/*.md",             // glob, all loaded at startup
  "skill://.kiro/skills/**/SKILL.md",          // metadata only at startup, full content on demand
  {
    "type": "knowledgeBase",
    "source": "file://./docs",
    "name": "ProjectDocs",
    "indexType": "best",
    "autoUpdate": false
  }
]
```

**Key difference:** `file://` = always in context (costs tokens). `skill://` = metadata only
until the agent decides it needs the full content. Use `skill://` for large reference docs
the agent may not always need.

---

## Hooks — trigger types and matcher names

Hook matchers use the **internal tool name** (canonical or alias — both work).

| Trigger | When it fires | Can block? |
|---|---|---|
| `agentSpawn` | Agent activated | No |
| `userPromptSubmit` | User submits a message | No (output added to context) |
| `preToolUse` | Before tool execution | Yes (exit 2 blocks) |
| `postToolUse` | After tool execution | No |
| `stop` | End of each agent turn | No |

**Exit code behavior:**
- Exit 0: success, stdout added to context (agentSpawn/userPromptSubmit) or ignored (pre/postToolUse)
- Exit 2: block tool (preToolUse only)
- Other: warning shown to user, execution continues

**Matcher examples:**
```json
"matcher": "fs_write"      // exact match (canonical name)
"matcher": "write"         // alias — also works
"matcher": "fs_*"          // wildcard
"matcher": "@git/status"   // MCP tool
"matcher": "*"             // all tools
```

---

## Skills — SKILL.md format

Skills use YAML frontmatter + markdown body.

```markdown
---
name: my-skill           # kebab-case, matches folder name
description: >           # trigger phrases go here — this is the ONLY matching mechanism
  Use when: "$trigger", "natural phrase", "another phrase".
  Not for: competing skill (use other-skill).
---
# Skill Title
...body...
```

**Loading:** Only `name` and `description` are loaded at startup (via `skill://` resource).
Full body loaded on demand when agent decides it's needed.

**File location:** `~/.kiro/skills/<name>/SKILL.md` (global) or `.kiro/skills/<name>/SKILL.md` (local).
Local takes precedence over global.

---

## Steering files

Markdown files that auto-load as context. Two types:

| Type | Path | Loads for |
|---|---|---|
| Global | `~/.kiro/steering/*.md` | Default agent only (NOT custom agents) |
| Workspace | `.kiro/steering/*.md` | All agents in that workspace |

**Key quirk:** Global steering files (`~/.kiro/steering/`) do NOT auto-load for custom agents.
Custom agents must explicitly list resources they need. This is intentional — custom agents
get explicit control, not implicit inheritance.

---

## Known quirks and gotchas

1. **`allowedTools` does not support `"*"` wildcard.** Use `"@builtin"` for all built-ins or list tools explicitly.

2. **`toolsSettings` key can be canonical name or alias.** Both `"write"` and `"fs_write"` work. Pick one convention and stick to it.

3. **`includeMcpJson` is the only valid field name.** `useLegacyMcpJson` is not a recognized field — it is silently ignored. Always use `includeMcpJson`.

4. **`model: null` means auto-selection.** May pick a weaker model. Pin explicitly with `"model": "claude-sonnet-4"` for agents with complex prompts.

5. **Local agents take precedence over global.** Same name in `.kiro/agents/` overrides `~/.kiro/agents/` with a warning.

6. **`skill://` glob patterns load metadata only.** The agent reads the description to decide if it needs the full content. Write descriptions that make this decision obvious.

7. **Hook matchers use internal names but aliases work too.** `"matcher": "write"` and `"matcher": "fs_write"` both match the write tool.

8. **`preToolUse` exit 2 blocks the tool and returns stderr to the LLM.** The LLM sees the error message and can decide what to do. Exit 0 allows. Any other exit shows a warning but allows.

9. **Hooks time out at 10 seconds by default.** Configure with `timeout_ms`. Hooks that hang silently fail after timeout.

10. **`agentSpawn` hooks are never cached** regardless of `cache_ttl_seconds`.

11. **`keyboardShortcut` conflicts are silently disabled.** If two agents share a shortcut, both shortcuts stop working. No error is shown.

12. **`prompt` field supports `file://` URIs.** Relative paths resolve from the agent config file's directory. Useful for keeping long prompts in separate `.md` files.
