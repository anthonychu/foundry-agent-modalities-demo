# Present the Prompt Agents and Hosted Agents demo

Use this guide after completing the setup in the main README. The presentation takes about seven
minutes and uses the same fictional support case in both agent types.

## What the customer should understand

By the end of the demo, the customer should be able to say:

- “Prompt Agents let Foundry operate the harness while I configure the agent.”
- “Hosted Agents let me own the runtime code while Foundry manages the hosting platform.”
- “I should choose based on the control I need, not by counting features.”

Do not position one path as universally better. Both are production agent types in Microsoft Foundry.

## Prepare before the meeting

From the demo repository root:

### 1. Confirm the agents are available

```bash
cd deployment
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent doctor --output json
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent show \
  field-demo-support-triage-hosted \
  --output json
cd ..
```

The diagnostic result should have no failed checks, and the Hosted Agent status should be `active`.

### 2. Run the complete demo once

```bash
bash scripts/run-customer-demo.sh
```

Confirm that both paths return `P0`, score `8`, and the same four reason codes.

### 3. Arrange the windows

Open these files side by side in VS Code:

1. `sample_case.json`
2. `prompt_agent/instructions.md`
3. `deployment/src/agent-framework-agent-with-local-tools-responses/priority_rules.py`
4. `deployment/src/agent-framework-agent-with-local-tools-responses/main.py`

Keep a terminal open at the repository root. Increase the editor and terminal font size before
sharing the screen.

## Seven-minute presentation

### 0:00-0:45 — Introduce the decision

Show `sample_case.json`.

Suggested language:

> “Foundry has two agent types: Prompt Agents and Hosted Agents. I will send the same fictional
> support case through both. I am not comparing which one writes a nicer answer. I am showing where
> the business rule lives and who owns it.”

Briefly read the case fields. Tell the audience that the expected result is P0 with a score of 8.

### 0:45-2:30 — Show the Prompt Agent

Open `prompt_agent/instructions.md`.

Point out:

- the model, instructions, and tools define the agent;
- the priority rubric is readable configuration; and
- there is no customer-owned agent application or container.

Suggested language:

> “In the Prompt Agent path, the policy is in the instructions. I can create and version the agent
> through the portal, SDK, or REST, but Foundry operates the harness and runtime.”

Invoke only the Prompt Agent:

```bash
prompt_agent/.venv/bin/python prompt_agent/invoke.py
```

Call out the priority, score, reason codes, first response, and three actions. Do not spend time
comparing prose word by word.

### 2:30-4:45 — Show the Hosted Agent

Open `deployment/src/agent-framework-agent-with-local-tools-responses/priority_rules.py`.

Point out:

- the rule is a normal Python function;
- the score and thresholds are deterministic; and
- the code can be reviewed, versioned, tested, and released with the application.

Then open `deployment/src/agent-framework-agent-with-local-tools-responses/main.py` and show where
`calculate_case_priority` is registered as a local tool.

Suggested language:

> “In the Hosted Agent path, we own this policy as code. The model must call the function before it
> assigns priority. Foundry still gives us a managed deployment, endpoint, identity, scaling, and
> session infrastructure, but we own the application logic and dependencies.”

Invoke the deployed Hosted Agent:

```bash
cd deployment
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent invoke \
  field-demo-support-triage-hosted \
  --new-session \
  --new-conversation \
  'Triage this support case. Customer: Contoso Retail. Annual contract: $240,000. Production outage: 95 minutes. Regulated regions affected: 2. Renewal in: 21 days. Summarize the priority, reason codes, first response, and next three actions.'
cd ..
```

Again, call out the priority, score, and reason codes. Explain that the important difference is the
customer-owned function, not the generated wording.

### 4:45-6:15 — Compare responsibilities

Use this summary:

| Question | Prompt Agent | Hosted Agent |
| --- | --- | --- |
| Where is the triage policy? | Agent instructions | Python code |
| Who owns the agent-loop implementation? | Microsoft Foundry | Customer |
| Who operates the hosting platform? | Microsoft Foundry | Microsoft Foundry |
| Does the customer maintain runtime code? | No | Yes |
| Can the policy be a deterministic in-process function? | Use supported tools/integration patterns | Yes |
| Are endpoint and scaling managed? | Yes | Yes |

Suggested language:

> “Choose Prompt when instructions and supported tools are enough and you want Foundry to operate
> the loop. Choose Hosted when your requirement is to own and change the code, framework,
> dependencies, protocols, or runtime behavior.”

### 6:15-7:00 — Ask the customer

Close with these questions:

1. Which parts of your agent must be deterministic business code?
2. Do you need a specific framework, protocol, or dependency?
3. Do you want to operate that runtime logic, or would you prefer Foundry to operate it?

If the customer cannot identify a code-level control requirement, recommend starting with a Prompt
Agent and validating the scenario before taking on a Hosted application.

## Optional developer detail

For a developer audience, show that the Hosted rule has automated checks:

```bash
python3 -m unittest discover -s hosted_agent/tests -v
```

Explain it in plain language:

> “This confirms the customer-owned rule returns the same result even without a model. It is one
> reason to choose Hosted when deterministic policy code and software release controls matter.”

Skip this step for an executive or product audience.

## If a live call fails

Keep the comparison intact:

1. Show `prompt_agent/instructions.md` and the last validated Prompt output.
2. Show `priority_rules.py`, then run the local automated checks.
3. Show the last validated Hosted output or the Hosted Agent in the portal.
4. State the exact failure category: authentication, model quota, deployment, session startup, tool
   call, or network access.

Do not replace it with an unrelated canned agent and imply that it validates this comparison.

## After the meeting

If no additional customer or reviewer session needs the environment, follow the **Clean up** section
in the main README. Cleanup removes the disposable resource group and stops further resource costs.
