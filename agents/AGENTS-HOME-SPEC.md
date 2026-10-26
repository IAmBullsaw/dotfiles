# agents — Specification and Migration Brief for an AI Coding Agent

> **Who this is for:** an AI coding agent (Kiro CLI first, others later) that will inspect the user's current setup and migrate it to this standard.
> **How to use it:** read the whole document before acting. Sections 1–6 define the target state. Sections 7–9 define how to get there. Section 10 lists what you must verify rather than assume.

---

## 0. Operating rules for you, the agent

These override anything else in this document if they conflict.

1. **Phase 0 is read-only.** Do not create, move, link, or edit anything until you have produced the audit report (Section 7, Phase 0) and the human has approved a written plan.
2. **One phase at a time.** After each phase, stop, report what you did and what you observed, and wait for the human.
3. **Never touch tool state.** Do not modify, move, link, or delete: auth/login files, session history, caches, logs, `~/.kiro/settings/cli.json`, `~/.claude.json`, or anything you cannot positively classify as authored content.
4. **Never redirect tool homes.** No `KIRO_HOME`, `CLAUDE_CONFIG_DIR`, `CODEX_HOME` or similar in rc files, scripts, or wrappers. No `PATH` shims around the CLIs. No symlinking a whole `~/.kiro`, `~/.claude`, `~/.kiro/skills` etc. If you find existing redirects, report them; remove them only with approval.
5. **Never overwrite a real file.** If a destination exists and is not a link the system created, it is a conflict: stop and report it.
6. **Back up before any change** to a file outside `~/.agents/`.
7. **No root.** Never use `sudo`, `dnf`, `yum`, or system-wide installs. Never bypass proxies or registry restrictions. If something is unavailable, report it.
8. **No work content in the personal repo.** The machine is employer-owned. Anything containing employer code, internal hostnames, ticket IDs, team names, internal URLs or confidential process goes in the local overlay (Section 3.3), never in `~/.agents/`.
9. **Never commit to or push a shared work repo** without per-repo approval. Never push anything to any remote without explicit confirmation.
10. **Verify, don't assume.** Tool paths and behavior change between versions. Anything in Section 10 must be checked against the installed version before you rely on it. Report what you checked and how.
11. **Do not generate `AGENTS.md` wholesale.** You may propose line-level additions/removals, each with a one-line justification, for human approval.

---

## 1. The problem and the core idea

The user runs several AI coding CLIs (Kiro CLI today; Claude Code, Codex, Gemini CLI, pi and others later). Each expects its own home (`~/.kiro`, `~/.claude`, `~/.codex`) and its own formats. The earlier attempt redirected tool homes with `KIRO_HOME`; that moved auth, sessions and settings along with content, and any script that ran the CLI without the variable saw a different, logged-out install.

**Core idea:**

- Author everything **once** in a canonical folder using **open standards** where they exist (Agent Skills `SKILL.md`, `AGENTS.md`, MCP).
- Leave every tool's home exactly where the tool wants it.
- Route **only content** into tools, using the lightest mechanism that works: native discovery → config reference/import → per-item symlink → generated copy.
- Keep the canonical folder in the user's **dotfiles repo** at `dotfiles/agents/`, linked to `~/.agents`, and deployed by the existing Ansible dotfiles playbook.

The system should get **smaller** over time: as tools adopt the standards natively, links and adapters are deleted.

---

## 2. Vocabulary

| Term | Meaning |
|---|---|
| **Canonical** | The one place a resource is edited. Everything else points to it. |
| **Authored** | Written by the human (or proposed by an agent and approved). Version-controlled. |
| **Native** | Files a tool owns in its own home (`~/.kiro/...`). |
| **Managed** | A native-location file or link that `agents-sync` created and records in its manifest. Only managed items may be changed or removed by the system. |
| **State** | Machine-local bookkeeping (manifest, backups). Never version-controlled, never read by AI tools. |
| **Overlay** | Machine-local authored content that must not go in the personal repo (e.g. work skills). |
| **Target** | One AI CLI the system integrates with (kiro, claude, codex, …). |

---

## 3. The target filesystem

There are exactly four places that matter.

### 3.1 `dotfiles/agents/`, linked to `~/.agents/`

The folder lives in the dotfiles repo as `dotfiles/agents/`; `~/.agents` is a single symlink to it (created by Ansible, Section 8). That symlink is the only whole-folder link in the system and is safe because no AI tool writes into `~/.agents`. Tools that natively scan `~/.agents/skills/` find skills with zero integration work. Edit through either path; it's the same files.

```
dotfiles/agents/   (= ~/.agents)    # part of the dotfiles repo (jj)
├── AGENTS.md                       # global always-on instructions (short, human-written)
├── README.md                       # human docs: what this repo is, how to install
├── skills/                         # Agent Skills standard — one folder per skill
│   ├── code-review/
│   │   ├── SKILL.md                # required: frontmatter (name, description) + body
│   │   ├── references/             # optional: dense docs loaded on demand
│   │   ├── scripts/                # optional: deterministic helpers the skill runs
│   │   └── assets/                 # optional: templates
│   └── jj-gerrit-change/
│       └── SKILL.md
├── targets/                        # tool-specific integration, kept per tool
│   ├── kiro/
│   │   ├── target.json             # what to link/generate for Kiro (Section 5.1)
│   │   └── agents/
│   │       └── main.json           # Kiro-native custom agent definition (see 5.1)
│   ├── claude/                     # created only when Claude Code is adopted
│   │   └── target.json
│   └── codex/                      # created only when Codex is adopted
│       └── target.json
├── mcp/
│   └── servers.json                # canonical MCP definitions; secrets as ${ENV} refs only
├── bin/
│   └── agents-sync                 # the management CLI (Python 3 stdlib only)
├── tests/                          # tests for agents-sync, run in a temp HOME
└── .gitignore
```

Rules for this folder (the dotfiles repo may be public or synced off the work machine — treat it as such):

- **Only authored content.** No generated files, no state, no secrets, no work content.
- **`skills/` is flat.** One level: `skills/<name>/SKILL.md`. The folder name must equal the frontmatter `name`.
- **`targets/<tool>/` holds tool-specific files that have no cross-tool standard** (e.g. Kiro agent JSON). Do not invent a "neutral" agent/command/hook format until a second tool actually needs the same thing. Create a target folder only when that tool is in use.
- **Directories are created when a real resource needs them**, not upfront. No empty `commands/`, `hooks/`, `agents/` scaffolding.

### 3.2 Machine-local state: `${XDG_STATE_HOME:-~/.local/state}/agents-sync/`

```
~/.local/state/agents-sync/
├── manifest.json        # every link/file agents-sync created: path, kind, target, source, sha256, created_at
├── backups/             # <timestamp>/<original-relative-path> copies made before any change
└── capabilities.json    # per-target, per-capability evidence (added later with `probe`)
```

Why not inside the repo: state is per machine; putting it in the repo invites accidental commits and makes clones carry another machine's history.

### 3.3 Machine-local overlay: `~/.agents.local/` (optional)

```
~/.agents.local/                    # NOT in the personal repo; may be its own repo on employer infra
├── AGENTS.md                       # optional machine/work addendum (short)
└── skills/<name>/SKILL.md          # work-only skills
```

- Same layout rules as `~/.agents/`.
- `agents-sync` treats it as a second source. **A skill name existing in both is an error**, not a silent override.
- On a personal machine this folder usually doesn't exist.

### 3.4 Project scope (inside a code repo)

```
my-project/
├── AGENTS.md                # project always-on instructions (open standard, repo root)
├── .agents/
│   └── skills/<name>/       # project-specific skills (same standard)
└── .kiro/ .claude/ ...      # native tool folders — owned by the tool / the team, not by this system
```

- In **personal** repos: commit `AGENTS.md` and `.agents/` normally.
- In **shared work repos**: a team `AGENTS.md` is a team decision. Default is **local-only** — keep personal project skills uncommitted via `.git/info/exclude` (verify jj honors it, Section 10). If approved for commit, it goes in its own jj change, never mixed into a feature change (Gerrit one-commit-per-push).
- Never modify a team-owned `.kiro/` in a work repo.

### 3.5 Resource-to-location table

"Where is the authoritative version edited?" must always have exactly one answer.

| Resource | Canonical location | Authored/State | VCS | Consumed by | Integration into tools | Who may delete |
|---|---|---|---|---|---|---|
| Global instructions | `~/.agents/AGENTS.md` | Authored | personal repo | all tools | Kiro: custom-agent `file://` resource, or per-file link into `~/.kiro/steering/`; Claude: import stub; Codex: per-file link `~/.codex/AGENTS.md` | human |
| Work/machine instructions | `~/.agents.local/AGENTS.md` | Authored | not personal repo | all tools | same as above, as a second resource | human |
| Global skills | `~/.agents/skills/<name>/` | Authored | personal repo | all tools | native where supported; Kiro: custom-agent `skill://` resource, or per-item link into `~/.kiro/skills/` | human |
| Work skills | `~/.agents.local/skills/<name>/` | Authored | not personal repo | all tools | same as global skills | human |
| Project instructions | `<repo>/AGENTS.md` | Authored | project repo (if approved) | all tools | native in most tools; Claude: `CLAUDE.md` import stub | human/team |
| Project skills | `<repo>/.agents/skills/<name>/` | Authored | project repo or local-only | all tools | Kiro: relative `skill://.agents/skills/...` in the global custom agent — no files in the repo | human/team |
| Kiro custom agents | `~/.agents/targets/kiro/agents/*.json` | Authored | personal repo | Kiro only | per-file link into `~/.kiro/agents/` | human |
| MCP servers | `~/.kiro/settings/mcp.json` **stays native in v1**; later `~/.agents/mcp/servers.json` | Authored | personal repo (no secrets) | tools with MCP | v1: none. Later: merge only system-owned keys into native file, with backup | human |
| Secrets | environment / OS keyring / employer secret store | — | never | MCP servers at runtime | referenced as `${VAR}` only | — |
| Tool auth, sessions, caches, `cli.json` | native | Tool state | never | the tool | **never touched** | the tool |
| Manifest, backups | `~/.local/state/agents-sync/` | State | never | agents-sync | — | agents-sync |

---

## 4. What goes in which file (content rules)

### `AGENTS.md` (global and project) — always loaded, so every line costs tokens on every request

Include only what an agent cannot cheaply discover and must not get wrong:
- non-obvious build / test / lint commands;
- hard constraints and forbidden actions ("never push", "one commit per change", "no sudo");
- conventions tooling does not enforce;
- pointers to real docs.

Exclude: architecture tours, anything a linter enforces, generic advice ("write clean code"), step-by-step procedures (→ skills), secrets.

Quality policy (configurable warnings, not hard errors): global ~50 lines, project ~100 lines.

### `SKILL.md` — loaded on demand

- Frontmatter: `name` (matches folder, lowercase-hyphenated), `description` (what it does **and when to use it**, with the words a user would actually type — this is what triggers activation). Tool-specific extra fields go under `metadata:`, not new top-level keys.
- Body: the procedure. Keep it actionable; ~500 lines max (policy). Kiro loads the full body on activation.
- `references/`: schemas, long docs, checklists — loaded only when the body tells the agent to.
- `scripts/`: deterministic steps (validation, conversion). Reference by relative path from the skill folder.
- Third-party skills: vendored (copied in, never live-linked), with `PROVENANCE.md` (Section 6).

### Decision rule for existing content

| If the content is… | It goes to… |
|---|---|
| a rule that applies to every task | `AGENTS.md` (global or project) — after human approval |
| a repeatable multi-step workflow | a skill |
| dense reference material for a workflow | that skill's `references/` |
| something a script can do exactly | that skill's `scripts/` |
| a live connection to an external system | MCP config |
| Kiro-only agent configuration (tools, permissions, model) | `targets/kiro/agents/` |
| work/confidential | `~/.agents.local/` |
| stale, duplicated, or generic | proposed for deletion (human decides) |

---

## 5. Integration per target

Order of preference, per resource and per target:

1. **Native discovery** — tool already reads the canonical path. Do nothing.
2. **Reference/import** — tool config points at the canonical path (Kiro `skill://`/`file://` resources, Claude `@import`).
3. **Per-item symlink** — one link per skill folder or per file. Never a whole tool directory (tools write internal files into their folders).
4. **Generated copy** — only when the tool needs a different format. Marked as generated, tracked in the manifest with its hash.

Links: absolute for global scope, relative for project scope.

### 5.1 Kiro CLI (current tool)

Documented behavior (verify on the installed version):
- Skills: workspace `.kiro/skills/`, global `~/.kiro/skills/`. The **default agent** loads both automatically. On a name conflict, the workspace skill wins.
- **Custom agents do not load skills by default**; they must list them in `resources` with `skill://` URIs (globs and `~` appear in the official examples). `skill://` loads metadata at startup, body on demand.
- Custom agents: JSON in `.kiro/agents/` (workspace) or `~/.kiro/agents/` (global); local takes precedence over global.
- Custom agents do not include steering automatically; steering must be listed as `file://` resources.

**Recommended integration — one global custom agent that references canonical paths:**

`~/.agents/targets/kiro/agents/main.json` (linked to `~/.kiro/agents/main.json`):

```json
{
  "name": "main",
  "description": "Default agent wired to the canonical ~/.agents workspace",
  "resources": [
    "file://~/.agents/AGENTS.md",
    "file://~/.agents.local/AGENTS.md",
    "file://AGENTS.md",
    "skill://~/.agents/skills/*/SKILL.md",
    "skill://~/.agents.local/skills/*/SKILL.md",
    "skill://.agents/skills/*/SKILL.md",
    "skill://.kiro/skills/*/SKILL.md"
  ]
}
```

Why this is preferred:
- No links for skills at all; new skills appear automatically.
- Project skills in `<repo>/.agents/skills/` work through the relative URI, so nothing is written into shared work repos.
- Team `.kiro/skills/` in work repos still loads.

Before relying on it, verify (Section 10): `~` expansion in `file://`, behavior when a referenced file/glob doesn't exist (e.g. no `~.agents.local`), whether repo-root `AGENTS.md` is double-loaded, and how to make `main` the default agent. Also carry over the `tools`/`allowedTools`/permissions from whatever agent the user uses today — don't silently widen or narrow permissions.

**Fallback — per-item links for the built-in default agent:** for each skill, `~/.kiro/skills/<name>` → `~/.agents/skills/<name>`. Use this if the custom agent route fails verification, or for the pilot (Section 7, Phase 2) because it needs no config.

**Leave native:** `~/.kiro/settings/` (incl. `cli.json`, `mcp.json` in v1), hooks, auth, sessions, logs. Existing steering files are triaged (Section 7, Phase 1), not linked wholesale.

### 5.2 Claude Code (only when adopted — verify first)

- Global instructions: `~/.claude/CLAUDE.md` as a managed stub containing only an import of `~/.agents/AGENTS.md` (and the overlay). Project: `CLAUDE.md` stub importing `AGENTS.md` (only where committing is approved; otherwise local).
- Skills: per-item links `~/.claude/skills/<name>` → canonical, unless native `~/.agents/skills` discovery is verified.
- Never link `~/.claude/` or `~/.claude/skills/` as a whole.

### 5.3 Codex and others (only when adopted — verify first)

- Codex reads `AGENTS.md` natively; global instructions via per-file link to Codex's global instructions path. Check whether it discovers `~/.agents/skills/` natively; if so, nothing to do for skills.
- Every new target gets `targets/<tool>/target.json` describing, per capability (`instructions`, `skills`, `agents`, `mcp`, `hooks`), one of: `native` / `reference` / `link` / `copy` / `unsupported`, plus the verified paths.

### 5.4 `target.json` shape

```json
{
  "tool": "kiro",
  "verified_version": "x.y.z",
  "capabilities": {
    "instructions": { "mode": "reference", "via": "targets/kiro/agents/main.json" },
    "skills":       { "mode": "reference", "via": "targets/kiro/agents/main.json",
                      "fallback": { "mode": "link", "dest": "~/.kiro/skills/{name}" } },
    "agents":       { "mode": "link", "src": "targets/kiro/agents/*.json", "dest": "~/.kiro/agents/" },
    "mcp":          { "mode": "native" },
    "hooks":        { "mode": "native" }
  }
}
```

`mode` is a claim that must be backed by evidence (Section 10). If not yet verified, set `"mode": "unknown"` and do nothing for that capability.

---

## 6. Security and supply chain

- **Third-party skills are vendored**, never live-linked or auto-updated.
- `PROVENANCE.md` is **mandatory for any third-party skill containing `scripts/`** or instructions to run shell/network commands; recommended for all third-party skills. Fields: source URL, immutable revision (commit SHA/tag), retrieval date, sha256 of the vendored tree, reviewer, review date, risks (network / credentials / files outside project / shell), status (`pending` / `approved`).
- A provenance file is **not** approval. `status: approved` is set by the human after reading the full `SKILL.md` and every script. Any content change resets review (hash mismatch → `agents-sync check` fails).
- **Secrets** never appear in `AGENTS.md`, skills, `mcp/servers.json`, generated files, the manifest, backups listings, or logs. Use `${VAR}` references resolved at runtime.
- In Kiro agent configs, do not grant the agent write access to `~/.agents/`, `~/.agents.local/` or the state folder unless the human asks; skill edits go through normal reviewed changes.

---

## 7. Migration plan (from the current Kiro setup)

### Phase 0 — Read-only audit (no changes)

Collect and report:

- Environment: `uname -a`, `cat /etc/os-release`, `python3 --version` (and other pythons), `git --version`, `jj --version`, `kiro-cli --version`, whether `claude`/`codex`/`gemini`/`pi` exist, whether github.com (or the chosen remote host) is reachable over git/https.
- Redirects: search rc files (`~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.zshrc`, `~/.config/`), `~/bin`, `~/.local/bin`, crontab (`crontab -l`) and any scripts the user names for `KIRO_HOME`, `*_CONFIG_DIR`, `*_HOME` for AI tools, and wrapper scripts named like the CLIs.
- Kiro content, with file sizes and line counts, symlink targets (`ls -la`, `find -maxdepth 3`): `~/.kiro/skills/`, `~/.kiro/steering/`, `~/.kiro/agents/`, `~/.kiro/settings/mcp.json` (report server **names only**, never values), hooks, plus `.kiro/` in any project the user names.
- Any existing `~/.agents/`, `~/.ai/`, `~/.agents.local/`.
- Cross-references: which agent configs reference which steering/skill paths (grep for `file://`, `skill://`).

Output: an inventory table with one row per item: path, type, size, referenced-by, proposed classification (Section 4 decision rule), proposed destination, contains-work-content (yes/no/unsure). **Stop. Wait for approval.**

### Phase 1 — Create the repo, no tool changes

- Create `dotfiles/agents/` inside the existing dotfiles repo and link `~/.agents` to it (by hand, or by running the Ansible task file with `--tags agents`). `README.md` already exists; add an empty-ish `AGENTS.md`.
- Copy (don't move) approved content into place: skills into `skills/`, Kiro agent JSON into `targets/kiro/agents/`, work items into `~/.agents.local/`.
- Triage steering files: hard rules → proposed `AGENTS.md` lines (as a diff with justifications); procedures → skills; the rest → proposed deletions. Remember Kiro CLI loads steering always, so moving procedures out of steering is a direct token saving.
- Run `agents-sync check` once it exists; until then, check frontmatter by hand.
- Commit as its own jj change in the dotfiles repo. Do not push without confirmation.

Rollback: remove the `~/.agents` link and abandon the jj change in dotfiles; nothing else was touched.

### Phase 2 — Pilot one skill end to end

- Pick one low-risk skill. Back up `~/.kiro/skills/<name>` if it exists, replace it with a per-item link to `~/.agents/skills/<name>`.
- Verify in a fresh Kiro session with the default agent: the skill is listed, a prompt matching its description activates it, any `scripts/` path resolves (relative paths through a symlink are a known risk).

Rollback: remove the link, restore the backup.

### Phase 3 — Custom agent wiring

- Link `targets/kiro/agents/main.json` into `~/.kiro/agents/`. Verify every item in Section 10 for Kiro. Make it the default only after it works.
- Once verified, the pilot link from Phase 2 can be removed (skill now comes via `skill://`).
- Remove `KIRO_HOME` and similar redirects (approved list from Phase 0), one at a time, testing the scripts that used them.

### Phase 4 — Move the rest

- Migrate remaining approved skills. Retire old copies in `~/.kiro/skills/` only after the canonical version is verified loading (backup first).
- Leave `mcp.json`, hooks, settings native.

### Phase 5 — Project scope

- A personal test repo first: `AGENTS.md` + `.agents/skills/`, confirm the relative `skill://` path loads.
- Work repos: local-only (Section 3.4). Never touch team `.kiro/`.

### Phase 6 — Later, only when needed

- Claude Code / Codex targets (Section 5.2–5.3), one at a time, verify-first.
- `agents-sync probe`, MCP managed-key merge, neutral agent/command formats, an existing translator (e.g. Rulesync) — only when a second tool creates a real duplication problem, and only if its dependencies install without root or blocked registries.

---

## 8. New machine: Ansible

The user installs dotfiles with Ansible playbooks. The task file is `dotfiles/ansible/agents.yml`; include it from the dotfiles playbook with tag `agents`.

### Division of responsibility

- **Ansible** places the folder and calls the CLI: links `~/.agents` → `dotfiles/agents`, links `agents-sync` into `~/.local/bin`, runs `agents-sync check` and `agents-sync sync --dry-run`, and runs `agents-sync sync` only when `agents_sync_apply=true`.
- **agents-sync** owns every tool-side link (`~/.kiro/agents/main.json`, skill links) and the manifest.
- Ansible must **never** create tool-side links itself (no `file: state=link` into `~/.kiro` etc.). Two writers means two ownership records and missed conflicts.

### Task file requirements

- No `become`, no packages, no rc-file edits.
- Fail if `~/.agents` is a real directory or a link to somewhere else; never replace it.
- Idempotent: re-running changes nothing. The `apply` task reports `changed` only when agents-sync actually changed something (agents-sync must print a stable "no changes" line when idempotent).
- Works before `agents-sync` exists (links the folder, prints a note, skips the rest).
- Never handles secrets. `~/.agents.local/` is not provisioned from dotfiles; on the work machine it comes from a separate source (e.g. an internal repo) or is created by hand.

### Usage

```bash
ansible-playbook dotfiles.yml --tags agents                           # link + validate + plan
ansible-playbook dotfiles.yml --tags agents -e agents_sync_apply=true # also apply
```

Restricted networks: this needs only the dotfiles checkout, so if the VDI can't reach the git host, bring the repo over SSH as a `git bundle` and clone from it.

---

## 9. `agents-sync` — the management CLI

Python 3 standard library only (no PyYAML, no tomllib dependency): config is JSON; `SKILL.md` frontmatter is parsed with a small subset parser (`key: value`, quoted strings, folded `>`/`|` blocks, nested `metadata:`).

It is **never** needed to run a tool. Tools run normally; `agents-sync` only sets up and checks.

### v1 commands

| Command | Behavior |
|---|---|
| `agents-sync status` | List sources (`~/.agents`, `~/.agents.local`), skills found, targets configured, and for each managed item: ok / missing / drifted / conflict. Read-only. |
| `agents-sync check` | Validate: frontmatter present; `name` matches folder; `description` non-empty and ≤1024 chars; no duplicate names across sources; `PROVENANCE.md` present and hash-matching where required; `AGENTS.md` length warnings; no obvious secrets (simple patterns). Exit non-zero on errors. Read-only. |
| `agents-sync sync --dry-run` | Compute the plan from `targets/*/target.json`: create link / replace own stale link / skip (already correct) / CONFLICT. Print it. Change nothing. |
| `agents-sync sync` | Run the same plan. Back up anything replaced. Write each action to the manifest **as it happens** (so an interrupted run is recoverable). Refuse to proceed if the plan has conflicts. Report actual results. |
| `agents-sync unlink [--target T] [--dry-run]` | Remove only items in the manifest whose on-disk state still matches what was recorded. Anything modified since is reported, not removed. |

Deferred: `probe` (canary-based capability testing), `new` (scaffolding), `add-skill` (vendoring with review), MCP merge, generated copies, hooks.

### Safety contract

- Plan first, then act; dry-run and real run use the same planner.
- Destination is a real file or a link not in the manifest → conflict, stop.
- Destination is a manifest link pointing at the right source → no-op (idempotency: second run = zero actions).
- Every replaced file is copied to `backups/<timestamp>/` first.
- Manifest entries: `{path, kind: "link"|"file", source, target_tool, sha256 (files), created_at}`.
- Prune only manifest-owned items; never pattern-delete (e.g. "all symlinks").
- A skill removed from the source → its managed link is reported as stale and removed only by `sync` with confirmation.

### Tests (run in a temporary `HOME`, no AI CLI required)

Empty destination; existing own link (no-op); foreign file (conflict); foreign link (conflict); stale manifest entry; duplicate skill name across sources; interrupted sync (kill mid-run, rerun converges); idempotency (two runs, second is empty); unlink leaves modified items alone; path traversal (skill name `../x` rejected); backup restore. Real-CLI checks (does Kiro load it?) are manual or `probe`, separate from unit tests.

---

## 10. Verify before relying on (record evidence)

For each item, record: tool version, command run, observed result, date. Store in `targets/<tool>/target.json` (`verified_version`) or later `capabilities.json`. Version numbers alone are not evidence.

Kiro CLI:
- [ ] `~` expands in `file://` resources (documented examples show it for `skill://`).
- [ ] Missing `file://`/`skill://` targets (no overlay, no project `AGENTS.md`) are ignored, not fatal.
- [ ] Repo-root `AGENTS.md` is not loaded twice when also listed in resources.
- [ ] How to set the default agent on the installed version.
- [ ] Global custom agent's relative `skill://.agents/skills/...` resolves against the current working directory.
- [ ] Skill `scripts/` with relative paths work when the skill folder is a symlink.
- [ ] Kiro does not write into linked skill folders or linked agent JSON files unexpectedly (if `/agent` edits write through the link, that's acceptable but must be known).
- [ ] Where Kiro reads global `AGENTS.md`/steering on this version, and whether steering is always-loaded.

jj / repos:
- [ ] jj honors `.git/info/exclude` in colocated repos (for local-only project files).

Claude Code / Codex (when adopted):
- [ ] Native discovery of `~/.agents/skills/` and of `AGENTS.md` (global and project).
- [ ] Import syntax and `~` support in `CLAUDE.md`.
- [ ] Global instruction file location for Codex.

---

## 11. Decisions and rejected alternatives

| Decision | Rejected | Why |
|---|---|---|
| Open standards as canonical format | Custom `~/.ai` format + full compiler | Native reading needs no code; standards outlive any one tool. |
| `dotfiles/agents` linked to `~/.agents` by Ansible | Separate repo + curl install script | Reuses the existing dotfiles deployment; one link keeps native `~/.agents/skills` discovery. |
| Ansible calls agents-sync for tool links | Ansible templates/links tool files directly | One owner of tool-side artifacts and conflict detection. |
| State in `~/.local/state/agents-sync` | `~/.ai/` or `.state/` in repo | Per-machine data stays out of the repo; follows XDG. |
| Work content in `~/.agents.local` overlay | Branches/folders inside the personal repo | Employer content must never reach a personal remote. |
| Kiro via one custom agent with references | Links for everything / copying into `.kiro/` | No links, project skills without touching shared repos. |
| Per-item links as fallback | Whole-folder links | Tools write internal files into their own folders. |
| Tool-specific files under `targets/<tool>/` | Neutral agent/command/hook formats now | No standard exists; one tool doesn't justify an abstraction. |
| `mcp.json` left native in v1 | Immediate MCP centralization | Credentials and merging risk; little gain with one tool. |
| Python stdlib CLI | Node-based translators first | Locked-down VDI, no root, possibly blocked registries. |
| Minimal human-written `AGENTS.md` | Large or generated context files | Always-on context costs tokens every request; generated context tends to hurt. |


