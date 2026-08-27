"""Create and invoke the declarative Prompt Agent side of the modalities demo."""

from __future__ import annotations

import json
import os
from pathlib import Path

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition
from azure.identity import DefaultAzureCredential


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent


def _load_local_env() -> None:
    """Load simple KEY=VALUE pairs without an additional runtime dependency."""

    env_file = HERE / ".env"
    if not env_file.exists():
        return
    for raw_line in env_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, value = line.split("=", 1)
        os.environ.setdefault(name.strip(), value.strip().strip("'\""))


def _required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Set {name} in prompt_agent/.env before running the demo.")
    return value


def _case_prompt() -> str:
    case = json.loads((ROOT / "sample_case.json").read_text(encoding="utf-8"))
    return (
        "Triage this support case. "
        f"Customer: {case['customer']}. "
        f"Annual contract: ${case['annual_contract_usd']:,}. "
        f"Production outage: {case['outage_minutes']} minutes. "
        f"Regulated regions affected: {case['regulated_regions']}. "
        f"Renewal in: {case['renewal_days']} days. "
        f"{case['request']}"
    )


def main() -> None:
    _load_local_env()

    endpoint = _required("FOUNDRY_PROJECT_ENDPOINT")
    model = _required("FOUNDRY_MODEL_NAME")
    agent_name = os.environ.get(
        "FOUNDRY_PROMPT_AGENT_NAME", "field-demo-support-triage-prompt"
    )
    instructions = (HERE / "instructions.md").read_text(encoding="utf-8")

    with (
        DefaultAzureCredential() as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project,
        project.get_openai_client() as openai,
    ):
        agent = project.agents.create_version(
            agent_name=agent_name,
            definition=PromptAgentDefinition(
                model=model,
                instructions=instructions,
            ),
            description="Sample: declarative support-case triage rubric.",
        )
        print(
            "Prompt Agent created: "
            f"name={agent.name}, version={agent.version}, id={agent.id}"
        )

        response = openai.responses.create(
            input=_case_prompt(),
            extra_body={
                "agent_reference": {
                    "name": agent.name,
                    "type": "agent_reference",
                }
            },
        )
        print(f"Response ID: {response.id}")
        print(response.output_text)

        if os.environ.get("DELETE_AFTER_RUN", "false").lower() == "true":
            project.agents.delete_version(
                agent_name=agent.name,
                agent_version=agent.version,
            )
            print("Deleted the disposable Prompt Agent version.")
        else:
            print("Preserved the Prompt Agent version for portal/trace inspection.")


if __name__ == "__main__":
    main()
