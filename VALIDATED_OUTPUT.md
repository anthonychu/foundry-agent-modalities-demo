# Known-good demo output

Use this page only as a fallback when a live call is unavailable. Both paths were validated on
August 27, 2026 with `gpt-5.6-sol` and the Contoso Retail sample case.

The generated customer-response wording can change between runs. The priority, score, and reason
codes should remain the same.

## Prompt Agent

The Prompt Agent read the priority policy from its instructions and returned:

```text
Priority: P0
Score: 8
Reason codes:
- OUTAGE_60
- STRATEGIC_CONTRACT
- REGULATED_IMPACT
- RENEWAL_30

First response:
We recognize the production outage affecting Contoso Retail and are treating this as a P0
incident. We are initiating immediate investigation and will provide updates as progress is made.

Next actions:
1. Engage the incident-response team and assign an incident owner.
2. Begin diagnosis and recovery using the available incident evidence.
3. Establish a customer update cadence covering status, mitigation, and next steps.
```

## Hosted Agent

The Hosted Agent called the customer-owned `calculate_case_priority` Python function. The function
returned:

```json
{
  "policy": "fictional-demo-v1",
  "priority": "P0",
  "reason_codes": [
    "OUTAGE_60",
    "STRATEGIC_CONTRACT",
    "REGULATED_IMPACT",
    "RENEWAL_30"
  ],
  "rule_source": "hosted-python",
  "score": 8
}
```

The model then used that result to draft:

```text
First response:
We recognize the production outage affecting Contoso Retail and have assigned P0 priority.
Immediate incident response is underway, and we will provide updates as the investigation
progresses.

Next actions:
1. Engage the incident-response team and assign an incident owner.
2. Collect outage diagnostics, affected-service details, and relevant logs.
3. Establish a customer update cadence and track restoration progress.
```

## What this fallback demonstrates

- Both agents perform the same support-triage job.
- Both agents reach P0, score 8, and the same four reason codes.
- The Prompt Agent relies on a priority policy written in instructions.
- The Hosted Agent receives its score from customer-owned Python code before drafting its response.
- The comparison is about ownership and control, not small differences in generated wording.
