---
name: feynman-method
description: Explains and tests understanding with the Feynman Technique, and conducts structured, source-grounded research inspired by feynman.is. Use when learning, teaching, simplifying complex topics, identifying knowledge gaps, producing research briefs or literature reviews, auditing claims, or designing replication plans.
---

# Feynman Method

Use one of two modes, or combine them when appropriate.

## Mode 1: Learn and Explain

Apply the Feynman Technique iteratively.

1. **Define the target**
   - State the exact concept or question.
   - Ask about the learner's level only when it materially changes the answer; otherwise assume an intelligent beginner.
2. **Explain simply**
   - Use plain language, short sentences, and concrete examples.
   - Avoid unexplained jargon. Define every necessary technical term at first use.
   - Prefer causal explanations: say what happens, why it happens, and what changes the outcome.
3. **Expose gaps**
   - Mark any step that relies on an assumption, vague phrase, missing mechanism, or unsupported claim.
   - Distinguish facts, interpretations, analogies, and uncertainty.
4. **Repair the gaps**
   - Revisit the difficult parts using first principles or reliable sources.
   - Replace circular explanations with mechanisms.
5. **Compress and refine**
   - Restate the concept more clearly without losing important qualifications.
   - Add an analogy only if it maps cleanly; explicitly state where the analogy breaks down.
6. **Check understanding**
   - End with 2–4 diagnostic questions or a small teach-back prompt when the user is learning.
   - Questions should test transfer and reasoning, not mere recall.

### Default explanation format

- **In one sentence**
- **Plain-language explanation**
- **Concrete example**
- **What is easy to misunderstand**
- **Knowledge check**

Adapt the format rather than forcing it when the user asks for a concise answer.

## Mode 2: Research and Verify

Use this mode for research briefs, literature reviews, technical comparisons, claim audits, and replication planning.

### Research rules

1. Convert the request into a precise research question and explicit scope.
2. Search from multiple angles; prioritize primary sources, papers, official documentation, datasets, and original code.
3. Separate:
   - established evidence,
   - plausible interpretation,
   - disagreement or uncertainty,
   - unanswered questions.
4. Trace important claims to sources. Do not use a citation unless it supports the nearby claim.
5. Check consequential or surprising claims against multiple independent sources when practical.
6. Report source limitations, date sensitivity, conflicts of interest, and missing evidence.
7. Never invent papers, authors, identifiers, quotations, results, or citations.

### Research brief

Produce:

- **Question and scope**
- **Simple answer**
- **What the evidence shows**
- **Mechanism or reasoning**
- **Counterevidence and uncertainty**
- **Open questions**
- **Sources**

### Literature review

Group work by findings or approaches rather than listing papers sequentially. Include:

- consensus,
- competing explanations,
- methodological differences,
- evidence quality,
- reproducibility concerns,
- open questions.

### Claim audit

For each material claim, report:

| Claim | Claimed evidence | What the source actually supports | Confidence | Caveats |
|---|---|---|---|---|

When code or data is available, compare the written methodology with the implementation. Distinguish absence of evidence from evidence of absence.

### Replication plan

Include:

- target claim and success criterion,
- required data, code, environment, and compute,
- baseline and controls,
- ordered procedure,
- metrics and statistical tests,
- confounders and failure modes,
- reproducibility artifacts,
- staged checkpoints before expensive or destructive actions.

Do not execute costly, destructive, or externally consequential experiments without explicit user authorization.

## Combined Workflow

For complex learning questions:

1. Give a plain-language provisional explanation.
2. Identify the claims or mechanisms most in need of verification.
3. Research those gaps using authoritative sources.
4. Correct and simplify the explanation based on the evidence.
5. State remaining uncertainty.
6. Test understanding with a teach-back or transfer question.

## Quality Bar

Before answering, verify that:

- a beginner can follow the central explanation,
- technical precision was not sacrificed for simplicity,
- jargon is defined,
- analogies are labeled and bounded,
- major claims are supported when research was requested,
- uncertainty is visible,
- the answer directly addresses the user's question.
