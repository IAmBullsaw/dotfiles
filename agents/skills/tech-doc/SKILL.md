---
name: tech-doc
description: "Turn rough notes, meeting output, investigation findings, or chat dumps into clear, structured technical documents. Applies technical writing principles automatically. TRIGGER when ANY of these match: - '$doc' (explicit trigger) - 'write this up', 'clean this up', 'make this a document' - 'turn these notes into', 'structure this', 'write a proposal' - 'document this', 'write up the findings', 'make this presentable' - 'polish this', 'formalize this', 'write a summary' - User pastes raw meeting notes or findings and asks for a document Not for: writing code (just write it), creating presentations (use Marp directly), daily work log (say 'log')."
---

# Technical Document Writer

Turn messy input into clear, structured technical documents.

<context>

## Principles

These are non-negotiable. Apply to every document.

1. **Lead with why.** First paragraph answers: why does this document exist? What triggered it?
2. **Summary before detail.** Numbered list of key points at the top. A reader who stops after the summary still gets the message.
3. **One purpose per section.** Don't mix proposal with background with implementation detail.
4. **Concrete over abstract.** Show example output, not "the output will contain relevant information." Show the command, not "a command will be available."
5. **Active voice, present tense.** "The command lists all UEs" not "All UEs will be listed by the command."
6. **No filler.** Cut "it should be noted that", "it is important to", "as mentioned above." If it's important, just say it.
7. **Tables for structured comparisons.** Prose for reasoning. Bullet points for lists. Code blocks for commands and output.
8. **Open questions explicit.** If something is undecided, say so in a dedicated section. Don't bury uncertainty in prose.

## Document types

Detect the type from context. Each has a different structure.

### Proposal (recommending a change)
```
Why now (1-2 sentences, the trigger)
Summary (numbered items)
Current state (what exists today, be specific)
What others do (reference implementations, if applicable)
Items (one section per proposal item, each with: what, why, example)
Open questions (what needs deciding)
Appendices (detail for those who want to dig deeper)
Sources (where the information came from)
```

### Findings (investigation results)
```
TL;DR (3-5 lines)
What we looked at
What we found (grouped by topic, not by chronology)
What it means (implications)
What to do next
Sources
```

### Meeting notes (structured capture)
```
Date, attendees, context
Decisions made
Action items (who, what, when)
Discussion points (grouped by topic)
Open questions
```

### Knowledge reference (reusable information)
```
What this covers
Quick reference (table or list, the 80% case)
Detail sections (one per topic)
Gotchas (what a reader might miss)
Sources
```

</context>

<procedure>

## Workflow

### 1. Assess input

Read the raw input. Classify:
- What type of document is needed? (proposal / findings / meeting notes / reference)
- Who is the audience? (team discussion, broader org, future self)
- What's the core message? (one sentence)

### 2. Extract structure

From the raw input, identify:
- Key facts and decisions
- Examples and concrete data (commands, output, code, numbers)
- Open questions and uncertainties
- Sources and references

### 3. Draft

Write the document following the type-specific structure above.

Apply these rules during drafting:

**Conciseness checks:**
- ❌ "It is worth noting that the system currently has 6 commands" → ✅ "6 commands exist today"
- ❌ "In order to address this gap, we propose" → ✅ "Fix:"
- ❌ "This would allow us to be able to" → ✅ "This enables"

**Specificity checks:**
- ❌ "Several commands" → ✅ "6 commands" (use the number)
- ❌ "The output will show relevant information" → ✅ show the actual output
- ❌ "A file will be created" → ✅ show the file path and example content

**Structure checks:**
- Every section longer than 5 lines should have a clear first sentence stating what the section covers
- If a section has both "what" and "why", lead with "what"
- If comparing options, use a table
- If listing more than 3 items, use bullets or a table, not prose

### 4. Review

Before presenting, check:
- [ ] Can a reader get the full picture from the summary alone?
- [ ] Does every section earn its place? (Would removing it lose information?)
- [ ] Are examples concrete? (Actual commands, actual output, actual file paths)
- [ ] Are open questions in their own section, not buried in prose?
- [ ] Is the document front-loaded? (Most important information first in every section)
- [ ] No filler phrases? (Search for "it should be noted", "it is important", "in order to", "it is worth")

### 5. Output

Write the document to the location the user specifies (default: `~/Code/vault/`).
State what was written and where.

</procedure>

<done>

## Quality bar

A good document:
- Can be skimmed in 2 minutes and understood in 5
- Has no section a reader would skip
- Contains at least one concrete example per major point
- Makes open questions and uncertainties explicit
- Lists its sources

A bad document:
- Requires reading everything to understand anything
- Has sections that exist "for completeness" but add no information
- Uses abstract language where concrete examples exist
- Hides uncertainty in hedging language ("perhaps", "it might be worth considering")
- Has no sources (reader can't verify or dig deeper)

</done>