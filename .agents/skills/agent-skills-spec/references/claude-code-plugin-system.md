# Claude Code Plugin System — Distilled Reference

Source: https://github.com/anthropics/claude-code (`plugins/` directory)

---

## Plugin structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # required: manifest
├── commands/                # slash commands (.md files)
├── agents/                  # subagent definitions (.md files)
├── skills/                  # agent skills (subdirs, each with SKILL.md)
│   └── skill-name/
│       └── SKILL.md
├── hooks/
│   └── hooks.json           # event handlers
├── .mcp.json                # MCP server config
└── README.md
```

**Rules:**
- `plugin.json` must be in `.claude-plugin/`, not at root
- `commands/`, `agents/`, `skills/`, `hooks/` must be at plugin root (not inside `.claude-plugin/`)
- All `.md` files in `commands/` and `agents/` are auto-discovered
- All subdirs with `SKILL.md` in `skills/` are auto-discovered

---

## plugin.json (manifest)

Minimal:
```json
{ "name": "my-plugin" }
```

Full:
```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What it does",
  "author": { "name": "Oskar Jansson", "email": "hello@oskarjansson.com" },
  "license": "MIT"
}
```

Custom paths are additive (supplement, don't replace auto-discovery):
```json
{
  "name": "my-plugin",
  "commands": "./custom-commands",
  "hooks": "./config/hooks.json"
}
```

---

## Commands (slash commands)

Files in `commands/*.md`. Invoked by user as `/command-name`.

**Critical:** Commands are instructions FOR Claude, not messages to the user.

```markdown
---
description: Commit, push, and open a PR     # shown in /help
allowed-tools: Bash(git add:*), Bash(gh pr create:*)
argument-hint: [pr-number] [priority]
model: haiku                                 # inherit | sonnet | opus | haiku
---

## Context
- Current status: !`git status`
- Diff: !`git diff HEAD`

Based on the above, create a commit, push, and open a PR.
```

**Dynamic content:**
- `$ARGUMENTS` — everything the user typed after the command name
- `$1`, `$2`, ... — positional args
- `@path/to/file` — includes file contents
- `` !`bash command` `` — executes and inlines output before Claude sees the prompt
- `${CLAUDE_PLUGIN_ROOT}` — plugin's install dir (use for portability)

**Personal commands** (all projects): `~/.claude/commands/`  
**Project commands** (this project): `.claude/commands/`  
**Plugin commands**: `plugin-name/commands/`

---

## Agents (subagents)

Files in `agents/*.md`. Claude spawns them autonomously or via Agent tool.

```markdown
---
name: code-reviewer
description: Use this agent when reviewing code for bugs. Examples:

<example>
Context: User has just written a feature branch
user: "review my changes"
assistant: "I'll spawn the code-reviewer agent to analyze your diff"
<commentary>
Code review tasks should use the specialized agent, not inline Claude
</commentary>
</example>

model: inherit        # inherit | sonnet | opus | haiku
color: red            # blue | cyan | green | yellow | magenta | red
tools: ["Read", "Grep", "Glob"]   # omit for all tools
---

You are an expert code reviewer specializing in...

**Your Core Responsibilities:**
1. ...

**Process:**
1. ...

**Output Format:**
...
```

**Description is the trigger** — same principle as skill descriptions. Include 2-4 `<example>` blocks with `<commentary>` explaining why the agent should fire.

**Colors by convention:**
- blue/cyan: analysis, review
- green: success-oriented
- yellow: validation, caution
- red: critical, security
- magenta: creative, generation

**Tool restriction** (least privilege): `["Read", "Grep", "Glob"]` for read-only, omit for full access.

---

## Hooks

Event handlers that run on Claude Code events. Two types:

**Prompt-based** (recommended for complex logic — uses an LLM):
```json
{ "type": "prompt", "prompt": "Check if this tool call is safe. Return approve or deny.", "timeout": 30 }
```

**Command-based** (deterministic, fast):
```json
{ "type": "command", "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/validate.sh", "timeout": 10 }
```

### Hook events

| Event | When | Typical use |
|-------|------|-------------|
| `PreToolUse` | Before tool runs | Validate, approve, deny, modify |
| `PostToolUse` | After tool completes | Feedback, logging |
| `UserPromptSubmit` | User submits prompt | Add context, validate |
| `Stop` | Agent about to stop | Verify completion |
| `SubagentStop` | Subagent about to stop | Verify subagent task done |
| `SessionStart` | Session begins | Load context, set env vars |
| `SessionEnd` | Session ends | Cleanup, logging |
| `PreCompact` | Before context compaction | Preserve critical info |
| `Notification` | Claude sends notification | React to notifications |

### Hooks run in parallel — don't rely on ordering.

### Two config formats

**Plugin `hooks/hooks.json`** — use `hooks` wrapper:
```json
{
  "description": "optional",
  "hooks": {
    "PreToolUse": [{ "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "..." }] }]
  }
}
```

**User `settings.json`** — direct format, no wrapper:
```json
{
  "PreToolUse": [{ "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "..." }] }]
}
```

### Matchers

```json
"matcher": "Write"           // exact tool name
"matcher": "Write|Edit"      // multiple tools
"matcher": "*"               // all tools
"matcher": "mcp__.*"         // all MCP tools (regex)
"matcher": "Bash"            // bash only
```

### Hook I/O

Hooks receive JSON via stdin:
```json
{
  "session_id": "...", "cwd": "...", "hook_event_name": "PreToolUse",
  "tool_name": "Write", "tool_input": { "file_path": "..." }
}
```

Output for PreToolUse:
```json
{
  "hookSpecificOutput": { "permissionDecision": "allow|deny|ask" },
  "systemMessage": "Explanation for Claude"
}
```

Output for Stop:
```json
{ "decision": "approve|block", "reason": "...", "systemMessage": "..." }
```

Exit codes: `0` = success (stdout to transcript), `2` = blocking error (stderr fed to Claude).

**SessionStart special:** write env vars to `$CLAUDE_ENV_FILE` to persist them across the session.

### `${CLAUDE_PLUGIN_ROOT}`

Always use this in hook commands and MCP configs — never hardcode paths.

```bash
#!/bin/bash
source "${CLAUDE_PLUGIN_ROOT}/lib/common.sh"
```

---

## Skills (SKILL.md)

Same agentskills format as the open standard. See `agentskills-spec.md`.

In plugin context, skills live in `skills/<skill-name>/SKILL.md`.

Skills auto-activate based on description — the agent loads them progressively (name+description upfront, body on activation, references/scripts on demand).

---

## Notable plugin examples

| Plugin | What to steal |
|--------|--------------|
| `commit-commands` | Minimal real-world command with `!` bash inline |
| `feature-dev` | Multi-agent workflow: explorer + architect + reviewer |
| `pr-review-toolkit` | 6 parallel specialized review agents |
| `hookify` | All 4 hook types, Python hook scripts, rule-file pattern |
| `security-guidance` | Python-based PreToolUse with 9 security patterns |
| `ralph-wiggum` | Stop hook to intercept completion and loop |
| `plugin-dev` | 7 skills covering every plugin component — read these |

---

## Personal commands vs plugins

For personal reusable commands that don't need packaging:
- Put `.md` files in `~/.claude/commands/` — available globally, no plugin overhead
- For this workspace, `~/.ai/skills/` holds skills, symlink or copy as needed

---

## Key source files

| File | What it covers |
|------|---------------|
| `plugins/README.md` | Plugin catalog |
| `plugins/plugin-dev/skills/plugin-structure/SKILL.md` | Full structure spec |
| `plugins/plugin-dev/skills/agent-development/SKILL.md` | Agent format + best practices |
| `plugins/plugin-dev/skills/hook-development/SKILL.md` | Hook system deep dive |
| `plugins/plugin-dev/skills/command-development/SKILL.md` | Command format + patterns |
| `plugins/plugin-dev/skills/hook-development/examples/` | Working hook scripts |
| `plugins/feature-dev/agents/` | Real agent examples |
| `.claude/commands/commit-push-pr.md` | Real command with inline bash |
