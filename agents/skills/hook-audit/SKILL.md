---
name: hook-audit
description: "Audit ~/.kiro/hooks/ scripts for compliance with the instrumentation runtime's safety requirements: exit-0 guarantee, ghost file risk, SIGINT safety, and shell parsing brittleness. Use when: \"$hook-audit\", \"audit hooks\", \"check hook scripts\", \"are my hooks safe\", \"hook compliance check\", \"will my hooks block the agent\", \"hook exit codes\", \"hook safety review\". Not for: evaluating agent configs (use agent-evaluate), auditing state files (use state-audit)."
---

# Hook Audit

Audit `~/.kiro/hooks/` scripts against the instrumentation runtime's four safety
requirements. A hook that violates any of these can silently corrupt sessions,
block the agent, or leak state files.

Reference: `~/.agents.local/skills/system-architecture-deep-dive/SKILL.md`
Reference: `~/.agents/skills/kiro-agent-spec/SKILL.md`

<context>

## The four requirements

### 1. Exit-0 guarantee
Every hook must exit 0 unconditionally. A non-zero exit from `preToolUse` blocks
the tool call. A non-zero exit from any hook can crash the agent session.

- ✅ `except Exception: pass` then `sys.exit(0)` - all exceptions swallowed, always exits 0
- ❌ `sys.exit(1)` on error, or no explicit exit - Python default exit on exception is non-zero

### 2. Ghost file safety
`preToolUse` writes timing files (`kiro-tc-*.json`). `postToolUse` deletes them.
If the session dies (SIGINT, context crash, network timeout) between pre and post,
the timing file leaks forever.

- ✅ Hook writes timing file AND `health-check.py` or cron reaps files older than 12h
- ❌ Timing files written with no reaping mechanism - they accumulate indefinitely

### 3. SIGINT / crash safety
Hooks are stateless processes. Any state written to disk must be safe to leave
behind if the hook is killed mid-execution.

- ✅ Writes are atomic (write to temp, rename) or idempotent (overwrite same path)
- ❌ Partial writes to state files - a half-written JSON corrupts the next session's state read

### 4. Shell parsing brittleness (bash hooks only)
`KEY=VALUE` sourcing in bash hooks fails silently on values with spaces, special
characters, or trailing whitespace.

- ✅ Hook is Python with `json.load()` for config - typed, safe
- ❌ Hook sources a `.conf` file with `source config.sh` or `eval $(cat config)` - injection risk

</context>

<procedure>

## Procedure

### 1. List all hooks

```bash
ls ~/.kiro/hooks/
```

For each hook file, I note: language (`.py` / `.sh`), hook type (agentSpawn /
userPromptSubmit / preToolUse / postToolUse / stop).

### 2. Check exit-0 guarantee

For Python hooks: I scan for `sys.exit(0)` at the end and verify the entire
logic is wrapped in `try/except Exception: pass`.

For bash hooks: I scan for `exit 0` at the end and verify `set -e` is NOT used
(it causes silent exits on any error).

### 3. Check ghost file risk

I check if any hook writes files to `~/.kiro/state/` without a corresponding
cleanup. Specifically: does `preToolUse` write timing files? If yes, does
`postToolUse` delete them? Is there a reaping mechanism for files older than 12h?

```bash
find ~/.kiro/state/ -name "kiro-tc-*.json" -mmin +720 | wc -l
```

More than 0 = ghost files confirmed.

### 4. Check SIGINT safety

I verify that all state writes use `path.write_text()` (atomic on most Linux
filesystems) rather than open/write/close sequences that could leave partial files.

### 5. Check shell parsing (bash hooks only)

I scan for `source`, `eval`, or `KEY=VALUE` parsing patterns. If found, I flag
the specific lines and propose a Python rewrite.

### 6. Produce findings

One finding per violation. Each finding includes:
- Which hook file
- Which requirement it violates
- The specific line(s)
- The concrete fix

</procedure>

<output-format>

## Output format

**Hook Audit Report**

**Hooks audited:** {list}
**Violations found:** {N}

**{hook-filename}**

| Requirement | Result | Finding |
|---|---|---|
| Exit-0 guarantee | ✅ / ❌ | {specific note} |
| Ghost file safety | ✅ / ❌ | {specific note} |
| SIGINT safety | ✅ / ❌ | {specific note} |
| Shell parsing | ✅ / N/A | {specific note} |

**Fix:** {concrete action for each violation}

</output-format>

<failure-recovery>

## Failure recovery

- **Hook file not readable:** Flag as unauditable, continue with others.
- **Hook type unclear from filename:** Read the file header comment to determine type.
- **No hooks found:** Report "No hooks in ~/.kiro/hooks/ - instrumentation not active."
- **All hooks pass:** Report clean bill of health. Don't manufacture findings.

</failure-recovery>

<done>

## Done

- [ ] All hook files in `~/.kiro/hooks/` audited
- [ ] Exit-0 guarantee verified for each hook
- [ ] Ghost file count checked (`find ~/.kiro/state/ -name "kiro-tc-*.json" -mmin +720`)
- [ ] SIGINT safety verified for state writes
- [ ] Shell parsing checked for any `.sh` hooks
- [ ] Each violation has a concrete fix, not just a flag

</done>