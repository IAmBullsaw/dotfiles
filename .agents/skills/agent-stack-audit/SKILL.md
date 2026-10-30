---
name: agent-stack-audit
description: "Holistic audit of the full ~/.kiro/agents/ stack as a system: lifecycle separation, resource overlap, missing safety hooks, and write permission coverage. Use when: \"$stack-audit\", \"audit my agent stack\", \"check all agents\", \"agent stack health\", \"are my agents well separated\", \"agent overlap check\", \"missing hooks across agents\", \"agent stack review\". Not for: evaluating a single agent config (use agent-evaluate), auditing hook scripts (use hook-audit)."
---

# Agent Stack Audit

Audit `~/.kiro/agents/` as a system, not as individual configs. Individual agent
quality is `agent-evaluate`'s job. This skill finds systemic problems that only
appear when looking at all agents together: role overlap, missing safety hooks
on agents that accept user input, write permission gaps, and lifecycle separation.

Reference: `~/.agents/skills/skill-writing-lessons/SKILL.md`
Reference: `~/.agents/skills/kiro-agent-spec/SKILL.md`

<context>

## What a healthy agent stack looks like

A well-designed agent stack has:
1. **Clean lifecycle separation** - each agent owns one phase (write / run / review / troubleshoot). No two agents do the same thing.
2. **Minimal resource loading** - each agent loads only what its role requires. No agent loads everything "just in case."
3. **Consistent safety hooks** - every agent that accepts user-pasted content has a `userPromptSubmit` redact hook.
4. **Scoped write permissions** - every agent with `write` in `allowedTools` has `toolsSettings.write.allowedPaths` set.
5. **Explicit `includeMcpJson`** - set on every agent, not left ambiguous.

</context>

<procedure>

## Procedure

```bash
ls ~/.kiro/agents/*.json
```

I extract from each agent: name, tools, allowedTools, resources, hooks, includeMcpJson.

### 2. Check lifecycle separation

I group agents by role and look for overlap:

- ✅ `retrospective` (analysis) and `ecosystem-evolution` (pattern extraction) - different roles, no overlap
- ❌ Two agents both described as "general coding assistant" - one is redundant

For each overlap: which agent is strictly better? The weaker one should be removed or merged.

### 3. Check resource loading

I check whether each agent's resources match its stated role:

```bash
python3 -c "
import json, glob, os
for f in sorted(glob.glob(os.path.expanduser('~/.kiro/agents/*.json'))):
    a = json.load(open(f))
    r = a.get('resources', [])
    print(f\"{a.get('name','?')}: {len(r)} resources\")
"
```

- ✅ `retrospective` loads `learnings.md` and `learnings-context.md` - it writes to both
- ❌ An agent loads `profile`, `learnings.md`, all skills, and 5 reference docs - but its role is narrow (e.g., time reporting)

Flag agents loading >5 resources for a narrow-purpose role.

### 4. Check safety hooks

I check which agents accept user-pasted content (any agent a human types into directly)
and whether they have a `userPromptSubmit` hook for redact scanning.

```bash
grep -l "userPromptSubmit" ~/.kiro/agents/*.json
```

Agents without this hook that accept user input are a data leak risk.

- ✅ the default agent has `userPromptSubmit` redact hook
- ❌ a paste-processing agent accepts user-pasted content but has no redact hook

### 5. Check write permission scoping

Every agent with `write` (or `fs_write`) in `allowedTools` must have `toolsSettings.write.allowedPaths`
(or `toolsSettings.fs_write.allowedPaths`). Both key names are valid per the Kiro spec.
Without it, the agent can write anywhere.

```bash
python3 -c "
import json, glob, os
for f in sorted(glob.glob(os.path.expanduser('~/.kiro/agents/*.json'))):
    a = json.load(open(f))
    allowed = a.get('allowedTools', [])
    has_write = any(t in ('write', 'fs_write', 'fsWrite') for t in allowed)
    if has_write:
        ts = a.get('toolsSettings', {})
        paths = ts.get('write', ts.get('fs_write', {})).get('allowedPaths', [])
        if not paths:
            print(f'MISSING allowedPaths: {f}')
"
```

### 6. Check includeMcpJson

Every agent should have `includeMcpJson` explicitly set. `useLegacyMcpJson` is not a valid field - it is silently ignored. Flag any agent using `useLegacyMcpJson` as a bug.

### 7. Produce findings

</procedure>

<output-format>

## Output format

**Agents audited:** {N} ({list names})

**Lifecycle separation**
{table: agent → role → overlap with}

**Resource loading**
{agents with excessive or mismatched resources}

**Safety hooks**
{agents missing redact hook that accept user input}

**Write permission scoping**
{agents with write in allowedTools but no allowedPaths}

**includeMcpJson coverage**
{agents missing explicit setting or using invalid useLegacyMcpJson field}

**Recommended actions**
1. {highest impact - remove/merge redundant agent, add missing hook, etc.}
2. ...

</output-format>

<failure-recovery>

## Failure recovery

- **Agent file is invalid JSON:** Flag it, skip evaluation, continue with others.
- **Only one agent exists:** Skip lifecycle separation check, evaluate others.
- **No agents with write access:** Write permission section reports clean.
- **All agents pass:** Report clean bill of health. Don't manufacture findings.

</failure-recovery>

<done>

## Done

- [ ] All agent JSON files in `~/.kiro/agents/` inventoried
- [ ] Lifecycle separation checked - overlapping roles identified
- [ ] Resource loading checked - excessive loads flagged
- [ ] Safety hooks checked - agents missing redact hook identified
- [ ] Write permission scoping checked - missing `allowedPaths` identified
- [ ] `useLegacyMcpJson` coverage checked
- [ ] Each finding has a concrete recommended action

</done>