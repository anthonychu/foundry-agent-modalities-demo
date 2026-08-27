"""Invoke the existing Prompt Agent without creating another version."""

from __future__ import annotations

import json
import os
from pathlib import Path

from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent


def _load_local_env() -> None:
    env_file = HERE / ".env"
    if not env_file.exists():
        raise RuntimeError(
            "prompt_agent/.env is missing. Run scripts/configure-local-env.sh first."
        )
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
    agent_name = os.environ.get(
        "FOUNDRY_PROMPT_AGENT_NAME", "field-demo-support-triage-prompt"
    )

    with (
        DefaultAzureCredential() as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project,
        project.get_openai_client() as openai,
    ):
        response = openai.responses.create(
            input=_case_prompt(),
            extra_body={
                "agent_reference": {
                    "name": agent_name,
                    "type": "agent_reference",
                }
            },
        )
        print(f"Prompt Agent: {agent_name}")
        print(f"Response ID: {response.id}")
        print(response.output_text)


if __name__ == "__main__":
    main()
