---
name: skill-coverage-audit
description: >
  Audit ~/.kiro/skills/ for dead skills (not loaded by any agent), trigger phrase
  overlap between skills, and skills missing required frontmatter. Use when:
  "$skill-coverage", "audit skills", "dead skills", "unused skills", "skill overlap",
  "which skills are loaded", "skill trigger conflicts", "skill coverage check".
  Not for: evaluating a single skill's quality (use skill-evaluate), auditing
  agent configs (use agent-stack-audit).
---

# Skill Coverage Audit

Audit `~/.kiro/skills/` as a system. Individual skill quality is `skill-evaluate`'s job.
This skill finds systemic problems: skills that exist but are never loaded, trigger phrases
that overlap between skills causing unpredictable activation, and skills with broken
frontmatter that can't be parsed.

Reference: `~/.agents/skills/kiro-agent-spec/SKILL.md`

## What a healthy skill set looks like
<context>

1. Every skill in `~/.kiro/skills/` is loaded by at least one agent via `skill://` glob.
2. No two skills share trigger phrases that would cause the same user input to match both.
3. Every SKILL.md has valid frontmatter with `name` and `description` fields.
4. The `name` in frontmatter matches the folder name.

</context>

## Procedure
<procedure>

### 1. Inventory all skills

```bash
ls ~/.kiro/skills/
```

For each skill folder, I check that `SKILL.md` exists and has valid frontmatter.

### 2. Check which skills are loaded by agents

```bash
python3 -c "
import json, glob, os, re
from pathlib import Path

# Find all skill:// patterns in agent configs
loaded = set()
for f in glob.glob(os.path.expanduser('~/.kiro/agents/*.json')):
    try:
        a = json.load(open(f))
        for r in a.get('resources', []):
            if isinstance(r, str) and r.startswith('skill://'):
                # Check if it's a glob that would match our skills
                loaded.add(r)
    except:
        pass

print('Skill resource patterns in agents:')
for r in sorted(loaded):
    print(f'  {r}')
"
```

Then I check which skill folders are covered by those patterns.

- ✅ `skill://~/.kiro/skills/**/SKILL.md` - covers all skills
- ❌ `skill://~/.agents.local/skills/retrospective/SKILL.md` - only loads one skill, others are dead

### 3. Check for trigger overlap

I extract the `description` field from each skill's frontmatter and look for shared
trigger phrases - especially the `Use when:` section.

```bash
python3 -c "
import re
from pathlib import Path

skills = {}
for skill_md in Path.home().glob('.kiro/skills/*/SKILL.md'):
    content = skill_md.read_text()
    m = re.search(r'description:\s*>\s*(.*?)(?=\n\w|\Z)', content, re.DOTALL)
    if m:
        skills[skill_md.parent.name] = m.group(1).strip()

# Look for shared trigger phrases (only clean phrases: 6-60 chars, no special chars)
from collections import defaultdict
phrase_map = defaultdict(list)
for name, desc in skills.items():
    triggers = re.findall(r'"([^"]+)"', desc)
    for t in triggers:
        t = t.strip()
        # Skip: too short, too long, contains newlines or emoji/special chars
        if len(t) < 6 or len(t) > 60: continue
        if any(c in t for c in ['\n', '❌', '✅', '->', '→', '`', '*']): continue
        phrase_map[t.lower()].append(name)

conflicts = {p: names for p, names in phrase_map.items() if len(names) > 1}
if conflicts:
    print('TRIGGER CONFLICTS:')
    for phrase, names in sorted(conflicts.items()):
        print(f'  \"{phrase}\" → {names}')
else:
    print('No trigger conflicts found')
"
```

### 4. Check frontmatter validity

```bash
python3 -c "
import re
from pathlib import Path

for skill_md in sorted(Path.home().glob('.kiro/skills/*/SKILL.md')):
    content = skill_md.read_text()
    folder = skill_md.parent.name
    has_fm = content.startswith('---')
    name_m = re.search(r'^name:\s*(\S+)', content, re.MULTILINE)
    desc_m = re.search(r'^description:', content, re.MULTILINE)
    name = name_m.group(1) if name_m else 'MISSING'
    issues = []
    if not has_fm: issues.append('no frontmatter')
    if not name_m: issues.append('no name field')
    if not desc_m: issues.append('no description field')
    if name != folder: issues.append(f'name mismatch: {name} != {folder}')
    if issues:
        print(f'ISSUES {folder}: {issues}')
    else:
        print(f'OK {folder}')
"
```

### 5. Produce findings

</procedure>

## Output format
<output-format>

**Skill Coverage Audit Report**

**Skills found:** {N} in ~/.kiro/skills/

**Dead skills (not loaded by any agent):**
{list or "none"}

**Trigger conflicts:**
{list of conflicting phrases with skill names, or "none"}

**Frontmatter issues:**
{list of skills with broken frontmatter, or "none"}

**Recommended actions:**
1. {highest impact}

</output-format>

## Failure recovery
<failure-recovery>

- **No skills directory:** Report "No skills found - skill system not active."
- **No agents load skills:** All skills are dead - report this as a systemic issue.
- **Frontmatter parse fails:** Flag the specific skill, continue with others.
- **All skills pass:** Report clean. Don't manufacture findings.

</failure-recovery>

## Done
<done>

- [ ] All skill folders in `~/.kiro/skills/` inventoried
- [ ] Dead skills identified (not covered by any agent's skill:// resource)
- [ ] Trigger overlap checked across all skill descriptions
- [ ] Frontmatter validity checked for each skill
- [ ] name/folder match verified for each skill
- [ ] Each finding has a concrete recommended action

</done>
