# Deploy the Hosted Agent

This folder contains the Microsoft Foundry project and Hosted Agent deployment manifest for the
fictional support-triage comparison. Use the [repository quickstart](../README.md) for the complete
setup, Prompt Agent, Hosted Agent, presentation, troubleshooting, and cleanup workflow.

## Deployable source

The Hosted Agent implementation is under
`src/agent-framework-agent-with-local-tools-responses/`:

- `main.py` registers the deterministic priority function as a local Agent Framework tool and serves
   the agent through the Responses protocol.
- `priority_rules.py` owns the fictional scoring policy.
- `tests/` validates the exact policy module that is packaged for deployment. Tests are excluded
   from the deployed artifact by `.azdignore` and `.agentignore`.
- `requirements.txt` pins the direct dependency versions used for the August 27, 2026 validation.

The scaffold was initialized from the public
[Microsoft Foundry Agent with Local Tools sample](https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents/agent-framework/responses/02-tools)
and customized for this repository. See the root [LICENSE](../LICENSE).

## Important boundaries

- The Python `agent-framework-foundry-hosting` integration is prerelease even though the Hosted
   Agents service is generally available.
- The manifest currently provisions `gpt-5.6-sol` version `2026-07-09` in North Central US. Check
   the current [model availability table](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure-region-availability)
   before deploying or substitute another compatible chat model.
- Provisioning and model/agent use can incur Azure charges. Run the root README's cleanup procedure
   when the demo is no longer needed.
- Never commit `.azure/`, `.env`, credentials, endpoints, subscription IDs, resource identifiers, or
   exported logs.

## Useful public references

- [Quickstart: Deploy your first Hosted Agent](https://learn.microsoft.com/azure/foundry/agents/quickstarts/quickstart-hosted-agent)
- [Host Agent Framework agents in Foundry](https://learn.microsoft.com/azure/foundry/how-to/develop/framework-hosted-agents)
- [Hosted Agents overview](https://learn.microsoft.com/azure/foundry/agents/concepts/hosted-agents)
