# Foundry agent modalities demo

This demo sends one fictional support case through two Microsoft Foundry Agent Service paths:

- **Prompt Agent:** a declarative agent whose triage rubric lives in instructions.
- **Hosted Agent:** an Agent Framework application whose triage rubric is a deterministic,
  unit-tested local Python tool.

The learning objective is **who owns the rule and harness**, not which generated paragraph looks
better.

## Status

- Four deterministic Hosted-rule tests: passed.
- Disposable Foundry project: provisioned in North Central US with `gpt-5.6-sol`.
- Live Prompt invocation: passed; Prompt Agent version 1 retained for inspection.
- Live Hosted invocation: passed locally and remotely; deterministic tool call verified in both.
- Remote Hosted deployment: active version 1, Responses protocol, direct code deployment.
- Evaluation-suite generation: submitted asynchronously.
- Cleanup: intentionally deferred until review/demo evidence is final; the disposable environment
  incurs costs until `azd down` is run from `deployment/`.

## Repository layout

```text
.
├── AGENTS.md
├── README.md
├── sample_case.json
├── prompt_agent/
│   ├── .env.example
│   ├── create_and_run.py
│   ├── instructions.md
│   └── requirements.txt
├── hosted_agent/
│   ├── .env.example
│   ├── main.py
│   ├── priority_rules.py
│   ├── requirements.txt
│   └── tests/
│       └── test_priority_rules.py
├── deployment/
│   ├── azure.yaml
│   └── src/agent-framework-agent-with-local-tools-responses/
│       ├── main.py
│       ├── priority_rules.py
│       └── requirements.txt
└── .vscode/
    ├── launch.json
    └── tasks.json
```

## Fictional case

```text
Customer: Contoso Retail
Annual contract: $240,000
Production outage: 95 minutes
Regulated regions affected: 2
Renewal in: 21 days
```

Expected deterministic Hosted result:

```json
{
  "priority": "P0",
  "score": 8,
  "reason_codes": [
    "OUTAGE_60",
    "STRATEGIC_CONTRACT",
    "REGULATED_IMPACT",
    "RENEWAL_30"
  ]
}
```

## 1. Test the customer-owned rule without Azure

Python 3.10 or later is sufficient for this pure rule test:

```bash
python3 -m unittest discover -s hosted_agent/tests -v
```

This is the key Hosted proof: the business rule can be versioned and tested independently from the
model.

## 2. Run the Prompt Agent path

Prerequisites:

- an authenticated Azure CLI session;
- an existing Foundry project;
- a deployed model; and
- permission to create Prompt Agent versions.

Set up locally:

```bash
cd prompt_agent
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
cp .env.example .env
```

Populate `.env` with the project endpoint and deployed model name, then run:

```bash
python create_and_run.py
```

The script creates a new Prompt Agent version, invokes the shared fictional case, and prints the
version plus response. By default it preserves the version so the presenter can inspect it. Set
`DELETE_AFTER_RUN=true` only for a disposable validation environment.

## 3. Run the Hosted Agent locally

Python 3.13 or later is required by the current Hosted code-deployment path:

The deployable source is under `deployment/src/agent-framework-agent-with-local-tools-responses/`.
Create a Python 3.13 virtual environment there, set its ignored `.env`, and run through `azd ai agent
run --no-client` from `deployment/`. On this machine, global `uv` could not reach
`files.pythonhosted.org`; pip through the configured Microsoft package proxy succeeded. Exclude the
global `uv` path or install requirements with pip if that network condition persists.

The local server listens on port 8088. Invoke it with the current `azd ai agent invoke --local`
flow, or press F5 from the repository root after the Hosted source virtual environment exists.

## 4. Deployment source

The `deployment/` project was initialized from the current official local-tools sample and then
customized for the support-triage case:

```text
https://github.com/microsoft-foundry/foundry-samples/blob/main/samples/python/hosted-agents/agent-framework/responses/02-tools/azure.yaml
```

The completed validation followed this sequence:

1. local run with `--no-client`;
2. local invoke with the shared case;
3. stop the local server;
4. deploy only after local success;
5. verify active status;
6. remote invoke; and
7. retain the temporary versions for review, then delete the project after the presentation.

All `azd` commands should set `AZURE_DEV_USER_AGENT=microsoft_foundry_skill` inline.

## Presenter proof points

| Prompt path | Hosted path |
| --- | --- |
| Rubric is readable configuration | Rubric is executable Python |
| No runtime application code | Customer owns code and dependencies |
| Fastest managed starting point | Deterministic logic has unit tests |
| Foundry operates the harness | Foundry hosts customer harness code |

## Known local prerequisites as of 2026-08-27

- `azd` 1.32.0 is installed; the workflow required an upgrade from 1.28.0.
- Official `azure.ai.agents` 1.0.0-beta.13 is installed. The private `mha-dev` extension source
  remains registered but was not used for this deployment.
- The bundled Foundry skill references preflight helper scripts that are absent from its installed
  package. The general dependency check succeeded, and `az account show` plus the live azd sample
  list succeeded. Treat the missing helper as a tooling issue, not demo validation.
- The deployment logs emit a non-blocking optional A365 instrumentation import warning and state
  that resilient background tasks are disabled. This demo does not claim crash-resilient work.

## Inspect and clean up

- Open the deployed Hosted Agent using the `playground_url` returned by `azd ai agent show`.
- Run `azd ai agent eval run` later if the generated evaluation suite is useful.
- When the demo no longer needs inspection, run `azd down` from `deployment/` to delete the
  disposable resource group and avoid ongoing cost.

## Sources

- <https://learn.microsoft.com/azure/foundry/agents/quickstarts/prompt-agent>
- <https://learn.microsoft.com/azure/foundry/agents/quickstarts/quickstart-hosted-agent>
- <https://learn.microsoft.com/azure/foundry/agents/quickstarts/quickstart-deploy-own-code>
- <https://learn.microsoft.com/azure/foundry/agents/concepts/hosted-agents>
- <https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents/agent-framework/responses/02-tools>
