"""Hosted Agent with a deterministic local support-priority tool."""

from __future__ import annotations

import json
import os
from typing import Annotated

from agent_framework import Agent, tool
from agent_framework.foundry import FoundryChatClient
from agent_framework_foundry_hosting import ResponsesHostServer
from azure.identity import DefaultAzureCredential
from pydantic import Field

from priority_rules import calculate_priority


@tool(approval_mode="never_require")
def calculate_case_priority(
    annual_contract_usd: Annotated[
        int, Field(description="Annual contract value in US dollars.")
    ],
    outage_minutes: Annotated[
        int, Field(description="Current production outage duration in minutes.")
    ],
    regulated_regions: Annotated[
        int, Field(description="Number of regulated regions affected by the incident.")
    ],
    renewal_days: Annotated[
        int, Field(description="Number of days until the customer's renewal date.")
    ],
) -> str:
    """Calculate priority using the versioned fictional support-policy implementation."""

    decision = calculate_priority(
        annual_contract_usd=annual_contract_usd,
        outage_minutes=outage_minutes,
        regulated_regions=regulated_regions,
        renewal_days=renewal_days,
    )
    return json.dumps(
        {
            **decision.to_dict(),
            "policy": "fictional-demo-v1",
            "rule_source": "hosted-python",
        },
        sort_keys=True,
    )


def main() -> None:
    client = FoundryChatClient(
        project_endpoint=os.environ["FOUNDRY_PROJECT_ENDPOINT"],
        model=os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
        credential=DefaultAzureCredential(),
    )

    agent = Agent(
        client=client,
        instructions=(
            "You are a support case triage assistant for a fictional demonstration. "
            "Always call calculate_case_priority exactly once before assigning priority. "
            "Use the tool's priority, score, and reason codes without changing them. "
            "Then provide a concise first response and exactly three next actions. "
            "State that the rubric is fictional demonstration policy. "
            "Do not invent customer facts."
        ),
        tools=[calculate_case_priority],
        # The Foundry Responses hosting layer manages conversation history.
        default_options={"store": False},
    )

    ResponsesHostServer(agent).run()


if __name__ == "__main__":
    main()
