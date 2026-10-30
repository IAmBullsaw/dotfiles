---
name: structure-optimizer
description: "Deep-dive structural analysis of a skill's body text. Optimizes step sequencing, context token footprint, deterministic failure boundaries, and verifiable done criteria. Use when: \"optimize skill structure\", \"fix my skill steps\", \"reduce token bloat\", \"make this skill deterministic\", \"improve skill logic\", \"fix looping agent behavior\", \"restructure skill body\". Not for: auditing frontmatter or writing trigger descriptions (use skill-evaluate)."
---

# Skill Body Structure Optimizer

Analyze and refactor the core execution body of a `SKILL.md` file to eliminate token bloat, maximize algorithmic determinism, and prevent execution loops.

Reference: `~/.agents/skills/skill-writing-lessons/SKILL.md`

## Input Scope
<context>

The user will provide the body text of a skill or a path to a skill directory. I will focus exclusively on the content *below* the frontmatter.

</context>

## Structural Optimization Matrix

I audit and refactor the skill body against 4 foundational structural pillars:

### 1. Token Topography & Scoping (Pillar 1)
* **Rule:** A skill's main file must contain zero static data, massive templates, or reference tables.
* **Action:** I strip out heavy examples or documentation blocks and write a localized structural blueprint explaining exactly what files to dump into the `./references/` sub-directory.
* **Protected blocks - never cut or move these during a token-bloat pass:** frontmatter,
  checklists (`- [ ]` items), code fences, output-format templates, and contrastive
  ✅/❌ example pairs. These carry the skill's enforcement power, not its prose weight - cutting
  them to hit a token target breaks the skill even though the file gets shorter. If a section
  looks bloated but is one of these five block types, the fix is tightening the surrounding
  prose, not deleting the block.

### 2. Algorithmic Sequencing (Pillar 2)
* **Rule:** Multi-step workflows must be written using markdown lists or structured tags (e.g., `<Sequence>`, `<Step>`) using purely imperative, active command verbs.
* **Action:** I flatten paragraphs of prose into strict, un-ordered or sequential state-machine steps.

### 3. Contrastive Guardrail Tuning (Pillar 3)
* **Rule:** Every complex rule requires an explicit contrastive pair (one ✅ Pass and one ❌ Fail example) containing explicit contextual reasoning.
* **Action:** I replace generic "Do/Don't" statements with hyper-targeted, real-world examples custom-tailored to the specific skill's domain.

### 4. Convergence & Hard Termination (Pillar 4)
* **Rule:** The skill must end with an absolute, unambiguous, verifiable checklist (Done Criteria) alongside strict failure recovery loops that bound retries.
* **Action:** I rewrite soft phrases like "ensure it works" into boolean, checkbox-driven state verifications.

---

## Execution Workflow
<procedure>

<Sequence>
  <Step title="Structural Deficit Mapping" subtitle="Identify loop holes">
    Scan the target skill body. Pinpoint exact lines where loose prose, missing edge cases, or heavy data dumps threaten agent execution stability.
  </Step>
  <Step title="Context Decoupling Blueprint" subtitle="Isolate data blocks">
    Draft a file-layout schema showing which chunks of data should be moved into external references to save prompt tokens.
  </Step>
  <Step title="Generate Refactored Core" subtitle="Rewrite the architecture">
    Output a pristine, drop-in replacement body structured with immaculate sequencing, contrastive pairs, and zero-leak guardrails.
  </Step>
</Sequence>

---

</procedure>

## Output Format
<output-format>

Your response must strictly follow this structural blueprint:

### 1. Structural Deficit Report
* **Token Distribution:** [Optimal / Bloated - Identify sections that belong in references/]
* **Execution Logic:** [Linear / Looping Risk - Identify step vulnerabilities]
* **Guardrail Density:** [High / Low - Identify rule gaps missing contrastive pairs]
* **Padding Check:** count cosmetic/style findings or suggestions against substantive
  (behavior-changing) ones in the audit. If cosmetic outnumbers substantive, say so explicitly -
  that ratio itself is a signal the optimization pass is padding rather than improving the skill.

### 2. Decoupling Manifest (File Tree Migration)

Provide a clean directory tree showing what text needs to be broken out into external files:

```text
.kiro/skills/{skill-name}/
├── SKILL.md (Optimized instruction core)
└── references/
    ├── {extracted-template-1}.md
    └── {extracted-docs-2}.md
```

### 3. Refactored Drop-In Body

Provide the completely rewritten skill body using this structure:

```
# [Skill Title]

[Brief, punchy, high-intent operational context]

## Operational Workflow
<Sequence>
  ... [Refactored, highly imperative execution steps] ...
</Sequence>

## Contrastive Guardrails
* ✅ [Pass Example] -> [Contextual Reason]
* ❌ [Fail Example] -> [Contextual Reason]

## Failure Modes & Escape Hatches
* If [Condition A] -> Execute [Action X], then [Exit/Retry Bound]
* If [Condition B] -> Execute [Action Y], then [Exit/Retry Bound]

## Verification Criteria
- [ ] [Measurable Condition 1]
- [ ] [Measurable Condition 2]
```

---

</output-format>

## Failure Recovery Loops
<failure-recovery>

* **Skill body missing structured steps:** If the input uses raw paragraphs, break them down into state steps automatically without asking.
* **Skill domain is highly abstract:** If the target skill domain makes it hard to write concrete examples, invent real-world edge-case proxies based on best CLI practicing patterns.

---

</failure-recovery>

## Done
<done>

* [ ] Audited all 4 structural pillars of the skill body.
* [ ] Confirmed no protected block (frontmatter, checklist, code fence, output template, contrastive pair) was cut or moved during the token-bloat pass.
* [ ] Extracted token-bloating text out into a modular references file mapping.
* [ ] Produced a refactored markdown block using strict, imperative sequencing language.
* [ ] Embedded highly customized contrastive pairs (✅/❌) featuring explicit reasoning.
* [ ] Drafted explicit, bounded failure-recovery modes and checkbox-driven done criteria.
* [ ] Checked the padding ratio (cosmetic vs substantive findings) and flagged it if cosmetic dominates.
</done>
