# Present the Prompt Agents and Hosted Agents demo

Use this guide after completing the setup in the main README. The presentation takes about seven
minutes and compares two ways to build the same support-triage agent in Microsoft Foundry.

## Demo overview

The agent acts as the first responder for an incoming production-support case. It receives a few
facts about the customer and incident, then it:

1. evaluates the case against a priority policy;
2. assigns a priority and explains which rules were triggered;
3. drafts a short first response to the customer; and
4. recommends the next three actions for the support team.

The **priority policy** is a simple set of four scoring rules. It is also called a *scoring rubric*
in some source files and agent output. For this demo, both terms mean the same thing:

| Case condition | Points | Reason code |
| --- | ---: | --- |
| Production outage is at least 60 minutes | 3 | `OUTAGE_60` |
| Annual contract is at least $200,000 | 2 | `STRATEGIC_CONTRACT` |
| One or more regulated regions are affected | 2 | `REGULATED_IMPACT` |
| Renewal is within 30 days | 1 | `RENEWAL_30` |

The points are added together. A score of 7 or more is P0, 4-6 is P1, 2-3 is P2, and 0-1 is P3.
The **reason codes** are short labels that show exactly which conditions contributed to the score.

The sample Contoso Retail case triggers all four rules, for a score of 8 and priority P0. The values,
thresholds, and response process are fictional and are used only to make the agent behavior easy to
follow.

These are the four fields the scoring policy evaluates:

| Input from the case | Demo value |
| --- | ---: |
| Annual contract value | $240,000 |
| Production outage duration | 95 minutes |
| Regulated regions affected | 2 |
| Days until renewal | 21 |

The customer name and requested output are additional context, but they do not add points.

The two agents perform that same job differently:

- In the **Prompt Agent**, the four scoring rules are written in the agent instructions. Foundry
  operates the software loop that sends context to the model, handles any tools, and continues until
  the agent returns a response.
- In the **Hosted Agent**, the four scoring rules are implemented as a Python function. The model is
  instructed to call that function before drafting its response. The customer owns this application
  code, while Foundry operates the managed hosting platform around it.

That software loop is sometimes called the **agent harness**. The point of the demo is to make the
ownership choice concrete: should the scoring policy remain managed agent configuration, or does the
customer need to own it as application code?

The Foundry portal is valuable in both paths, but it plays a different role:

| Portal experience | Prompt Agent | Hosted Agent |
| --- | --- | --- |
| Create the agent | Create directly in the portal, or use SDK/REST | Build in code, then deploy to Foundry |
| Change agent behavior | Edit model, instructions, tools, knowledge, memory, and guardrails in the agent-building UI | Change the source code and deploy a new version; Hosted code is not edited in the agent-building UI |
| Try the agent | Chat in the Agents playground | Chat with the deployed agent in the Agents playground |
| Improve and operate | Save versions, inspect traces, evaluate, monitor, and optimize | Inspect details and logs, trace, evaluate, monitor, and optimize |

This is an important part of the comparison. **Prompt Agents offer a portal-first authoring path as
well as SDK and REST. Hosted Agents offer code-first authoring plus a managed portal experience for
testing and operations after deployment.**

## What the customer should understand

By the end of the demo, the customer should be able to say:

- “Prompt Agents let Foundry operate the agent loop while I configure the agent.”
- “Hosted Agents let me own the runtime code while Foundry manages the hosting platform.”
- “I can test and operate both from the Foundry portal, but I edit only the Prompt Agent there.”
- “I should choose based on the control I need, not by counting features.”

Do not position one path as universally better. Both are production agent types in Microsoft
Foundry, and both should reach the same P0 decision in this demo.

## Prepare before the meeting

Complete the setup in the main README first. In particular, run `create_and_run.py` once to create the
Prompt Agent, then complete the separate Hosted Agent deployment step. During later presentations,
`invoke.py` calls the existing Prompt Agent; it does not create another version.

Before presenting for the first time, read the **If a live call fails** section near the end of this
guide and keep `VALIDATED_OUTPUT.md` open as the fallback.

Start from the demo repository root. The customer presentation needs one terminal. Every command
below either runs from the root or returns there with `cd ..` before the next step.

### 1. Confirm the agents are available

```bash
cd deployment
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent doctor --output json
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent show \
  field-demo-support-triage-hosted \
  --output json
cd ..
```

The first command checks the local configuration, authentication, project access, and deployed agent.
It should report no failed checks. The second command reads the deployed Hosted Agent directly; its
`status` should be `active`, which means it is ready to receive requests.

### 2. Run a preflight before each customer meeting

From the repository root:

```bash
bash scripts/run-customer-demo.sh
```

Confirm that both paths return `P0`, score `8`, and the same four reason codes.

This script is safe to run before every presentation: it invokes the existing Prompt and Hosted
Agents and does not create new agent versions. It does create fresh Hosted session/conversation
state and makes billable model calls. Use `prompt_agent/invoke.py` only when troubleshooting or
checking the Prompt Agent by itself; it is not a replacement for the paired preflight.

### 3. Open both agents in the Foundry portal

From the repository root, print the prepared portal links:

```bash
bash scripts/show-portal-links.sh
```

Open both links in separate browser tabs. Confirm:

- the Prompt Agent page shows an editable model, instructions, tools, knowledge, memory, and
  guardrails beside the playground; select the top-level **Playground** tab and its inner **Chat**
  tab; and
- the Hosted Agent page shows the deployed version, code asset, protocols, Chat playground, log
  stream, traces, monitor, and evaluation surfaces; select the top-level **Playground** tab and its
  inner **Chat** tab.

Do not edit or save anything during the customer presentation. The existing versions are already
validated.

### 4. Arrange the windows

Prepare these tabs in presentation order:

1. VS Code: `sample_case.json`
2. Browser: the Prompt Agent playground
3. VS Code: `deployment/src/agent-framework-agent-with-local-tools-responses/priority_rules.py`
4. VS Code: `deployment/src/agent-framework-agent-with-local-tools-responses/main.py`
5. Browser: the Hosted Agent playground

Keep one terminal open at the repository root; no second terminal or local server is needed for the
customer presentation. Increase the editor and terminal font size before sharing the screen. The
priority-rules file shows the scoring calculation. The main file shows how that calculation is
registered as a tool the Hosted Agent must call.

## Seven-minute presentation

### 0:00-1:15 — Set up the scenario and decision

Show `sample_case.json`. Highlight the four scored fields: contract value, outage duration,
regulated-region count, and renewal timing. The `request` field tells the agent what response to
produce after it assigns priority.

Suggested language:

> “Imagine a support team wants an agent to triage new production incidents. The agent reads the
> outage duration, contract value, regulated-region impact, and renewal timing. It applies four
> scoring rules, assigns a priority, drafts the first customer response, and recommends three next
> actions. This case triggers every rule, so we expect P0 with a score of 8. I will run that same job
> as a Prompt Agent and as a Hosted Agent. The comparison is not about which one writes a nicer
> paragraph. It is about where the scoring policy lives and who owns it.”

Briefly show the four case fields. Explain that a reason code names each rule that contributed to the
score. The audience now knows what the agent will do before seeing either implementation.

### 1:15-3:00 — Create, configure, and test a Prompt Agent in the portal

Switch to the Prompt Agent playground in the Foundry portal.

Explain what the audience is seeing:

- a Prompt Agent can be created directly in this portal or through SDK/REST;
- the left pane configures the model, instructions, tools, knowledge, memory, and guardrails;
- saving a change creates a version that can be tested and compared;
- the right pane is the playground for multi-turn chat, metrics, and request configuration; and
- there is no customer-owned agent application or container to maintain.

Expand **Instructions** and point to the four scoring rules. Point to **Tools**, **Knowledge**, and
**Memory** without changing them. Mention that this demo was created with the SDK only so setup is
repeatable; the same agent definition is visible and editable here.

Suggested language:

> “Prompt Agents support both portal-first and code-first development. Here I can choose the model,
> edit the instructions, attach tools and knowledge, save versions, and test the agent without
> building an application runtime. We used the SDK to create this demo repeatably, but I could have
> created the same agent here. Foundry operates the agent loop and runtime.”

In the top-level **Playground** tab, select the inner **Chat** tab, start a new chat, and paste:

```text
Triage this support case. Customer: Contoso Retail. Annual contract: $240,000. Production outage: 95 minutes. Regulated regions affected: 2. Renewal in: 21 days. Summarize the priority, reason codes, first response, and next three actions.
```

Call out the P0 priority, score of 8, the four triggered reason codes, first response, and three
actions. Connect each reason code back to the table in the introduction. Do not spend time comparing
prose word by word. If time allows, point out the **Traces**, **Monitor**, and **Evaluation** tabs as
the path from rapid portal prototyping to managed operation.

### 3:00-5:15 — Show code-first authoring and portal-based testing for a Hosted Agent

Open `deployment/src/agent-framework-agent-with-local-tools-responses/priority_rules.py`.

Explain what changed:

- the rule is a normal Python function;
- the same case always produces the same score because the calculation is code, not model judgment;
- the code can be reviewed, versioned, tested, and released with the application.

Then open `deployment/src/agent-framework-agent-with-local-tools-responses/main.py` and show where
`calculate_case_priority` is registered as a local tool.

Suggested language:

> “In the Hosted Agent path, we own the priority policy as code. The model must call this function
> before it assigns priority, then it uses the result to draft the response and actions. Foundry
> still gives us a managed deployment, endpoint, identity, scaling, and session infrastructure, but
> we own the application logic and dependencies.”

Switch to the Hosted Agent playground in the browser. Point out:

- the deployed version and running status;
- **Code asset** and **Protocols**, which describe what was deployed rather than offering a portal
  code editor;
- the same **Chat** playground used to invoke the deployed agent;
- the log stream for customer-owned runtime code, which starts after the first Playground message;
  and
- the **Details**, **Traces**, **Monitor**, **Evaluation**, and **Optimize** surfaces.

Suggested transition:

> “The Hosted Agent is built and changed in code, not in this setup pane. After deployment, it still
> participates in the Foundry lifecycle: I can test it in the playground, inspect logs and traces,
> evaluate it, monitor it, and optimize it from the managed portal experience.”

In the top-level **Playground** tab, select the inner **Chat** tab, start a new chat, and paste the
same support case.

Again, call out P0, score 8, and the four reason codes. Explain that the calculation came from the
customer-owned function. The generated wording can vary; the function result does not. After the
response arrives, point to **Log stream** if you want to show that the customer-owned runtime handled
the request.

### 5:15-6:15 — Compare responsibilities

Use this summary:

| Question | Prompt Agent | Hosted Agent |
| --- | --- | --- |
| Where is the triage policy? | Agent instructions | Python code |
| Who owns the agent-loop implementation? | Microsoft Foundry | Customer |
| Who operates the hosting platform? | Microsoft Foundry | Microsoft Foundry |
| Does the customer maintain runtime code? | No | Yes |
| Can the priority policy run as customer-owned code inside the agent? | No; connect customer code through a supported external tool | Yes |
| Are endpoint and scaling managed? | Yes | Yes |
| Can it be tested in the Foundry playground? | Yes | Yes, after deployment |
| Can its behavior be edited in the agent-building UI? | Yes | No; edit code and deploy a new version |

Suggested language:

> “Choose Prompt when instructions and supported tools are enough and you want Foundry to operate
> the agent loop. Choose Hosted when you need to own and change the code, framework, dependencies,
> protocols, or runtime behavior. In this example, the deciding question is whether the priority
> policy must be governed and released as customer-owned software.”

### 6:15-7:00 — Ask the customer

Close with these questions:

1. Which decisions in your agent must always follow customer-owned code rather than model instructions?
2. Do you need a specific framework, protocol, or dependency?
3. Do you want to operate that runtime logic, or would you prefer Foundry to operate it?

If the customer cannot identify a code-level control requirement, recommend starting with a Prompt
Agent and validating the scenario before taking on a Hosted application.

## Optional developer detail

For a developer audience, show that the Hosted rule has automated checks:

```bash
python3.13 -m unittest discover \
  -s deployment/src/agent-framework-agent-with-local-tools-responses/tests \
  -v
```

Explain it in plain language:

> “This confirms the customer-owned rule returns the same result even without a model. It is one
> reason to choose Hosted when deterministic policy code and software release controls matter.”

Skip this step for an executive or product audience.

## Command-line alternative

If the portal is unavailable or the audience wants an API/automation view, run both existing agents
from the repository root:

```bash
bash scripts/run-customer-demo.sh
```

The helper starts fresh Hosted session and conversation state, invokes the existing Prompt Agent,
and invokes the deployed Hosted Agent with the same case. It does not create new agent versions.

## If a live call fails

Keep the comparison intact:

1. Open `VALIDATED_OUTPUT.md`, which contains a known-good output from each path.
2. Show `prompt_agent/instructions.md` and explain how the Prompt Agent reaches the priority.
3. Show `priority_rules.py`, then run the local automated checks.
4. Show the Hosted Agent in the portal if it remains reachable.
5. State the exact failure category: authentication, model quota, deployment, session startup, tool
  call, or network access.

Do not replace it with an unrelated canned agent and imply that it validates this comparison.

## After the meeting

If no additional customer or reviewer session needs the environment, follow the **Clean up** section
in the main README. Cleanup removes the disposable resource group and stops further resource costs.
