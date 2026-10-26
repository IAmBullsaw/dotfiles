---
name: diction-optimizer
description: >
  Deep-dive auditing of a skill's linguistic precision, terminology consistency,
  and behavioral tone. Eliminates passive language, vague fluff, and menu loops.
  Use when: "fix skill writing", "clean up prompt language", "improve prompt phrasing",
  "fix passive instructions", "make prompt clear", "audit skill terminology",
  "remove vague advice from skill".
  Not for: restructuring directory layouts or editing frontmatter metadata (use structure-optimizer).
---

# Skill Diction & Writing Quality Optimizer

Analyze and refine the text of a skill file to enforce an authoritative, first-person imperative tone, purge ambiguous corporate fluff, and optimize linguistic prompt clarity.

Reference: `~/.agents.local/skills/skill-writing-lessons/SKILL.md`

## Input Scope
<context>

The user will provide a skill's text. I isolate the prose, guidelines, and behavioral descriptions to evaluate the linguistic impact on LLM reasoning engines.

</context>

## Linguistic Optimization Audits

I scan and rewrite the skill prose against 5 critical writing benchmarks:

### 1. Imperial First-Person Stance
* **Anti-Pattern:** "The model should attempt to verify...", "The agent could consider..."
* **Fix:** Convert to absolute, active first-person execution: "I will verify...", "I must execute..."

### 2. Radical Specificity & Intent De-Fluffing
* **Anti-Pattern:** "Write clean code", "Be polite and helpful", "Carefully check for errors."
* **Fix:** Replace with verifiable, execution-level metrics: "I will run `eslint` to verify code layout", "I will parse the output JSON keys strictly against the schema."

### 3. Logically Grounded Constraints ("Because" Enforcements)
* **Anti-Pattern:** "NEVER run tests in production." (An LLM can gloss over blind negatives).
* **Fix:** "I will never run tests against the production environment because running un-sandboxed tests risks mutating live client database records."

### 4. Terminology Synchronization
* **Anti-Pattern:** Referring to a configuration file as "the script", "the config block", and "the setup map" interchangeably within the same file.
* **Fix:** Enforce one strict noun per asset across the entire skill lifecycle.

### 5. Menu Extermination (Default + Escape Hatch)
* **Anti-Pattern:** Giving the agent choices in its instructions: "You can use option A, or you could do option B, or try C."
* **Fix:** Establish a deterministic default track with a conditional escape hatch: "I will use Track A by default. If Track A returns a 403 error, I will immediately drop back to Escape Hatch B."

---

## Execution Workflow
<procedure>

<Sequence>
  <Step title="Linguistic Drift Isolation" subtitle="Highlight bad phrasing">
    Scan the skill's text. Flags lines containing passive voice, optionality phrases ("should/could/maybe"), non-specific instructions, or mixed terminology.
  </Step>
  <Step title="The 'Because' Clause Injection" subtitle="Inject rationales">
    For every absolute rule (`ALWAYS` or `NEVER`), determine the implicit engineering risk and append a logical reasoning statement to make the rule stick.
  </Step>
  <Step title="Pristine Prose Synthesis" subtitle="Rewrite the copy">
    Output an updated, highly optimized version of the text using punchy, professional, first-person imperative syntax.
  </Step>
</Sequence>

---

</procedure>

## Output Format
<output-format>

Your evaluation report must use this exact layout:

### 1. Diction Audit Matrix
* **Tone Authority:** [High / Passive - Identify "should/could" leakages]
* **Ambiguity Footprint:** [Clean / Fluffy - Identify vague phrases like "clean code"]
* **Noun Consistency:** [Unified / Mixed - List any shifting terminology]

### 2. Phrase Transformations (Before / After)
Provide a clear markdown table showing the exact tactical text updates made:
| Old Phrasing (Weak) | New Phrasing (Engineered) | Prompt Impact Reason |
|---------------------|---------------------------|----------------------|
| "{weak string}"     | "{optimized imperative}"  | {why this works better} |

### 3. Fully Refactored Skill Text

Provide the completely rewritten, linguistically polished text block here.

---

</output-format>

## Failure Recovery Loops
<failure-recovery>

* **Skill text uses extreme technical jargon exclusively:** Balance it by translating technical execution instructions into clear, logical first-person directives without losing the rigorous constraints.
* **The user provides a fragmented file snippet:** Optimize the writing of the snippet provided, ensuring it fits cleanly into an authoritative first-person stance.

---

</failure-recovery>

## Done
<done>

* [ ] Audited text for active first-person imperative syntax ("I will").
* [ ] Eliminated vague corporate advice and replaced it with strict, actionable metrics.
* [ ] Injected clear logical context ("because") into all hard constraints.
* [ ] Unified disparate concepts under a single, non-shifting terminological glossary.
* [ ] Converted option-based menu prose into deterministic default tracks + escape hatches.
</done>
