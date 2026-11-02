> **Archived copy.** This is the upstream README, moved here unchanged except for links. Run its commands from the repository root. The current entry point is the [root README](../README.md).

# Compare Prompt Agents and Hosted Agents

> **Sample status:** This is an unsupported demonstration, not Microsoft product documentation,
> support policy, SLA, roadmap commitment, or guarantee. The support scenario and scoring policy are
> fictional. Validate current product availability, prerequisites, and pricing before using it.

This demo compares two implementations of a support-triage agent in Microsoft Foundry Agent Service.
The agent reads customer and incident facts, applies four scoring rules, assigns a support priority,
drafts a first response, and recommends three next actions:

- A **Prompt Agent** keeps the triage policy in agent instructions. Microsoft Foundry runs the
  software loop that coordinates the model and tools, so there is no agent application to deploy or
  maintain.
- A **Hosted Agent** keeps the same triage policy in Python code. You own the code and its
  dependencies; Microsoft Foundry deploys, hosts, scales, and exposes it through a managed endpoint.

The **priority policy**—also called a *scoring rubric* in some source files—awards points for a long
outage, strategic contract, regulated-region impact, and near-term renewal. Short **reason codes**
identify which rules contributed to the result. The values and thresholds are fictional, but the
design choice is realistic.

The demo helps a customer answer one question:

> **Do we need to own and change the code that controls this decision, or do we want Foundry to
> operate the agent from configuration?**

Both agents receive the same input and return the same priority. The Prompt Agent keeps the policy in
instructions; the Hosted Agent calls customer-owned Python code. The difference is ownership, not
which response sounds better.

The portal supports both paths, with an important distinction:

- **Prompt Agent:** create, configure, edit, version, and test the agent in the Foundry portal—or
  define it through SDK/REST for an automated workflow.
- **Hosted Agent:** build and edit the application in code, deploy it to Foundry, then use the portal
  playground to invoke, trace, evaluate, monitor, and optimize the deployed agent. Hosted code is not
  edited in the agent-building UI.

This repository creates the Prompt Agent with code so setup is repeatable. That is a demo choice,
not a Prompt Agent limitation.

## What you will show

```text
                              Microsoft Foundry Agent Service

  Same support case ──┬──> Prompt Agent ──> Policy in instructions ──> P0
                      │
                      └──> Hosted Agent ──> Policy in Python code ───> P0
```

The fictional case is deliberately simple:

```text
Customer: Contoso Retail
Annual contract: $240,000
Production outage: 95 minutes
Regulated regions affected: 2
Renewal in: 21 days
```

Both paths should return:

- priority `P0`;
- score `8`; and
- reason codes `OUTAGE_60`, `STRATEGIC_CONTRACT`, `REGULATED_IMPACT`, and `RENEWAL_30`.

The score comes from four rules: three points for a 60-minute outage, two for a $200,000 contract,
two for regulated-region impact, and one for a renewal within 30 days. The values and thresholds are
not Microsoft support policy.

## Before you begin

You need:

- macOS or Linux;
- Python 3.13 or later;
- Azure CLI, signed in with `az login`;
- Azure Developer CLI 1.32 or later, signed in with `azd auth login`;
- an Azure subscription where you can create a resource group and Microsoft Foundry resources; and
- available quota for `gpt-5.6-sol` in North Central US.

This sample was validated on August 27, 2026 with `gpt-5.6-sol` version `2026-07-09`. Model and
region availability changes over time. Before provisioning, check the current
[model availability table](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure-region-availability)
and update the model name, version, deployment name, and region in `deployment/azure.yaml` when
using another compatible chat model.

The validated Python dependencies are pinned in the requirements files. The Python
`agent-framework-foundry-hosting` integration is prerelease even though the Hosted Agents service is
generally available, so review dependency updates before adopting this sample.

Install the current Foundry Agent extension:

```bash
azd extension install azure.ai.agents --source azd
azd version
azd extension list
```

Confirm that `azd` is version 1.32 or later and that `azure.ai.agents` is version
`1.0.0-beta.13` or later. If the extension is already installed from another registered source,
replace it explicitly with the public `azd` build:

```bash
azd extension install azure.ai.agents --source azd --force
```

> **Cost notice:** Setup creates a Foundry project, model deployment, Prompt Agent, and Hosted Agent.
> Model calls and Hosted Agent sessions can incur charges. Complete the cleanup section after the
> demo.

## Set up the demo

### 1. Open the demo folder

Clone or download this repository, then change to its root folder:

```bash
cd foundry-agent-modalities-demo
```

### 2. Optional but recommended: check the local policy code

The Hosted Agent uses a small Python function to calculate priority. Run its automated checks before
creating cloud resources:

```bash
python3.13 -m unittest discover \
  -s deployment/src/agent-framework-agent-with-local-tools-responses/tests \
  -v
```

Why this check exists: the Hosted path is useful when a business rule must return the same result for
the same input, be versioned, and be independently testable. The check confirms that the rule returns
the expected score without relying on a model. It is preparation evidence; it does not need to be
part of a normal customer presentation.

### 3. Create an azd environment

Choose a unique environment name. The example below uses `foundry-modalities-demo`:

```bash
cd deployment
azd env new foundry-modalities-demo
azd env set AZURE_SUBSCRIPTION_ID "$(az account show --query id -o tsv)"
azd env set AZURE_LOCATION northcentralus
azd env set AZURE_AI_MODEL_DEPLOYMENT_NAME gpt-5.6-sol
```

If the environment already exists, select it instead:

```bash
azd env select foundry-modalities-demo
```

### 4. Provision the Foundry project

```bash
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd provision --no-state --no-prompt
```

Provisioning creates a resource group, Foundry account and project, `gpt-5.6-sol` deployment, and the
supporting resources required for Hosted Agents.

Verify the project:

```bash
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent doctor --output json
```

Before the Hosted Agent is deployed, the diagnostic result should show that the project is reachable
and that the only remaining agent action is deployment.

### 5. Create the local environment files

Return to the repository root and run the helper:

```bash
cd ..
bash scripts/configure-local-env.sh
```

The helper copies the provisioned project endpoint and model deployment name into ignored `.env`
files for the Prompt and local Hosted paths. It does not copy credentials or tokens.

### 6. Install the Prompt Agent dependencies

```bash
python3.13 -m venv prompt_agent/.venv
prompt_agent/.venv/bin/python -m pip install -r prompt_agent/requirements.txt
```

### 7. Create and test the Prompt Agent

```bash
prompt_agent/.venv/bin/python prompt_agent/create_and_run.py
```

This command:

1. creates a Prompt Agent version named `field-demo-support-triage-prompt`;
2. sends the fictional case;
3. prints the response; and
4. preserves the version so it can be shown in the Foundry portal.

Expect `P0`, score `8`, and the four reason codes listed earlier.

Run `create_and_run.py` once during setup. Do not rerun it before later presentations. Use
`prompt_agent/invoke.py` when you want to check only the existing Prompt Agent, or use
`scripts/run-customer-demo.sh` for the normal paired Prompt-and-Hosted preflight. Neither command
creates another agent version.

You can now open **Build → Agents** in the Foundry portal and select
`field-demo-support-triage-prompt`. The playground shows the editable model, instructions, tools,
knowledge, memory, and guardrails beside the chat experience. Do not make a change yet; the customer
demo uses the validated version.

### 8. Install the Hosted Agent dependencies

```bash
python3.13 -m venv deployment/src/agent-framework-agent-with-local-tools-responses/.venv
deployment/src/agent-framework-agent-with-local-tools-responses/.venv/bin/python \
  -m pip install \
  -r deployment/src/agent-framework-agent-with-local-tools-responses/requirements.txt
```

The deployable Hosted Agent source is in
`deployment/src/agent-framework-agent-with-local-tools-responses/`.

### 9. Test the Hosted Agent locally

Start the local server from the `deployment` folder:

```bash
cd deployment
source src/agent-framework-agent-with-local-tools-responses/.venv/bin/activate
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent run --no-client
```

Wait until the terminal says that the agent is ready and is running on port 8088. Leave that terminal
open.

In a second terminal, run:

```bash
cd foundry-agent-modalities-demo/deployment
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent invoke \
  field-demo-support-triage-hosted \
  --local \
  --new-session \
  --new-conversation \
  'Triage this support case. Customer: Contoso Retail. Annual contract: $240,000. Production outage: 95 minutes. Regulated regions affected: 2. Renewal in: 21 days. Summarize the priority, reason codes, first response, and next three actions.'
```

Expect the same priority, score, and reason codes as the Prompt Agent. The local server log should
show one call to `calculate_case_priority`.

Stop the local server with **Control+C** before continuing.

### 10. Deploy and test the Hosted Agent

From the `deployment` folder:

```bash
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd deploy \
  field-demo-support-triage-hosted \
  --no-prompt
```

Verify that the new version is active:

```bash
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent show \
  field-demo-support-triage-hosted \
  --output json
```

Print the direct portal links for both agents:

```bash
cd ..
bash scripts/show-portal-links.sh
```

Open both links. The Prompt Agent page is an authoring and testing surface. The Hosted Agent page is
a testing and operations surface for code that was deployed from this repository.

Finally, run the same case against both deployed paths as a preflight:

```bash
bash scripts/run-customer-demo.sh
```

The helper invokes the existing Prompt Agent and the deployed Hosted Agent back to back. It does not
create another agent version.

## Present the demo

Use [original-CUSTOMER_DEMO.md](original-CUSTOMER_DEMO.md) for the exact presentation sequence and suggested language.
It is designed for a seven-minute customer conversation and includes a fallback if a live call fails.

The recommended presentation is **portal-first**:

At a high level:

1. Show the single customer scenario in `sample_case.json`.
2. Open the Prompt Agent in the Foundry portal. Show that its model, instructions, tools, knowledge,
  memory, and guardrails are configurable there, then test it in the playground.
3. Open `deployment/src/agent-framework-agent-with-local-tools-responses/priority_rules.py` and
   explain that the Hosted Agent policy is customer-owned code.
4. Open the Hosted Agent in the Foundry portal. Explain that its code is edited and deployed outside
  the portal, then test it in the playground and show its logs/traces/monitoring surfaces.
5. Close by asking whether the customer needs to own the runtime rule.

Do not present the demo as a quality contest. Both paths are expected to reach the same decision.

## Clean up

Cleanup deletes the disposable Azure resource group and all agents, model deployments, sessions, and
telemetry in it. It does not delete the source code.

First capture the resource group name, then delete the resources:

```bash
cd deployment
RESOURCE_GROUP="$(azd env get-value AZURE_RESOURCE_GROUP)"
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd down --force --purge
```

Confirm that the resource group is gone:

```bash
az group exists --name "$RESOURCE_GROUP"
```

The command should return `false`.

Optionally remove local generated state:

```bash
cd ..
rm -rf prompt_agent/.venv
rm -rf deployment/src/agent-framework-agent-with-local-tools-responses/.venv
rm -f prompt_agent/.env
rm -f deployment/src/agent-framework-agent-with-local-tools-responses/.env
```

## Troubleshooting

### `uv` cannot download dependencies

Install the requirements with the virtual environment's `pip`, as shown in the setup steps. If
`azd ai agent run` still selects an incompatible global `uv`, adjust `PATH` for that command or use
the documented `pip` setup before trying again.

### The Hosted Agent is not deployed

Run:

```bash
cd deployment
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent doctor --output json
```

Follow the first failed check. If every project check passes and only the agent is missing, run the
deployment step again.

### The model cannot be found

Confirm that both values refer to the same deployment:

```bash
cd deployment
azd env get-value AZURE_AI_MODEL_DEPLOYMENT_NAME
azd env get-value FOUNDRY_PROJECT_ENDPOINT
```

Then rerun `scripts/configure-local-env.sh` from the repository root.

### The live demo fails in front of the audience

Do not switch to an unrelated demo. Use the fallback in [original-CUSTOMER_DEMO.md](original-CUSTOMER_DEMO.md): show
the two source files, the last validated output, and the exact failure category.

## Project structure

```text
foundry-agent-modalities/
├── README.md                 # Setup, run, and cleanup quickstart
├── CUSTOMER_DEMO.md          # Seven-minute customer presentation script
├── VALIDATED_OUTPUT.md       # Known-good fallback output for an offline presentation
├── sample_case.json          # Fictional input shared by both paths
├── scripts/
│   ├── configure-local-env.sh
│   ├── run-customer-demo.sh
│   └── show-portal-links.sh
├── prompt_agent/
│   ├── instructions.md       # Policy expressed as Prompt Agent configuration
│   ├── create_and_run.py     # One-time create and validation
│   └── invoke.py             # Reusable presentation invocation
└── deployment/
    ├── azure.yaml            # Disposable Foundry project and Hosted Agent definition
    └── src/agent-framework-agent-with-local-tools-responses/
        ├── main.py           # Hosted Agent and local tool registration
      ├── priority_rules.py # Customer-owned deterministic policy
      └── tests/            # Checks the exact policy module that is deployed
```

## License and provenance

The Hosted Agent deployment scaffold was initialized from the public
[Microsoft Foundry Agent with Local Tools sample](https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents/agent-framework/responses/02-tools)
and customized for this fictional triage scenario. The upstream sample is licensed under the MIT
License. This repository retains that license in [LICENSE](../LICENSE).

## Learn more

- <https://learn.microsoft.com/azure/foundry/agents/overview>
- <https://learn.microsoft.com/azure/foundry/agents/concepts/development-lifecycle>
- <https://learn.microsoft.com/azure/foundry/concepts/concept-playgrounds>
- <https://learn.microsoft.com/azure/foundry/agents/quickstarts/prompt-agent>
- <https://learn.microsoft.com/azure/foundry/agents/quickstarts/quickstart-hosted-agent>
- <https://learn.microsoft.com/azure/foundry/agents/concepts/hosted-agents>
