---
name: transparent-reasoning-framework
type: reference
description: "Reference: templates for transparent, verifiable analysis: confidence declaration, evidence, analysis, conclusion, assumptions. Use when doing any non-trivial analysis or design that the user must be able to follow and challenge."
---

# Transparent Reasoning Framework

Templates and patterns for making AI analysis more transparent and verifiable.

## Analysis Template

### 1. Confidence Declaration
```
Confidence: [High/Medium/Low/Uncertain]
Verification status: [What I've checked vs what I'm assuming]
```

### 2. Evidence Hierarchy
```
Primary evidence (strongest):
- [Direct observations, tool outputs, verified facts]

Secondary evidence (supporting):
- [Patterns, correlations, indirect indicators]

Assumptions (need verification):
- [Inferences, extrapolations, unverified claims]
```

### 3. Reasoning Chain
```
Evidence A → Analysis B → Conclusion C
Where: [Explain each step and why it follows]
```

### 4. Alternative Explanations
```
Other possibilities:
- [Alternative 1]: [Why less likely]
- [Alternative 2]: [Why ruled out]
- [Alternative 3]: [Cannot rule out, needs investigation]
```

## Circuit-Style Reasoning

### For bug investigation
```
Symptom: [What we observe]
↓
Trigger: [What initiated the sequence]
↓
Mechanism: [How the failure propagated]
↓
Root Cause: [Underlying defect]
```

### For Code Debugging
```
Error: [What failed]
↓
Context: [When/where it failed]
↓
State: [System state at failure]
↓
Cause: [Why that state caused failure]
```

## Verification Checkpoints

### Before Analysis
- [ ] What specific question am I answering?
- [ ] What evidence do I have access to?
- [ ] What are my knowledge limitations here?

### During Analysis
- [ ] Am I pattern matching or actually reasoning?
- [ ] Can I trace my logic step by step?
- [ ] What would prove me wrong?

### After Analysis
- [ ] What's my confidence level and why?
- [ ] What can the user verify independently?
- [ ] What needs further investigation?

## Communication Patterns

### High Confidence
"I've verified X by checking Y. This shows Z because [reasoning]. You can confirm this by [verification method]."

### Medium Confidence
"Based on X evidence, it appears Y is the cause. The reasoning is [chain]. However, this assumes Z, which should be verified."

### Low Confidence
"The symptoms suggest X might be related to Y. This is based on [limited evidence]. Alternative explanations include Z. We need to check [specific items] to be more certain."

### Uncertain
"I don't have enough information to determine the cause. The key unknowns are [list]. I'd recommend investigating [specific areas] first."

## Red Flag Phrases to Avoid

- "Obviously..." (not obvious to user)
- "Clearly..." (may not be clear)
- "This must be..." (overconfident)
- "It's probably..." (vague confidence)
- "The issue is..." (without showing reasoning)

## Green Flag Phrases to Use

- "I've verified that..."
- "The evidence shows..."
- "Based on X, Y, and Z..."
- "You can confirm this by..."
- "I'm uncertain about X because..."
- "This assumes Y, which we should check..."

## Escalation Triggers

When to explicitly flag limitations:
- Analysis requires domain knowledge I may lack
- Multiple plausible explanations exist
- Evidence is circumstantial or incomplete
- Stakes are high (production systems, safety-critical)
- User needs to make important decisions based on analysis