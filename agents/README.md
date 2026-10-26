# agents

One place for everything I teach my AI coding tools: instructions, skills and agent configs. It works with Kiro CLI today and with Claude Code, Codex and others when I start using them.

Each tool keeps its own home (`~/.kiro`, `~/.claude`, …) untouched. This folder holds the authored content, and the content is pointed into each tool. Nothing is redirected: no `KIRO_HOME`, no wrapper scripts, no symlinked tool homes. Tools run exactly as installed, from any shell, script or cron job.

## Idea in three lines

1. **Write once, in open formats.** `AGENTS.md` for always-on instructions, [Agent Skills](https://agentskills.io) (`SKILL.md`) for workflows, MCP for live connections.
2. **Point, don't copy.** Each tool gets content through the lightest thing that works: native discovery, then a config reference, then a per-item symlink, then a generated copy.
3. **Shrink over time.** When a tool starts reading these formats natively, its links and adapters get deleted.

## Layout

```
dotfiles/agents/            → linked to ~/.agents
├── AGENTS.md               # global always-on rules. Short, hand-written.
├── skills/<name>/          # one folder per skill
│   ├── SKILL.md            #   name + description (the trigger) + procedure
│   ├── references/         #   long docs, loaded only when needed
│   └── scripts/            #   deterministic helpers
├── targets/<tool>/         # tool-specific glue, only for tools I use
│   └── kiro/
│       ├── target.json     #   how each capability reaches Kiro
│       └── agents/main.json#   Kiro custom agent that references ~/.agents
├── mcp/                    # canonical MCP definitions (later; no secrets ever)
├── bin/agents-sync         # small Python stdlib CLI: check, plan, link, unlink
└── tests/
```

Outside the repo:

| Path | What | In git? |
|---|---|---|
| `~/.agents` | Symlink to `dotfiles/agents` | — |
| `~/.agents.local/` | Machine or work-only skills and rules (same layout) | Never in dotfiles |
| `~/.local/state/agents-sync/` | Manifest of what agents-sync created, plus backups | No |
| `<project>/AGENTS.md`, `<project>/.agents/skills/` | Project rules and skills | Per project (local-only in shared work repos) |
| `~/.kiro`, `~/.claude`, … | Tool homes: auth, sessions, settings | Untouched |

## How content reaches each tool

| Tool | Instructions | Skills |
|---|---|---|
| Kiro CLI | `main` custom agent lists `file://~/.agents/AGENTS.md` (+ overlay, project) | Same agent lists `skill://` for `~/.agents`, the overlay and project `.agents/skills` |
| Claude Code (later) | `~/.claude/CLAUDE.md` stub that imports `~/.agents/AGENTS.md` | Per-skill links in `~/.claude/skills/`, unless native support is verified |
| Codex (later) | Link to its global `AGENTS.md` path | Native if it reads `~/.agents/skills` (to verify) |

Every link or file that `agents-sync` creates is recorded in its manifest. It never overwrites a file it didn't create and only removes what it recorded.

## What goes where

- **Applies to every task** (build commands, hard "never do X" rules) → `AGENTS.md`. Keep it around 50 lines.
- **Repeatable workflow** → a skill. The `description` decides when it triggers, so write it with the words I'd actually type.
- **Big reference material** → that skill's `references/`.
- **Exact, scriptable step** → that skill's `scripts/`.
- **Kiro-only config** (tools, permissions) → `targets/kiro/`.
- **Anything work or confidential** → `~/.agents.local/`, never here.
- **Third-party skills** → copied in with a `PROVENANCE.md`, and reviewed before any script runs.

## Day to day

```bash
nvim ~/.agents/skills/my-skill/SKILL.md   # write or edit a skill
agents-sync check                         # validate frontmatter, names, provenance
agents-sync sync --dry-run                # see what would change
agents-sync sync                          # apply (only needed for linked targets)
kiro-cli                                  # run the tool normally
```

With Kiro's `main` agent, new skills show up without running sync, because the agent references the folders rather than linking each skill.

Commit as usual in the dotfiles repo (`jj`).

## New machine

Ansible installs it as part of dotfiles (`ansible/agents.yml`). The task file:

1. links `~/.agents` → `dotfiles/agents` (and fails if a real `~/.agents` already exists),
2. links `agents-sync` into `~/.local/bin`,
3. runs `agents-sync check` and `agents-sync sync --dry-run`,
4. applies with `sync` only when `agents_sync_apply=true`.

Ansible only places the folder and calls `agents-sync`. It never creates tool links itself, so there is one owner of the manifest and one place where conflicts are detected. No root needed.

```bash
ansible-playbook dotfiles.yml --tags agents                          # plan only
ansible-playbook dotfiles.yml --tags agents -e agents_sync_apply=true
```

On the work VDI, `~/.agents.local/` is provided separately (for example from an internal repo) and is never committed here.

## Never

- Set `KIRO_HOME`, `CLAUDE_CONFIG_DIR` or similar.
- Wrap a CLI in a PATH shim.
- Symlink a whole tool home or a whole `skills/` folder.
- Put secrets or work content in this repo.

Full spec for agents doing migrations: `AGENTS-HOME-SPEC.md`.

