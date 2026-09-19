# AuditSense AI Model Drift and Hallucination Control

## Goal
Reduce the risk of wrong audit findings, unstable AI summaries, and degraded model quality as the application moves from MVP to production use.

## What drift means in this project
For AuditSense, drift can happen in two ways:

| Drift type | Meaning | Example in AuditSense |
|---|---|---|
| Model drift | The model behavior changes over time | Responses become more generic or less consistent on invoice mismatch findings |
| Data drift | The input data changes in shape or quality | Bank statement format changes, invoice layouts vary more, or document text quality drops |

Both can create hallucinations or low-confidence outputs, which is risky in an audit workflow.

---

## Main hallucination risks

| Risk | Example | Impact |
|---|---|---|
| Unsupported claim | AI says a vendor invoice is fraudulent without enough proof | Can lead to incorrect audit conclusions |
| Wrong transaction matching | AI matches the wrong ledger entry to a document | Causes false risk flags |
| Generic summary | AI produces vague text not tied to actual evidence | Reduces trust in the output |
| Overconfident tone | Model sounds certain even when the evidence is weak | Creates compliance risk |
| Hidden data mismatch | AI ignores missing evidence or ambiguous values | Leads to incomplete review |

---

## Control strategy

### 1) Ground the model in real case data
Use structured inputs such as:
- ledger entries
- invoice totals
- dates
- vendor names
- document extracted text
- case status and prior review decisions

Require the model to answer only from the provided evidence. Avoid free-form assumptions not backed by transaction or document metadata.

### 2) Add human approval before final publishing
The AI output should always be a draft. A human reviewer must confirm:
- the issue is supported by evidence,
- the amount or date is correct,
- the summary is fact-based,
- the conclusion is safe to finalise.

This protects the audit process from model overconfidence.

---

## Drift monitoring controls

| Control | What to monitor | Trigger |
|---|---|---|
| Output quality review | AI summary consistency across similar cases | More than 10% of cases need manual rewrite |
| Evidence coverage check | Percentage of AI finding claims backed by document or ledger data | Below 90% supported evidence coverage |
| Prompt drift check | Change in model response style or structure over time | Higher rate of generic or vague findings |
| Data drift check | Change in document type mix, invoice format, or field quality | Increase in OCR failures or missing extracted values |
| Reviewer override rate | Percentage of AI suggestions rejected by auditors | More than 20% of recommendations rejected |

---

## Practical monitoring rules

| Rule | Example threshold | Action |
|---|---|---|
| Low evidence support | AI finding lacks document or ledger reference in 20% of cases | Review prompt and retrieval inputs |
| Rejected drafts rising | Rejection rate > 20% | Audit prompt quality and input structure |
| Generic output increase | Summaries too short or vague across multiple cases | Tighten prompt instructions and output format |
| OCR quality decline | Extracted fields missing or distorted | Review Document Intelligence configuration |
| Inconsistent risk scoring | Similar cases produce inconsistent findings | Revalidate prompt templates and examples |

---

## Hallucination reduction techniques

### Prompt controls
Use explicit instructions such as:
- only use facts from the provided ledger and document text
- no assumptions without evidence
- cite specific amounts, dates, or vendor names
- if evidence is missing, say "insufficient evidence" instead of guessing

### Output format control
Require a fixed output structure, for example:
- issue summary
- evidence used
- impacted amount
- confidence level
- reviewer notes

This makes responses easier to validate and reduces free-form hallucinated text.

### Retrieval and grounding
Before generating a finding, the app should pass in:
- transaction rows
- scanned document text
- relevant invoice fields
- case metadata
- prior approved comments

This reduces the chance that the model invents facts outside the case context.

### Confidence gating
If the model cannot find enough direct evidence, it should return a lower-confidence draft or request more information rather than make a bold claim.

---

## Data quality safeguards

| Data issue | Risk | Mitigation |
|---|---|---|
| Missing invoice fields | Wrong matching | Validate required fields before model call |
| OCR misread numbers | False variance | Cross-check extracted totals with ledger values |
| Duplicate documents | Confusing context | De-duplicate uploaded files by case |
| Inconsistent file types | Input noise | Normalize document types before analysis |
| Legacy transaction format | Wrong comparison | Standardize ledger schema before AI prompt |

---

## Review workflow for quality control

| Stage | Control |
|---|---|
| Before AI call | Validate raw input, document presence, and required fields |
| During AI call | Pass grounded case context only |
| After AI call | Check for unsupported statements and missing evidence |
| Before final save | Human reviewer approves or rejects the finding |
| After review | Log final decision and use for future evaluation |

---

## Drift response plan

| Trigger | Action |
|---|---|
| Rejection rate rises | Review prompts and retrain or tune examples |
| Cost or token use spikes | Inspect prompt size and context selection |
| OCR quality drops | Review document ingestion and extraction settings |
| Output pattern changes | Compare new outputs with historical approved findings |
| A new file type appears | Update document-processing rules and validation |

---

## Success measures
Track the following metrics to confirm the control model is working:
- AI rejection rate by auditor
- ratio of findings supported by evidence
- average token cost per approved case
- output quality score from reviewer feedback
- rate of unsupported claims
- rate of model timeout or throttling

---

## Summary
For AuditSense, the best approach is not just model monitoring but evidence-based AI governance. The system should:
- ground the model in real case and document data,
- require human approval,
- monitor token use, output quality, and reviewer rejection,
- detect data drift before it affects finding quality,
- and block unsupported claims by design.

This reduces hallucinations, improves trust, and keeps the AI output aligned with real audit evidence.
