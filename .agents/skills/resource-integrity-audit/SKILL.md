---
name: resource-integrity-audit
description: "Audit all file:// and skill:// resource paths across every agent config to verify they resolve to real files. Broken resource paths silently degrade agents - they start without the context they expect, with no error. Use when: \"$resource-audit\", \"audit agent resources\", \"broken resource paths\", \"missing agent context files\", \"resource integrity check\", \"do my agents load correctly\", \"check agent file paths\". Not for: auditing agent config quality (use agent-evaluate), auditing skill quality (use skill-evaluate)."
---

# Resource Integrity Audit

Audit every `file://` and `skill://` path in every agent config in `~/.kiro/agents/`.
A broken resource path causes the agent to start without that context - silently.
No error is shown. The agent just operates with less information than it expects.

Reference: `~/.agents/skills/kiro-agent-spec/SKILL.md`

<context>

## What counts as broken

- `file://path` where the path doesn't exist on disk
- `skill://path` where no SKILL.md exists at the resolved path
- Glob patterns (`**/*.md`) that match zero files
- Paths using `~` that don't expand correctly
- Relative paths that resolve incorrectly from the agent config's directory

</context>

<procedure>

## Procedure

```bash
python3 -c "
import json, glob, os
from pathlib import Path

for f in sorted(glob.glob(os.path.expanduser('~/.kiro/agents/*.json'))):
    try:
        a = json.load(open(f))
        name = a.get('name', Path(f).stem)
        resources = a.get('resources', [])
        if resources:
            print(f'\n{name} ({Path(f).name}):')
            for r in resources:
                if isinstance(r, str):
                    print(f'  {r}')
                elif isinstance(r, dict):
                    print(f'  [knowledgeBase] {r.get(\"source\",\"?\")}')
    except Exception as e:
        print(f'ERROR reading {f}: {e}')
"
```

### 2. Resolve and check each path

```bash
python3 -c "
import json, glob, os, re
from pathlib import Path

home = Path.home()
broken = []

for f in sorted(glob.glob(os.path.expanduser('~/.kiro/agents/*.json'))):
    try:
        a = json.load(open(f))
        name = a.get('name', Path(f).stem)
        for r in a.get('resources', []):
            if not isinstance(r, str):
                continue
            # Strip scheme
            if r.startswith('file://') or r.startswith('skill://'):
                path_str = r.split('://', 1)[1]
            else:
                continue
            # Expand ~
            path_str = path_str.replace('~', str(home))
            # Check for glob
            if '**' in path_str or '*' in path_str:
                matches = list(Path('/').glob(path_str.lstrip('/')))
                if not matches:
                    broken.append((name, r, 'glob matches 0 files'))
            else:
                p = Path(path_str)
                if not p.exists():
                    broken.append((name, r, 'file not found'))

if broken:
    print('BROKEN RESOURCES:')
    for agent, res, reason in broken:
        print(f'  [{agent}] {res} - {reason}')
else:
    print('All resources resolve correctly')
"
```

### 3. Check prompt file:// URIs

Some agents use `"prompt": "file://./path.md"`. I also check these.

```bash
python3 -c "
import json, glob, os
from pathlib import Path

home = Path.home()
for f in sorted(glob.glob(os.path.expanduser('~/.kiro/agents/*.json'))):
    try:
        a = json.load(open(f))
        prompt = a.get('prompt', '')
        if isinstance(prompt, str) and prompt.startswith('file://'):
            path_str = prompt[7:].replace('~', str(home))
            p = Path(path_str)
            if not p.exists():
                print(f'BROKEN prompt URI in {Path(f).name}: {prompt}')
    except:
        pass
"
```

### 4. Produce findings

</procedure>

<output-format>

## Output format

**Agents checked:** {N}
**Total resource paths:** {N}
**Broken paths:** {N}

**Broken resources:**
{table: agent | resource path | reason}
or "All resources resolve correctly"

**Recommended actions:**
1. {highest impact - fix broken path or remove stale resource}

</output-format>

<failure-recovery>

## Failure recovery

- **Agent file is invalid JSON:** Skip it, flag it, continue with others.
- **Path uses environment variable:** Flag as "cannot verify statically", note it.
- **All resources resolve:** Report clean. Don't manufacture findings.
- **Glob matches many files:** Report count only, don't list all matches.

</failure-recovery>

<done>

## Done

- [ ] All agent configs in `~/.kiro/agents/` read
- [ ] All `file://` paths checked for existence
- [ ] All `skill://` paths checked for existence
- [ ] All glob patterns checked for at least one match
- [ ] Prompt `file://` URIs checked
- [ ] Each broken path has a concrete recommended action (fix path or remove resource)

</done>