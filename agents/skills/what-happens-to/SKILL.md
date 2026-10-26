---
name: what-happens-to
description: >
  Traces the full lifecycle of a resource through the codebase when an abnormal
  scenario occurs. Finds where cleanup breaks down.

  TRIGGER when the user asks:
  - "$whathappens" (explicit trigger)
  - "what happens to [resource] when [scenario]?"
  - "trace [resource] lifecycle on [error path]"
  - "where does [resource] leak when [condition]?"

  Examples:
  - "what happens to the pool slot when admission fails?"
  - "what happens to the session counter when a retry fails?"
  - "what happens to the request when the backend goes unavailable?"
---

# What Happens To: Resource Lifecycle Tracer

Given a **resource** and an **abnormal scenario**, trace the resource's full lifecycle
through the codebase and identify where cleanup fails.

## Workflow
<procedure>

### Step 1: Parse the question

Extract:
- **Resource**: the thing being tracked (counter, index, context, handle, ref, etc.)
- **Scenario**: the abnormal condition (timeout, retry failure, admission reject, crash, unavailable, etc.)

If either is unclear, ask one clarifying question.

### Step 2: Trace the happy path

Find in the codebase:
1. **Creation**: where is the resource allocated/incremented/registered?
2. **Usage**: where is it read/passed/stored?
3. **Destruction**: where is it freed/decremented/deregistered?

Report these as a numbered lifecycle with file:line references.

### Step 3: Trace the abnormal path

Starting from the creation point, follow the code path when the scenario occurs:
1. What function/branch handles the error?
2. Does it reach the destruction point?
3. If not, where does the path diverge?

Look specifically for:
- Missing cleanup in catch/error blocks
- Early returns that skip deallocation
- Key mismatches (allocated with key A, freed with key B)
- Conditional cleanup that doesn't cover this case
- Resources handed off to another owner who doesn't know about them

### Step 4: Report

Output a structured report:

```
## Resource: [name]
## Scenario: [description]

### Happy path
1. Created at: [file:line] - [code snippet]
2. Used at: [file:line] - [code snippet]
3. Destroyed at: [file:line] - [code snippet]

### Abnormal path ([scenario])
1. [scenario] occurs at: [file:line]
2. Control flows to: [file:line]
3. ❌ Destruction at [file:line] is NOT reached because: [reason]
   - OR  - 
3. ✅ Destruction at [file:line] IS reached. Cleanup is correct.

### Verdict
[LEAK / CRASH / HANG / CORRECT]
[One sentence explaining the gap]

### Suggested fix
[Concrete suggestion: add cleanup at X, check condition Y, etc.]
```

### Step 5: Check for related resources

If the resource is part of a pair (e.g. allocation + counter), check if the
paired resource also leaks in this scenario. Report both.

</procedure>

## Quality checklist
<done>

- [ ] Every file:line reference is real (verified by reading the code)
- [ ] The happy path covers create → use → destroy
- [ ] The abnormal path starts from the same creation point
- [ ] The divergence point is identified precisely
- [ ] The verdict is one of: LEAK, CRASH, HANG, CORRECT
- [ ] If LEAK/CRASH/HANG: a concrete fix suggestion is provided
</done>
