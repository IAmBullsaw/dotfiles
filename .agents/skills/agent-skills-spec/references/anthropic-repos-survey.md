# Anthropic Repos Survey — Distilled Reference

Cloned at: `/home/bullen/projects/ai-repos/`  
Date: 2026-06-03

---

## skills
**What it is:** Official Anthropic skills repo — example skills across creative, technical, enterprise, and document workflows.  
**Most useful for:** Primary reference for `SKILL.md` structure. Complex document skills (PDF, DOCX, XLSX, PPTX) show real production patterns.

- Skills are self-contained YAML frontmatter + markdown, loadable into Claude.ai, Claude Code, Claude API
- `/template/` is the minimal starting point
- `/spec/` is the formal Agent Skills specification

**Standout files:** `skills/docx/`, `skills/pdf/`, `template/`, `spec/`

---

## claude-cookbooks
**What it is:** Copy-paste Jupyter recipes for Claude API capabilities — classification, RAG, summarization, tool use, vision, and third-party integrations.  
**Most useful for:** API patterns. Sub-agents (Haiku as worker, Opus as orchestrator), prompt caching, JSON mode, multi-turn tool loops, form extraction, RAG with vector DBs.

**Standout files:**
- `tool_use/customer_service_agent.ipynb` — multi-turn tool use loop
- `misc/prompt_caching.ipynb` — caching strategy
- `capabilities/retrieval_augmented_generation/` — RAG patterns

---

## financial-services
**What it is:** Reference multi-skill agents for FSI workflows (pitch decks, market research, earnings, GL reconciliation, KYC) deployable as Claude Code plugins or Managed Agents.  
**Most useful for:** Multi-skill agent architecture, subagent orchestration, MCP connector bundles, skill-sync automation.

Key patterns:
- Skills organized by vertical (investment-banking, equity-research, PE, wealth-management) then synced into agent bundles via `scripts/sync-agent-skills.py`
- `agent.yaml` wraps same skills as plugin — one source of truth
- Orchestrator event loop routes `handoff_request` events between callable subagents
- 11 MCP connectors (Daloopa, Morningstar, FactSet, etc.) in `.mcp.json`

**Standout files:** `plugins/agent-plugins/pitch-agent/`, `managed-agent-cookbooks/gl-reconciler/agent.yaml`, `scripts/orchestrate.py`, `scripts/sync-agent-skills.py`

---

## claude-plugins-official
**What it is:** Official Claude Code plugin marketplace — directory structure, `plugin.json` schema, submission guidelines.  
**Most useful for:** Marketplace mechanics. Skill-bundle mode (explicit skills array), security/quality gates, plugin manifest schema.

- Plugin manifest: `.claude-plugin/plugin.json` with source refs, category, author
- Skill-bundle: reference git subdirs with relative skill paths

**Standout files:** `README.md`, `plugins/example-plugin/`

---

## claude-for-legal
**What it is:** 50+ agents and skills across 10 legal practice areas, MCP connectors to 10+ legal research/productivity tools, community skill trust layer, Managed Agent cookbooks.  
**Most useful for:** Largest example of a multi-skill agent ecosystem. Cold-start interview → practice profile (CLAUDE.md) that every skill reads. Scheduled and event-driven agents. Community skill QA framework.

Key patterns:
- **Cold-start interview** writes a practice profile (CLAUDE.md); all downstream skills read from it — strong personalization pattern
- Skills bundled per practice area; agents get their own copies
- **Scheduled agents** (cron-style renewal-watcher, docket-watcher)
- **Community trust layer**: registry allowlist, license gate, hidden-content scan, freshness check
- Output formats: tracked-changes Word, multi-sheet Excel with citations
- MCP: CourtListener, Trellis, Descrybe, Ironclad, DocuSign, iManage, Slack, Google Drive

**Standout files:** `commercial-legal/skills/vendor-agreement-review/SKILL.md`, `managed-agent-cookbooks/renewal-watcher/agent.yaml`, `scripts/orchestrate.py`, `legal-builder-hub/` (trust/QA framework)

---

## anthropic-cli
**What it is:** Official Go CLI for the Claude API — resource-based command structure, multi-provider auth, flexible output.  
**Most useful for:** CLI integration/scripting patterns. `@file.ext` auto-sniffs encoding; GJSON transformation filters; Bedrock/Vertex/Azure auth.

- `ant [resource] <command> [flags]` — resource-based
- `@myfile.ext` = inline file, `@file://` or `@data://` explicit prefixes
- Output: auto, pretty, JSON, YAML, raw

**Standout files:** `cmd/`, `README.md`

---

## claude-code-action
**What it is:** GitHub Actions integration for Claude — autodetects PR/issue context, dispatches to code review, Q&A, or implementation modes; runs on your own runner.  
**Most useful for:** CI/CD automation. Mode detection from @claude mentions or issue assignment; structured JSON outputs as Action outputs; MCP config; access control.

- Multi-provider: Anthropic API, Bedrock, Vertex, Azure Foundry
- `docs/solutions.md` has ready-to-use automation patterns (PR review, contributor triage, security review)

**Standout files:** `docs/solutions.md`, `docs/configuration.md`, `src/modes/`

---

## defending-code-reference-harness
**What it is:** 7-stage autonomous vulnerability discovery and remediation pipeline for C/C++ codebases — recon → find → verify → report → patch — with gVisor sandboxing and multi-agent parallel scanning.  
**Most useful for:** Multi-agent security pipeline architecture. Default-FAIL contract, grader subagent, parallel scanning pattern, sandbox isolation.

Key patterns:
- **7-stage pipeline:** build (ASAN) → recon (partition) → find (parallel agents) → verify (grader reproduces) → dedupe (judge agent) → report (exploitability) → patch (fix + validate)
- **gVisor sandbox** with egress allowlist — hard containment for agent execution
- **Default-FAIL contract:** findings only count if build reproduces (same contract as cwc-long-running-agents)
- Customizable: port to new language by answering 3 questions (signal, POC format, build/run)

**Standout files:** `harness/cli.py`, `harness/agent.py`, `.claude/skills/`, `scripts/setup_sandbox.sh`, `docs/pipeline.md`

---

## healthcare
**What it is:** Skills for FHIR development, prior authorization review, and clinical trial protocol generation; MCP connectors to CMS, ICD-10, NPI Registry, PubMed.  
**Most useful for:** Healthcare domain skills and regulated-data connector patterns.

**Standout files:** `fhir-developer-skill/SKILL.md`, `prior-auth-review-skill/`

---

## html-effectiveness
**What it is:** Gallery of self-contained single-file HTML examples (no build, no frameworks) — code review UIs, design systems, slide decks, status reports, interactive editors, triage boards.  
**Most useful for:** HTML as a rich Claude output format. Everything in one `.html` file, embeddable in responses. Categories: exploration, code, prototyping, communication, diagrams, custom UIs.

**Standout files:** `index.html` (categorized index), `03-code-review-pr.html`, `05-design-system.html`, `09-slide-deck.html`

---

## cwc-long-running-agents
**What it is:** Reference implementation of harness primitives for reliable multi-session Claude Code agents — generator/evaluator loops with hooks, default-FAIL contracts, and agent-maintained handoff.  
**Most useful for:** Building agents that run unattended across sessions without losing state or silently failing.

Key patterns:
- **Default-FAIL contract:** every feature starts `false`; a PreToolUse hook denies writes unless the agent has read the evidence first
- **Fresh-context evaluator:** separate subagent grades work from a context that never saw the build — no confirmation bias
- **Agent-maintained handoff:** agent writes `PROGRESS.md` + commits; next session reads it, no memory loss across restarts
- **Operator controls:** kill-switch and steer hooks; watching via `tail`, `git log`, screenshots
- `/goal` command: built-in completion checker (one line, no hooks needed)
- Patterns apply directly to Agent SDK via PreToolUse/Stop callbacks

**Standout files:** `.claude/hooks/track-read.sh` + `verify-gate.sh`, `.claude/agents/evaluator.md`, `.claude/CLAUDE.md`

---

## claude-constitution
**What it is:** Anthropic's values and principles document for Claude's development (Jan 2026).  
**Most useful for:** Context for prompt engineering and safety-aware agent design.

**Standout files:** `20260120-constitution.md`

---

## courses
**What it is:** Structured Claude API curriculum — fundamentals → prompt engineering → real-world prompting → evaluations → tool use.  
**Most useful for:** Ordered learning path from API basics to production eval + tool use patterns.

---

## claude-code-monitoring-guide
**What it is:** Framework for measuring Claude Code ROI — Prometheus/OpenTelemetry telemetry, cost tracking, productivity metrics, Linear integration.  
**Most useful for:** Teams deploying Claude Code at scale. Docker Compose + Prometheus self-hosted stack.

Key metrics: cost per session, token usage, cache efficiency, PR frequency, adoption per developer.

**Standout files:** `claude_code_roi_full.md`, `docker-compose.yml`, `prometheus.yml`, `otel-collector-config.yaml`

---

## evals
**What it is:** Model-written evaluation datasets (persona, sycophancy, advanced AI risk) from Anthropic research.  
**Most useful for:** Evaluation methodology reference.

---

## PySvelte
**What it is:** Python↔Svelte bridge for ML research visualization — Svelte components with Python tab-completion, cloud publish, Jupyter/Colab support.  
**Most useful for:** ML visualization architecture pattern. Standalone HTML export.

---

## Cross-repo patterns worth stealing

### 1. Cold-start interview → practice profile
(From `claude-for-legal`, `financial-services`) An onboarding interview writes a CLAUDE.md that all subsequent skills read from. Every skill is personalized without hardcoding anything.

### 2. Default-FAIL contract
(From `cwc-long-running-agents`, `defending-code`) Every claim starts `false`. A hook (PreToolUse) enforces that the agent must read evidence before it can claim success. Prevents silent failures in long-running agents.

### 3. Fresh-context evaluator
(From `cwc-long-running-agents`, `defending-code`) A separate subagent grades work from a context with no Write/Edit access and no history of the build. Eliminates confirmation bias in self-assessment.

### 4. Agent-maintained handoff
(From `cwc-long-running-agents`) Agent writes `PROGRESS.md` + commits at every Stop. Next session reads it. No session state needed, works across restarts and interruptions.

### 5. Skill-sync automation
(From `financial-services`) Skills live in domain verticals; a script bundles them per agent. Single source of truth, no duplication.

### 6. Subagent orchestrator with handoff_request
(From `financial-services`, `claude-for-legal`) A top-level orchestrator routes tasks to specialist subagents via `handoff_request` events. Each subagent is a separate agent definition; the loop is in `orchestrate.py`.

### 7. HTML as rich output format
(From `html-effectiveness`) Single-file `.html` with no build step is a powerful output format — dashboards, editors, slide decks, code review UIs. No frameworks needed.
