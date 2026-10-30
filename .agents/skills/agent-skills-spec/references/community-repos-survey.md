# Community AI Repos Survey — Distilled Reference

Cloned at: `/home/bullen/projects/ai-repos/`  
Date: 2026-06-03

---

## awesome-claude-skills (ComposioHQ)
**What it is:** 1000+ production-ready Claude skills across 10+ categories — document processing, dev tools, data analysis, business, security, media, productivity.  
**Signal:** High

- SKILL.md frontmatter includes `when_to_use`, `arguments`, `model`, `effort`, `disallowed-tools` beyond the base agentskills spec
- Connect plugin bridges Claude to 500+ external apps (Slack, GitHub, email, etc.)
- `skill-creator/SKILL.md` is a meta-skill for generating new skills — worth reading

**Standout files:** `skill-creator/SKILL.md`, `template-skill/`, `connect-apps/`

---

## claude-howto (luongnv89)
**What it is:** 10-module tutorial (11-13 hours) teaching Claude Code via visual diagrams, copy-paste configs, and guided learning path.  
**Signal:** Medium — curriculum design, not novel patterns

- Mermaid diagrams explaining internal mechanics
- `06-hooks/` has production hook scripts: context tracking, security scanning, pre-commit
- `LEARNING-ROADMAP.md` is a good reference for feature sequencing

**Standout files:** `06-hooks/*.sh`, `LEARNING-ROADMAP.md`

---

## claude-code-best-practice (shanraisshan)
**What it is:** Best practice guide covering all Claude Code features with implementation examples and orchestration workflows.  
**Signal:** High

- Documents 16 SKILL.md frontmatter fields with examples — most complete reference found
- Orchestration workflow: command → agent → skill (reproducible, documented)
- Memory patterns: CLAUDE.md + `.claude/rules/` + auto-memory
- `reports/` has deep dives on agent memory, advanced tool use, mono-repo skills
- Tips attributed to Boris Cherny and community (timestamped, verifiable)

**Standout files:** `best-practice/claude-skills.md`, `orchestration-workflow/`, `best-practice/claude-memory.md`, `reports/`

---

## AutoGPT (Significant-Gravitas)
**What it is:** Platform for building, deploying, and monitoring continuous AI agents via block-based DAG workflows.  
**Signal:** Medium — large repo, useful for multi-agent architecture patterns

- Block-based design: each block = single action; blocks compose into DAGs
- Agent lifecycle: build → configure → test → deploy → monitor
- Has `.claude/settings.json` at project root — real-world Claude Code config in a major project
- `AGENTS.md` contribution guide — clean template for agent contribution docs

**Standout files:** `AGENTS.md`, `autogpt_platform/`, `.claude/settings.json`

---

## ECC (affaan-m)
**What it is:** Cross-harness operator system (works on Codex, Claude Code, Cursor, OpenCode, Gemini, Zed) — 10+ months of production-evolved skills, hooks, rules, MCP configs.  
**Signal:** High — real-world, multi-harness, battle-tested

Key patterns:
- **Cross-harness alignment**: same SKILL.md/agent/hook interfaces work on 6+ platforms
- **Token optimization**: model selection per task, system prompt slimming, background processes
- **Memory persistence**: hooks serialize/deserialize context across sessions automatically
- **Verification loops**: checkpoint evals vs continuous evals, grader patterns
- **Parallelization**: git worktrees + cascade method for parallel workstreams
- **Security**: attack vectors, sandboxing, sanitization; references AgentShield npm package

**Standout files:** `the-shorthand-guide.md`, `the-longform-guide.md`, `the-security-guide.md`, `RULES.md`

---

## awesome-claude-code-subagents (VoltAgent)
**What it is:** 154+ Claude Code subagents across 10 categories — core dev, language specialists, infra, quality/security, data/AI, DX, domains, business, orchestration, research.  
**Signal:** High — largest curated subagent collection

- Subagent YAML frontmatter: `name`, `description`, `tools` (Read/Write/Edit/Bash/Glob/Grep), behavioral instructions
- Tool assignment by role: read-only for reviewers, write for developers, research-focused for analysts
- Category `09-meta-orchestration/` has agent-to-agent delegation patterns
- `install-agents.sh` interactive installer — pattern for distributing agent collections

**Standout files:** `CLAUDE.md` (format spec), `categories/01-core-development/`, `categories/09-meta-orchestration/`, `install-agents.sh`

---

## SuperClaude_Framework (SuperClaude-Org)
**What it is:** Meta-programming configuration framework turning Claude Code into a structured dev platform — 30 slash commands, 20+ agents, 7 behavioral modes, 8 MCP servers.  
**Signal:** High — most complete framework design found

- 30 `/sc:*` commands covering full dev lifecycle (brainstorm → deploy)
- Command reference has visual decision trees showing when to use which command
- 7 behavioral modes (research, quality, performance, security, etc.) change how the agent approaches work
- `PLANNING.md` + `TASK.md` + `KNOWLEDGE.md` as agent context files — structured project memory
- `KNOWLEDGE.md` is accumulated troubleshooting patterns — self-improving docs

**Standout files:** `docs/user-guide/commands.md`, `PLANNING.md`, `KNOWLEDGE.md`

---

## claude-code-templates (davila7)
**What it is:** 100+ ready-to-use configs for agents, commands, settings, hooks, MCPs, and project templates. Web dashboard at aitmpl.com.  
**Signal:** Medium — packaging patterns, analytics integration

- Installation via `npx claude-code-templates` — interactive installer pattern
- Analytics dashboard for monitoring Claude Code sessions in real-time
- Conversation monitor with mobile UI + Cloudflare Tunnel support
- Health check tool for diagnosing Claude Code installation issues

**Standout files:** `api/` (tracking backend), `scripts/` (template generation, analytics)

---

## claude-skills (alirezarezvani)
**What it is:** 338 skills + 51 agents + 87 commands across 13 AI tools — engineering, DevOps, security, compliance, C-level personas. Cross-platform: Claude Code, Codex, Gemini, Cursor, Hermes.  
**Signal:** High — most comprehensive multi-platform skill collection

Key patterns:
- `SKILL-AUTHORING-STANDARD.md` — standardized creation guide worth reading
- `SKILL_PIPELINE.md` — validation and publishing workflow
- **Persona pattern**: C-level roles (CFO, CTO, CISO, CMO) as agents that provide domain-expert perspective. Agent defines the lens, skills execute the work.
- **Orchestration model**: skills execute tasks → agents choose tasks → personas define perspective
- **Tools in skills**: Python stdlib-only scripts (no pip) — self-contained, no dep management
- Works natively on 13 different harnesses — proves the agentskills format generalizes

**Standout files:** `SKILL-AUTHORING-STANDARD.md`, `SKILL_PIPELINE.md`, `orchestration/ORCHESTRATION.md`, `c-level-advisor/`

---

## claude-code-router (musistudio)
**What it is:** Request routing middleware for Claude Code — routes to different providers/models based on rules (fast model for background, thinking model for analysis).  
**Signal:** Medium — useful if you care about model routing

- Provider abstraction: OpenRouter, DeepSeek, Ollama, Gemini, Volcengine, SiliconFlow
- Request/response transformers per provider
- Dynamic model switching via CLI or `/model` command
- Non-interactive mode for CI/CD (GitHub Actions, Docker)
- `config.example.json` is a comprehensive routing configuration reference

**Standout files:** `examples/`, `config.example.json`

---

## oh-my-claudecode (Yeachan-Heo)
**What it is:** Multi-agent orchestration framework — 154+ subagents + orchestration skills (autopilot, ralph, ultrawork) + CLI (`omc`).  
**Signal:** High — clean orchestration patterns

Two surfaces:
- Terminal CLI (`omc ...`) — manage agents, plugins, skills outside Claude Code
- In-session skills (`/...`) — natural-language task breakdown and delegation

Key patterns:
- **Autopilot skill**: takes a natural-language goal, breaks it down, delegates to specialist subagents
- **Ralph pattern**: iterative self-improvement loop (same as cwc-long-running-agents ralph-wiggum)
- **OMC plugin marketplace**: per-category plugins installed independently (voltagent-lang, voltagent-infra)
- `examples/` has TypeScript delegation patterns and `hooks.json` configs

**Standout files:** `agents/`, `examples/`, `AGENTS.md`, `docs/REFERENCE.md`

---

## Cross-repo patterns that converge

### Frontmatter is converging on a standard
All repos use similar YAML regardless of platform. Beyond the agentskills base (`name`, `description`):
- `tools: [Read, Write, Edit, Bash, Grep, Glob]` — tool restriction per role
- `model: inherit | haiku | sonnet | opus` — per-agent model selection
- `effort: low | medium | high` — maps to thinking budget
- `context: fork` — run in isolated context (subagent)
- `platforms: [linux, macos, windows]` — OS gating

### Orchestration pattern (command → agent → skill)
Appears in: `claude-code-best-practice`, `oh-my-claudecode`, `SuperClaude_Framework`, `claude-skills`

```
user prompt
    ↓
slash command  (routes work, sets context)
    ↓
agent          (decides approach, delegates)
    ↓
skill          (executes specific procedure)
```

### Persona pattern (C-suite lens)
From `claude-skills`. A persona is an agent that defines *how* to think about a problem (CFO = cost-risk lens, CISO = security lens). Skills still do the work. Personas and skills compose.

### Tool restriction by role
Read-only agents (reviewers, auditors): `tools: [Read, Grep, Glob]`  
Writers (developers): `tools: [Read, Write, Edit, Bash]`  
Researchers: `tools: [Read, WebFetch, Bash]`  
Full access: omit `tools` field

### Knowledge files as agent memory
`SuperClaude_Framework` uses `PLANNING.md` + `TASK.md` + `KNOWLEDGE.md`. `KNOWLEDGE.md` is self-updating troubleshooting and insight accumulation — same concept as the Claude memory system but as a structured markdown file the agent reads and writes directly.

### Cross-harness portability (ECC, claude-skills)
The agentskills format works across Codex, Claude Code, Cursor, Gemini CLI, Hermes, Mistral Vibe. Design skills to be harness-agnostic. Platform-specific behavior goes in `compatibility:` or `platforms:` frontmatter.
