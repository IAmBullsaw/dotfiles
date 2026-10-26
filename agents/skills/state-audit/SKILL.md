---
name: state-audit
description: "Audit ~/.kiro/state/ for leaked timing files, orphaned session state, race condition risks, and invalid JSON. Use when: \"$state-audit\", \"audit state files\", \"check for ghost files\", \"state file cleanup\", \"kiro state health\", \"leaked timing files\", \"orphaned session state\", \"state directory audit\". Not for: auditing hook scripts (use hook-audit), auditing agent configs (use agent-evaluate)."
---

# State Audit

Audit `~/.kiro/state/` against the instrumentation runtime's state management
requirements. The state directory holds three file types, each with different
lifecycle rules. Violations cause ghost file accumulation, race conditions, and
corrupted session context.

Reference: `~/.agents.local/skills/system-architecture-deep-dive/SKILL.md`
Reference: `~/.agents/skills/kiro-agent-spec/SKILL.md`

<context>

## File types and their lifecycle rules

| Pattern | Purpose | Created by | Deleted by | Max age |
|---|---|---|---|---|
| `kiro-wu-{session_id}.json` | Work unit for session | `agentSpawn` hook | Never (one per session) | Unlimited |
| `kiro-corr-{session_id}.json` | Correlation ID for session | `prompt-intent` hook | Never (one per session) | Unlimited |
| `kiro-tc-{md5hash}.json` | Tool call timing (start→end pairing) | `preToolUse` hook | `postToolUse` hook | 12h max |

**Race condition risk:** `kiro-corr-{session_id}.json` is keyed only by `session_id`.
If two sub-agents spawn in the same session, the second overwrites the first's
correlation ID, breaking the causal chain for the first agent's tool calls.

</context>

<procedure>

## Procedure

### 1. Count and classify files

I run these commands and classify each file type:

```bash
ls ~/.kiro/state/ | wc -l
ls ~/.kiro/state/ | grep "kiro-wu-" | wc -l
ls ~/.kiro/state/ | grep "kiro-corr-" | wc -l
ls ~/.kiro/state/ | grep "kiro-tc-" | wc -l
ls ~/.kiro/state/ | grep -v "kiro-wu-\|kiro-corr-\|kiro-tc-" | wc -l
```

### 2. Check for ghost timing files

```bash
find ~/.kiro/state/ -name "kiro-tc-*.json" -mmin +720
```

Any file older than 12h is a ghost - `postToolUse` never fired to clean it up.
This happens on SIGINT, context crash, or network timeout between pre and post.

- ✅ 0 ghost files - cleanup is working
- ❌ >0 ghost files - need reaping mechanism or manual cleanup

### 3. Check for orphaned session state

Session state files (`kiro-wu-*`, `kiro-corr-*`) accumulate one per session.
I check how many exist and whether any are from sessions that no longer have
a corresponding `.jsonl` in `~/.kiro/sessions/cli/`.

```bash
for f in ~/.kiro/state/kiro-wu-*.json; do
    sid=$(basename $f | sed 's/kiro-wu-//;s/.json//');
    [ -f ~/.kiro/sessions/cli/${sid}.jsonl ] || echo "orphaned: $f";
done
```

### 4. Check race condition exposure

I check whether `kiro-corr-{session_id}.json` files exist and whether any two
share the same session_id prefix (indicating a sub-agent collision risk).

```bash
ls ~/.kiro/state/kiro-corr-*.json | wc -l
```

If the system spawns sub-agents, the single-key correlation file is a known
race condition. Flag it with the architectural fix: append `{parent_turn_id}`
to the filename.

### 5. Validate JSON integrity

```bash
for f in ~/.kiro/state/*.json; do
    python3 -c "import json; json.load(open('$f'))" 2>/dev/null || echo "invalid: $f"
done
```

### 6. Produce findings

</procedure>

<output-format>

## Output format

**State Audit Report**

**Total state files:** {N}
**kiro-wu (session state):** {N}
**kiro-corr (correlation):** {N}
**kiro-tc (timing):** {N}
**Other/unknown:** {N}

**Ghost file check**
{N} timing files older than 12h: {list or "none"}

**Orphaned session state**
{N} state files with no matching session: {list or "none"}

**Race condition exposure**
{assessment of kiro-corr single-key risk}

**JSON integrity**
{N} invalid files: {list or "none"}

**Recommended actions**
1. {highest impact action}
2. ...

</output-format>

<failure-recovery>

## Failure recovery

- **State directory empty:** Report clean. No findings to manufacture.
- **`find` command unavailable:** Use `ls -la` with manual age check.
- **JSON parse fails on a file:** Flag it, continue with others.
- **Sessions directory missing:** Skip orphan check, note it.

</failure-recovery>

<done>

## Done

- [ ] All four file types counted and classified
- [ ] Ghost timing files identified (`-mmin +720`)
- [ ] Orphaned session state checked against sessions directory
- [ ] Race condition exposure assessed for `kiro-corr-*` files
- [ ] JSON integrity validated for all state files
- [ ] Each finding has a concrete recommended action

</done>