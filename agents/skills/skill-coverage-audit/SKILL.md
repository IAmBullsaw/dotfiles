---
name: skill-coverage-audit
description: "Audit the three skill roots (~/.agents/skills, ~/.agents.local/skills, ~/.kiro/skills) for dead skills (not loaded by any agent), trigger phrase overlap between skills, and skills missing required frontmatter. Use when: \"$skill-coverage\", \"audit skills\", \"dead skills\", \"unused skills\", \"skill overlap\", \"which skills are loaded\", \"skill trigger conflicts\", \"skill coverage check\". Not for: evaluating a single skill's quality (use skill-evaluate), auditing agent configs (use agent-stack-audit)."
---

# Skill Coverage Audit

Audit the skill set as a system. Individual skill quality is `skill-evaluate`'s job.

Since the 2026-10-26 switch, skills live in three roots, and I always sweep all three:
`~/.agents/skills` (personal, dotfiles), `~/.agents.local/skills` (work, dot-ai) and
`~/.kiro/skills` (only the native skills that stay with a vendored agent bundle). Sweeping `~/.kiro/skills`
alone sees 18 of 104 skills (count on 2026-10-26) and reports a clean result that is false.
This skill finds systemic problems: skills that exist but are never loaded, trigger phrases
that overlap between skills causing unpredictable activation, and skills with broken
frontmatter that can't be parsed.

Reference: `~/.agents/skills/kiro-agent-spec/SKILL.md`

## What a healthy skill set looks like
<context>

1. Every skill in the three roots is loaded by at least one agent via a `skill://` glob or path.
2. No two skills share trigger phrases that would cause the same user input to match both.
3. Every SKILL.md has valid frontmatter with `name` and `description` fields.
4. The `name` in frontmatter matches the folder name.

</context>

## Procedure
<procedure>

### 1. Inventory all skills

```bash
ls ~/.agents/skills ~/.agents.local/skills ~/.kiro/skills
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

A skill is covered when `fnmatch` of its `SKILL.md` path against an agent's pattern
(with `~` expanded) matches. Relative patterns like `skill://.agents/skills/*/SKILL.md`
resolve against the working folder, so I resolve them from `~` and say so in the report.

- ✅ `skill://~/.agents.local/skills/*/SKILL.md` in `⚡ ez` - covers every work skill
- ❌ `skill://~/.kiro/skills/**/SKILL.md` as proof of full coverage - since the switch that root holds only the native bundle skills

### 3. Check for trigger overlap

I extract the `description` field from each skill's frontmatter and look for shared
trigger phrases - especially the `Use when:` section.

```bash
python3 - <<'EOF'
import re
from collections import defaultdict
from pathlib import Path

ROOTS = [Path.home() / r for r in ('.agents/skills', '.agents.local/skills', '.kiro/skills')]
phrase_map = defaultdict(set)
for skill_md in [p for r in ROOTS for p in r.glob('*/SKILL.md')]:
    m = re.search(r'^description:\s*(.+)$', skill_md.read_text(), re.MULTILINE)
    if not m:
        continue
    # Descriptions are one double-quoted YAML line; phrases inside
    # are escaped quotes, so match \"...\" rather than bare quotes.
    for t in re.findall(r'\\"([^"\\]+)\\"', m.group(1)):
        t = t.strip()
        if 6 <= len(t) <= 60 and not any(c in t for c in '`*'):
            phrase_map[t.lower()].add(skill_md.parent.name)

conflicts = {p: sorted(n) for p, n in phrase_map.items() if len(n) > 1}
print('TRIGGER CONFLICTS:' if conflicts else 'No trigger conflicts found')
for phrase, names in sorted(conflicts.items()):
    print(f'  "{phrase}" -> {names}')
EOF
```

### 4. Check frontmatter validity

```bash
python3 -c "
import re
from pathlib import Path

ROOTS = [Path.home() / r for r in ('.agents/skills', '.agents.local/skills', '.kiro/skills')]
for skill_md in sorted(p for r in ROOTS for p in r.glob('*/SKILL.md')):
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

**Skills found:** {N} ({a} in ~/.agents/skills, {b} in ~/.agents.local/skills, {c} in ~/.kiro/skills)

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

- [ ] All skill folders in all three roots inventoried
- [ ] Dead skills identified (not covered by any agent's skill:// resource)
- [ ] Trigger overlap checked across all skill descriptions
- [ ] Frontmatter validity checked for each skill
- [ ] name/folder match verified for each skill
- [ ] Each finding has a concrete recommended action

</done>
