---
name: forgejo
description: "Git pushes, issues and CI on my self-hosted Forgejo (git.konserver.lol) as the claude service identity: which remote to push to, FORGEJO_IDENTITY, service credentials, the forgejo CLI, priority labels and how a good issue reads. Use when pushing, creating or updating issues, triaging, setting priority, checking CI, or when a repo's AGENTS.md says to follow the forgejo skill."
---

# Forgejo as the claude service identity

Applies to every personal repo hosted on `git.konserver.lol`. The repo's own `AGENTS.md` keeps the two hard rules and anything repo-specific; this skill holds the rest. Canonical issue policy: `~/dotfiles/scripts/issue-workflow.yaml`.

## Two identities, never crossed

| | bullen (human) | claude (service identity) |
|---|---|---|
| git transport | SSH, `~/.ssh/id_ed25519` | SSH, `~/.ssh/id_ed25519_claude_forgejo` |
| SSH alias | `git-bullen` | `git-claude` |
| git remote | `origin` | `claude` (`git-claude:bullen/<repo>.git`) |
| API token | `.git/forgejo/token-bullen` | `.git/forgejo/token-claude` (selected by `FORGEJO_IDENTITY=claude`) |
| commit identity | `IAmBullsaw <hello@oskarjansson.com>` | `claude <claude@konserver.lol>` (repo-local `.git/config [user]`) |

`claude` is the service identity's name, not a requirement to use a particular coding agent.

Rules:
- Push only via the `claude` remote: `git push claude <branch>`. Never push to, use or alter `origin`, its transport config or the bullen identity.
- Keep repo-local `user.name` / `user.email` set to the claude identity.
- Always run the CLI as `FORGEJO_IDENTITY=claude forgejo ...`.
- Pushing still needs the user's go-ahead; this skill says how, not when.

Why: both git and the API used to share one HTTPS app token in the machine-wide git credential store. Concurrent sessions rewriting that one slot broke each other's auth. Now git uses per-identity SSH keys and the API uses per-repo token files, both scoped per identity.

## Service credentials

- Before API work, require a non-empty `.git/forgejo/token-claude` belonging to the claude account, with the access the task needs (repository read, issues read/write). Never read or print a token.
- If it is missing, empty or rejected: stop and ask the user to provision it in the Forgejo UI. Never fall back to `token-bullen`, the shared credential store (`git credential fill`; `forgejo.py` keeps it as a legacy fallback for the bullen identity only and exits for any other identity), an unverified `FORGEJO_TOKEN`, or human credentials to mint a service token.
- A working SSH key doesn't give API access, and an API token doesn't give git access. Keep them separate.
- `.git/forgejo/token-*` live inside `.git/`, untracked, and never leave the machine.

## Remote URL gotcha

`origin`'s stored URL stays `https://git.konserver.lol/bullen/<repo>` because `forgejo.py` parses host/owner/repo from it. Transport is rewritten to SSH by a repo-local `url."git-bullen:".insteadOf`. `git remote -v` shows the rewritten `git-bullen:...` form; check the stored value with `git config --get remote.origin.url`.

Forgejo git-SSH is LAN-only (NodePort 30022 on bullens), pubkey-only, no shell.

## The forgejo CLI

`~/dotfiles/scripts/forgejo.py`, linked as `~/.local/bin/forgejo`. Run from inside the repo. Check `forgejo <cmd> --help` rather than guessing flags.

```bash
export FORGEJO_IDENTITY=claude
forgejo issues [--state open|closed|all] [--label L] [--limit N]   # pages through all results
forgejo show <n> --comments
forgejo create --title "..." --body "..." --label p3-normal
forgejo comment <n> "..."
forgejo close <n> "closing comment with evidence"
forgejo reopen <n>
forgejo label-add <n> <label>      /  forgejo label-remove <n> <label>
forgejo set-priority <n> p2 "reason"            # posts the audit comment for you
forgejo set-size <n> s "reason"                 # only in repos that use size labels
forgejo ensure-labels                           # create the standard priority labels
forgejo batch ops.json [--json-output]          # or `-` for stdin
forgejo ci-status  /  forgejo ci-list  /  forgejo ci-logs <run>
```

## Issues

- Issues in the repo's Forgejo are the single source of truth for TODOs, bugs, findings and decisions. Check them when starting work and update them when finishing. A conclusion that only exists in chat is not tracked.
- Every issue has exactly one priority label: `p1-critical` (blocks normal operation or risks data loss), `p2-high` (significant, soon), `p3-normal` (standard backlog), `p4-low` (nice to have).
- Setting or changing priority always gets a comment with the reason, e.g. `**Priority changed: p3-normal → p1-critical** — reason`. `set-priority` does this.
- Size labels (`size-xs` … `size-xl`) and type labels are per repo: the canonical policy has none, a repo's `AGENTS.md` may opt in.
- Dependencies are Forgejo's native relationships, not labels.

How a good issue reads:
- Lead with the observable fact or goal, not the guess.
- Show the evidence: the command output, the measured number, the log line.
- Say what was ruled out and how.
- Record deliberate decisions, including options declined, so the reasoning isn't redone.
- A verification section with the exact commands that prove the claim.
- Cross-link related issues, especially ordering constraints.
- Mark unverified claims as unverified.

Close with evidence in the closing comment. Don't close an intermittent problem on one green probe; that needs a rate over time.
