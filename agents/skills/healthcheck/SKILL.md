---
name: healthcheck
description: "Run a full system health check on the .kiro ecosystem. Validates skills, agents, references, hooks, state files, and learnings in one pass. Use when: \"$healthcheck\", \"system health\", \"check everything\", \"run all audits\", \"how healthy is my setup\", \"validate my system\", \"full audit\". Not for: improving a specific skill (use skill-evaluate), investigating one agent (use agent-evaluate), checking event logs only (use event-log-audit)."
---

# Healthcheck

Full-system health audit. Runs mechanical checks on every .kiro component and produces
a unified report with severity-ordered findings.

## What gets checked
<context>

| Component | Checks | Tool |
|-----------|--------|------|
| Skills (owned only) | Tag pairing, frontmatter, em dashes, line count, code-fence-aware | `audit-skills.py` |
| Agents (all JSON) | Schema validity, model pinned, allowedPaths set, resources resolve | `kiro-cli agent validate` + inline |
| References | Files referenced by skills/agents exist on disk | `rg` + `ls` |
| Hooks | Scripts exist, syntax valid, executable only if directly invoked | `ls` + file checks |
| State files | No ghost timing files (>24h) for any generated prefix | `find` by mtime |
| Learnings | No duplicate bullets, actionable items not stale (>30 days unchecked) | inline scan |
| todo.md | No duplicates of learnings actionable, no completed items still listed | inline scan |

Do not hardcode a skill count here. It went stale within weeks last time and produced a
false finding. `audit-skills.py` prints the live owned and vendored counts.

**Vendored artifacts are excluded, deliberately.** Skills listed in
`~/.kiro/skills/.audit-ignore` are third-party and cannot be fixed without diverging from
upstream, so reporting on them produces unfixable findings that train the reader to ignore
this report. The audit prints the skipped count, so verify that number looks right rather
than assuming exclusion is working.

</context>

## Procedure
<procedure>

### 1. Skills audit

```bash
python3 ~/Code/scripts/audit-skills.py
```

Report the owned count, the vendored skipped count, and HIGH/MEDIUM/LOW. If any HIGH, list
them explicitly. Every remaining finding is in a skill we own, so every one is actionable.

An owned skill that is a pure lookup table or tool reference should carry
`type: reference` in its frontmatter, which exempts it from the `<procedure>` requirement.
If a reference-style skill is reporting a missing `<procedure>`, the fix is the marker, not
inventing a procedure section.

### 2. Agent validation

Run the official validator first, which authoritatively rejects unknown fields and reports
the accepted field set in its error:

```bash
for f in ~/.kiro/agents/*.json; do kiro-cli agent validate --path "$f"; done
```

Silence means valid. Then check the conventions the validator does not cover:
- `model` field is not null (pinned)
- Every path in `resources` array resolves (glob skill:// patterns, check file:// paths exist)
- If `allowedTools` includes write-capable tools, `toolsSettings.write.allowedPaths` exists
- `allowedTools` is non-empty for agents expected to work autonomously, since an empty list
  means every tool call prompts for confirmation

Two traps that have produced false findings here:
- **An unset `includeMcpJson` is not a defect.** Unset means default behavior. Both
  `includeMcpJson` and `useLegacyMcpJson` are valid, distinct fields. Report an unset value
  as a convention gap at most, never HIGH.
- **`fs_read`/`fs_write`/`execute_bash` are valid legacy aliases** for `read`/`write`/`shell`.
  An agent using them is not broken.

**Skip agents we do not own.** Externally delivered agents (for example a CASK-installed
agent) must not be edited, so findings against them are noise. Check ownership before
reporting.

**Resource scope is not duplication.** `skill://.kiro/skills/*/SKILL.md` is workspace-relative
and resolves against the current working directory; `skill://~/.kiro/skills/*/SKILL.md` is
global. An agent declaring both is covering workspace-local and global skills deliberately.
They only resolve to the same files when cwd happens to be the home directory, which is not a
defect. Do not report this pair as a duplicate glob.

**Accepted deviations, do not re-report:**
- `vibbe.json` has a write tool with no `allowedPaths`. This is intentional and confirmed by
  the owner 2026-09-21. Note the consequence so it stays a conscious choice rather than drift:
  its write scope is unbounded, and because a parent's `preToolUse` guard does not apply to
  subagents, `vibbe-guard.py` does not cover writes made by anything it delegates to.

### 3. Reference integrity

For each `file://` and skill:// in all agent resources:
- Resolve the path
- Verify file exists on disk
- Flag missing files

Also check skills that have `Reference:` lines pointing to files.

### 4. Hook validation

For each hook script referenced in agent configs:
- File exists at the path
- No syntax errors (python3 -c "compile(open(f).read(), f, 'exec')" for .py)
- Executable bit **only if the hook is invoked directly**. A command like
  `python3 ~/.kiro/hooks/foo.py` passes the script to an interpreter, so the exec bit is
  irrelevant and flagging it produces a false finding. Only a bare-path command such as
  `~/.kiro/scripts/foo.sh` needs `-x`. Most hooks here are interpreter-prefixed.

### 5. State file health

```bash
# Ghost files (>24h old) are garbage from incomplete tool calls.
# Check EVERY generated prefix, not just kiro-tc. A prefix that no check covers
# accumulates silently: kiro-corr-* reached 172 files over ~4 months unnoticed.
ls ~/.kiro/state/ | sed 's/-[0-9a-f-]*\.json$//' | sort -u   # discover prefixes first
find ~/.kiro/state/ -name "kiro-tc-*.json" -mmin +1440 | wc -l
find ~/.kiro/state/ -name "kiro-corr-*.json" -mmin +1440 | wc -l

# Session state files (kiro-wu-*) are KEPT as reference material - not flagged
```

Discover prefixes before counting, so a newly introduced prefix is caught the first time
rather than after it has accumulated for months.

### 6. Learnings health

- Count unchecked actionable items
- Flag any that reference skills/scripts that now exist (can be checked off)
- Flag duplicate bullets (same first 50 chars under same heading)

### 7. Produce report

</procedure>

## Output format
<output-format>

```
## System Health Report - {date}

**Score:** {X}/10
**Summary:** {one-line}

### Critical (blocks workflow)
- {finding with fix}

### High (degrades quality)
- {finding with fix}

### Medium (improvement opportunity)
- {finding}

### Clean areas
- {component}: all checks pass
```

Scoring:
- 10: 0 findings
- 9: only LOW/MEDIUM
- 8: 1-2 HIGH
- 7: 3-5 HIGH
- <7: structural problems, multiple systems degraded

</output-format>

## Failure recovery
<failure-recovery>

- **audit-skills.py not found:** Fall back to inline rg checks (em dashes, missing frontmatter). Less thorough but still useful.
- **Skipped-vendored count is 0 or missing:** `~/.kiro/skills/.audit-ignore` is absent or unreadable, so vendored skills are being audited and the report will fill with unfixable findings. Restore the file rather than acting on those findings.
- **Skipped count is higher than expected:** an over-broad exclusion is hiding skills we own. Diff the file against the vendored set before trusting a clean report.
- **`kiro-cli agent validate` not available:** Fall back to a `json.load` parse per file, and note in the report that unknown-field detection was skipped.
- **Agent JSON invalid:** Report which file is invalid, skip it, continue with others.
- **Permission denied on hook scripts:** Report the permission issue, don't attempt to fix.
- **State directory missing:** Report and skip. System still works without state tracking.

</failure-recovery>

## Done
<done>

- [ ] All 7 check categories executed
- [ ] Report printed to chat with severity-ordered findings
- [ ] Score assigned (1-10)
- [ ] Every HIGH/CRITICAL finding has a concrete fix action stated

</done>
