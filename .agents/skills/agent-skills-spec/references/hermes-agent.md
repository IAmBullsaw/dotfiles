# Hermes Agent — Distilled Reference

Source: https://github.com/NousResearch/hermes-agent  
The self-improving AI agent from Nous Research. Python, MIT, ~12k LOC core.

---

## What it is

A full-stack, self-hosted AI agent with:
- Provider-agnostic inference (200+ models via OpenRouter, Anthropic, OpenAI, Bedrock, Vertex, NIM, etc.)
- Full TUI (Ink/React frontend + Python backend, JSON-RPC over stdio)
- Messaging gateway (Telegram, Discord, Slack, WhatsApp, Signal, Email, etc.)
- Skill system (agentskills.io compatible)
- Pluggable memory backends (Honcho, mem0, supermemory, retaindb, etc.)
- Built-in cron scheduler, delegation/subagents, Kanban multi-agent board
- **Closed learning loop**: agent auto-creates skills from experience; Curator maintains them

---

## Architecture

```
tools/registry.py          # no deps — imported by all tool files
      ↑
tools/*.py                 # each calls registry.register() at import time (auto-discovery)
      ↑
model_tools.py             # imports tools/registry, triggers tool discovery
      ↑
run_agent.py  cli.py  batch_runner.py  environments/
```

Key source files:
- `run_agent.py` — `AIAgent` class, core conversation loop (~12k LOC)
- `model_tools.py` — tool orchestration, `discover_builtin_tools()`, `handle_function_call()`
- `toolsets.py` — toolset definitions, `_HERMES_CORE_TOOLS` default bundle
- `cli.py` — `HermesCLI` class, interactive CLI (~11k LOC)
- `hermes_state.py` — `SessionDB`, SQLite session store with FTS5 search
- `agent/curator.py` — background skill lifecycle manager
- `agent/memory_manager.py` — memory provider orchestrator

---

## Agent loop

Entirely synchronous, with interrupt checks and budget tracking:

```python
while (api_call_count < self.max_iterations and self.iteration_budget.remaining > 0) \
        or self._budget_grace_call:
    if self._interrupt_requested: break
    response = client.chat.completions.create(model=model, messages=messages, tools=tool_schemas)
    if response.tool_calls:
        for tool_call in response.tool_calls:
            result = handle_function_call(tool_call.name, tool_call.args, task_id)
            messages.append(tool_result_message(result))
        api_call_count += 1
    else:
        return response.content
```

Messages use OpenAI format. Reasoning content stored in `assistant_msg["reasoning"]`.

---

## Tool system

Auto-discovery: any `tools/*.py` with `registry.register()` at module level is imported automatically — no manual import list.

```python
from tools.registry import registry

registry.register(
    name="example_tool",
    toolset="example",
    schema={"name": "example_tool", "description": "...", "parameters": {...}},
    handler=lambda args, **kw: example_tool(param=args.get("param", ""), task_id=kw.get("task_id")),
    check_fn=check_requirements,       # availability check
    requires_env=["EXAMPLE_API_KEY"],
)
```

All handlers MUST return a JSON string.

**Toolsets** are named bundles. A tool is only exposed to an agent if its name appears in a toolset. `_HERMES_CORE_TOOLS` is the default bundle. Tools not in any toolset are registered but invisible to the model.

**For custom/local tools**: use `~/.hermes/plugins/<name>/plugin.yaml` + `__init__.py`, not core edits. Plugin tools are auto-discovered and can be enabled/disabled.

---

## Plugin system

Two surfaces:

### General plugins

`~/.hermes/plugins/<name>/` or pip entry points. Each exposes `register(ctx)`:

```python
def register(ctx):
    ctx.register_tool(...)                        # add tools
    ctx.register_cli_command(...)                 # add `hermes <pluginname> <subcmd>`
    ctx.hook("pre_tool_call", my_validator)       # hook: pre/post_tool_call, pre/post_llm_call,
                                                  #       on_session_start, on_session_end
```

**Rule**: plugins MUST NOT modify core files. If you need a new capability, expand the plugin surface.

### Memory-provider plugins

Implement `MemoryProvider` ABC (`agent/memory_provider.py`). Lifecycle:
- `sync_turn(turn_messages)` — called post-turn
- `prefetch(query)` — called pre-turn
- `shutdown()`
- `post_setup(hermes_home, config)` — setup wizard integration

Only ONE external memory provider active at a time (prevents tool bloat and conflicting backends). Memory context injected into system prompt as `<memory-context>...</memory-context>` block.

### Model-provider plugins

`plugins/model-providers/<name>/` — each calls `providers.register_provider(ProviderProfile(...))`. Last-writer-wins: user plugin overrides bundled one of same name.

---

## Delegation (subagents)

`tools/delegate_tool.py` spawns isolated subagents:

```python
# Single subagent
delegate_task(goal="...", context="...", toolsets=["file", "search"])

# Parallel batch — each task gets its own subagent
delegate_task(tasks=[{"goal": "...", "context": "..."}, ...])
```

**Roles:**
- `role="leaf"` (default) — focused worker. Cannot call `delegate_task`, `clarify`, `memory`, `send_message`, `execute_code`
- `role="orchestrator"` — retains `delegate_task`, can spawn workers. Gated by config, bounded by `max_spawn_depth` (default 2)

**Key invariant:** `delegate_task` is synchronous — parent waits. For long-running work that must outlive the current turn, use `cronjob` or `terminal(background=True, notify_on_complete=True)` instead.

Config knobs: `max_concurrent_children` (default 3), `max_spawn_depth`, `child_timeout_seconds`, `subagent_auto_approve`.

---

## Curator (skill lifecycle)

Background agent that maintains agent-created skills. Never deletes — only archives to `~/.hermes/skills/.archive/`.

```
agent/curator.py          # review loop, auto-transitions, LLM review prompt
agent/curator_backup.py   # pre-run tar.gz snapshots
tools/skill_usage.py      # sidecar .usage.json — use_count, view_count, patch_count, state, pinned
```

Lifecycle states: `active` → `stale` (after `stale_after_days`) → `archived` (after `archive_after_days`).

**Invariants:**
- Only touches `created_by: "agent"` skills — bundled/hub-installed are off-limits
- Pinned skills are exempt from all auto-transitions and LLM review pass
- Uses auxiliary client — never touches main session's prompt cache

Config (`curator:` in config.yaml): `enabled`, `interval_hours`, `min_idle_hours`, `stale_after_days`, `archive_after_days`.

---

## Skill authoring standards (hardline)

These are enforced on all skill PRs:

1. **`description` ≤ 60 characters, one sentence, ends with period.** No marketing words. Don't repeat skill name.
2. **Use native Hermes tool names in prose** — `search_files` not `grep`, `read_file` not `cat/head/tail`, `patch` not `sed/awk`.
3. **`platforms:` gating audited** — fix cross-platform first, gate only when genuinely platform-bound.
4. **`author` credits the human contributor first**.
5. **Section order**: title → 2-3 sentence intro → `## When to Use` → `## Prerequisites` → `## How to Run` → `## Quick Reference` → `## Procedure` → `## Pitfalls` → `## Verification`. Target ~200 lines for complex, ~100 for simple.
6. **Scripts in `scripts/`, references in `references/`, templates in `templates/`**.
7. **Tests at `tests/skills/test_<skill>_skill.py`**, stdlib + pytest + unittest.mock only, no live network calls.

SKILL.md frontmatter extra fields beyond agentskills standard:
```yaml
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [github, pr, review]
    category: development
    related_skills: [github-auth]
    config: { key: "skills.config.mykey" }  # prompted during setup, injected at load
```

---

## Prompt caching invariant

**Never alter past context mid-conversation.** Cache-breaking forces dramatically higher costs. The ONLY time context is altered is during explicit context compression.

Slash commands that mutate system-prompt state (skills, tools, memory) must:
- Default to **deferred invalidation** (change takes effect next session)
- Offer `--now` flag for immediate invalidation

This is why skill commands inject as **user message** (not system prompt) — to preserve prompt caching.

---

## Cron scheduler

Natural language scheduling:
```python
# All supported formats:
"30m"            # duration
"2h"
"every 2h"       # "every" phrase
"every monday 9am"
"0 9 * * *"      # 5-field cron expression
"2026-06-01T09:00:00Z"  # ISO one-shot
```

Per-job: `skills` (load specific skills), `model`/`provider` overrides, `script` (pre-run data-collection script injected into prompt), `context_from` (chain output from job A into job B), `workdir`.

**Hardening:** 3-minute hard interrupt on cron sessions. Cron sessions pass `skip_memory=True` by default.

---

## TUI architecture

```
hermes --tui
  └─ Node (Ink/React)  ──stdio JSON-RPC──  Python (tui_gateway)
       │                                        └─ AIAgent + tools + sessions
       └─ renders transcript, composer, prompts, tool activity
```

TypeScript owns the screen. Python owns sessions, tools, model calls, and slash command logic.

The dashboard (`hermes dashboard`) embeds real `hermes --tui` via PTY bridge — not a React rewrite. Extend Ink, not the dashboard React, for new chat features.

---

## Key patterns to steal

### Tool registry with auto-discovery
`registry.register()` at module level — import the module = tool is registered. No manual import lists. Toolsets as deliberate named bundles that control what's exposed to the model.

### Plugin hooks as extension points
`pre_tool_call`, `post_tool_call`, `pre_llm_call`, `post_llm_call`, `on_session_start`, `on_session_end` — clean extension without touching core.

### Leaf vs orchestrator delegation
Worker agents (leaf role) cannot spawn children. Orchestrators can, up to `max_spawn_depth`. Concurrency cap via `max_concurrent_children`. Clean containment.

### Skill curator pattern
Background auxiliary-model agent reviews agent-created skills on a schedule. Archives (never deletes) stale ones. Tracks usage per skill. Respects pinned status. Uses its own auxiliary client, never the main session's cache.

### Profile-aware paths
`get_hermes_home()` not `~/.hermes`. Enables fully isolated multi-instance deploys. All state files, config, and logs scope to the active profile automatically.

### Skill commands as user messages
Skills invoked via slash command are injected as user messages, not system prompt insertions. Preserves prompt caching across the entire conversation.

---

## Kanban (multi-agent work queue)

SQLite-backed board. Workers claim and complete tasks via `kanban_*` toolset. Dispatcher loop reclaims stale claims, spawns assigned profiles.

- **Board** = hard isolation boundary; workers pinned to their board via `HERMES_KANBAN_BOARD`
- **Tenant** = soft namespace within a board (workspace-path + memory-key isolation)
- Auto-blocks tasks after `failure_limit` consecutive failures (default 2) — prevents spin loops

---

## Standout source files

| File | Why read it |
|------|------------|
| `AGENTS.md` | Authoritative arch doc for AI coding assistants — great AGENTS.md template |
| `run_agent.py` | The conversation loop, budget, interrupts (~12k LOC) |
| `model_tools.py` | Tool discovery, dispatch, handle_function_call |
| `agent/curator.py` | Skill lifecycle background agent pattern |
| `agent/memory_manager.py` | Memory provider orchestration, context fencing |
| `tools/delegate_tool.py` | Leaf/orchestrator delegation, concurrency |
| `hermes_cli/commands.py` | Central command registry — single source for CLI, gateway, Telegram, Slack, autocomplete |
| `hermes_cli/skin_engine.py` | Data-driven theming — pure YAML skins |
