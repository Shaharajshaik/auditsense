# AuditSense Monitoring and Alerting Strategy

## Goal
Separate the monitoring model into three areas so operational alerts, user-facing issues, and AI cost/control problems are handled differently.

## SLI and SLO definitions
For this MVP, the team should define performance using measurable service indicators.

| Area | SLI | SLO |
|---|---|---|
| Infrastructure | App uptime, SQL availability, storage success rate | 99% uptime for App Service and 99.9% for critical data services |
| Application | Successful case analysis requests, approval workflow completion time | 95% of requests complete successfully; 90% of cases analyzed within 30 seconds |
| AI usage | AI success rate, token efficiency, budget control | 99% of AI calls succeed without throttling; token use within forecasted daily budget |

### Example service targets
- App Service availability: 99%
- Case analysis success rate: 95%
- AI call success rate: 99%
- p95 analysis latency: < 30 seconds for standard cases
- document upload success: > 99%
- audit case approval completion: 90% within 2 minutes after draft generation

---

## 1) Infrastructure alerts
These alerts protect the Azure platform and host availability.

| Alert | Real example | Trigger | Severity | Owner |
|---|---|---|---|---|
| App unavailable | Auditor cannot open the case list | App Service availability < 99% for 5 minutes | Critical | Platform team |
| App API failing | Analyze Case endpoint returns 500 errors | HTTP 5xx > 5% in 10 minutes | Critical | App team |
| Database unavailable | Case cannot be saved or reopened | SQL connection failures or DB unavailable | Critical | Database team |
| Storage failure | Uploaded PDF cannot be saved | Blob upload failures > 3 in 10 minutes | Warning | Platform team |
| Secret access failure | App cannot access DB or model credentials | Key Vault access failures > 1 in 10 minutes | Critical | Security/platform |
| Host resource pressure | App slows during the audit review day | CPU or memory > 85% for 15 minutes | Warning | Platform team |

---

## 2) Application alerts
These alerts protect the business workflow and user experience.

| Alert | Real example | Trigger | Severity | Owner |
|---|---|---|---|---|
| Case review blocked | Auditor cannot analyze an active case | 3 consecutive failed analysis requests in 10 minutes | Critical | App team |
| Document upload issue | PDF statement is rejected | Upload failure rate > 10% in 30 minutes | Warning | App team |
| OCR extraction issue | Invoice text is missing | Document Intelligence failures > 2 in 15 minutes | Warning | Processing team |
| Case stuck in progress | Case remains open without final decision | Case older than 24 hours with no final status | Warning | Audit operations |
| Approval workflow failure | Auditor cannot approve or reject draft finding | Approval API error rate > 2% in 15 minutes | Warning | App team |
| Slow user interaction | App still responds but feels unusable | p95 page load > 8 seconds for 3 checks | Warning | App team |

---

## 3) AI usage alerts
These alerts protect model availability, quota, budget, and per-user cost control.

| Alert | Real example | Trigger | Severity | Owner |
|---|---|---|---|---|
| Token usage spike | Team runs multiple large case summaries in one hour | Prompt + completion tokens > 150% of normal daily baseline | Warning | AI owner |
| Model quota nearing limit | New case analysis fails because quota is exhausted | Remaining quota < 20% for 1 hour | Critical | AI owner |
| Rate limit / throttling | AI returns 429 or 503 responses | More than 2 throttling events in 15 minutes | Critical | AI owner |
| High latency from AI | Draft finding takes too long | p95 model latency > 30 seconds across 3 calls | Warning | AI owner |
| Per session cost anomaly | One audit session uses unusually high tokens | Session cost > $0.50 or > 3x average session cost | Warning | Finance + AI owner |
| Daily AI budget threshold | Team reaches budget before month end | Daily AI spend > 80% of forecasted budget | Warning | Finance + AI owner |
| Cost per case spike | Similar cases use much more AI than expected | Cost per case > 2x baseline trend | Warning | AI owner |

---

## AI cost and quota controls

| Control | Example rule | Purpose |
|---|---|---|
| Token usage alert | Trigger when average tokens per case exceed expected baseline by 50% | Detects runaway prompt size or inefficient calls |
| Quota alert | Trigger when remaining Azure OpenAI quota is below 20% | Prevents production outage due to exhaustion |
| Throttling alert | Trigger on 429/503 responses | Detects service pressure before all users are blocked |
| Session cost alert | Trigger if a session exceeds a cost threshold | Helps stop excessive or repeated AI use |
| Budget alert | Trigger at 70%, 85%, 100% of budget | Keeps monthly AI cost under control |

---

## Example Azure alert rules for AI

| Metric | Threshold | Response |
|---|---|---|
| Prompt tokens per request | > 20,000 tokens | Review prompt length and context size |
| Completion tokens per request | > 5,000 tokens | Reduce output size or truncate context |
| Total monthly cost | > 80% of budget | Notify finance and AI owner |
| 429 throttling count | > 2 in 15 minutes | Investigate quota and retry logic |
| p95 model latency | > 30 seconds | Review prompt design and instance health |
| Cost per case | > 2x normal baseline | Review model usage and prompt efficiency |

---

## Alert routing by category

| Category | Route to | Response expectation |
|---|---|---|
| Infrastructure | Platform team | Immediate fix |
| Application | App team | Restore workflow |
| AI | AI owner + finance | Review quota, cost, and model performance |

---

## Monitoring dashboard layout

| Dashboard section | Metrics |
|---|---|
| Infrastructure | App uptime, SQL health, storage errors, Key Vault failures |
| Application | API errors, upload success ratio, workflow stuck cases, approval failures |
| AI | Tokens used, quota remaining, throttling events, latency, cost per session |

---

## Why this split matters
A single generic alert is not enough for an audit platform. The team needs different actions for different failures:
- infrastructure alerts fix Azure health
- application alerts restore business workflow
- AI alerts protect budget, quota, latency, and model reliability

This is especially important because AI cost can increase quickly when many cases are analyzed in a short time, while application reliability must still protect the human review process.
