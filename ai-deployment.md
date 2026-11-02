# AI deployment guide

Instructions for an AI coding agent to deploy this demo end to end. A human can follow them too. Validated on November 1, 2026 on Windows 11 (PowerShell 7) in North Central US.

## Rules for the agent

- Get the user's approval before creating Azure resources. Ask them to sign in. Never handle their password.
- Prefix every `azd` command with `AZURE_DEV_USER_AGENT=microsoft_foundry_skill` (inline only, never persisted).
- Never commit `.env` files, endpoints, connection strings, subscription or tenant IDs.
- Run `create_and_run.py` **once**. Use `invoke.py` afterwards.
- Run commands from the repo root unless a step says `deployment/`.

PowerShell: set `$env:AZURE_DEV_USER_AGENT='microsoft_foundry_skill'` once per shell instead of the inline prefix.

## What gets created

```text
Resource group <RESOURCE_GROUP>
├── Foundry account  cog-<token>
│   ├── project  <ENV_NAME>
│   │   ├── Prompt Agent   field-demo-support-triage-prompt
│   │   ├── Hosted Agent   field-demo-support-triage-hosted   (container runs on Microsoft-managed compute)
│   │   └── connection     appi-<name>   (App Insights, for traces)
│   └── model deployment   gpt-5.6-sol  (GlobalStandard, 10K TPM)
├── Log Analytics workspace  log-<name>
└── Application Insights     appi-<name>  (workspace-based)
```

## 1. Collect inputs

| Input | Example / default |
|---|---|
| `TENANT_ID` | ask the user |
| `SUBSCRIPTION_ID` | ask the user |
| `RESOURCE_GROUP` | `FoundryModalitiesDemo` |
| `LOCATION` | `northcentralus` (validated) |
| `ENV_NAME` | `foundry-modalities-demo` (also becomes the project name) |
| `MODEL` | `gpt-5.6-sol`, version `2026-07-09` (set in `deployment/azure.yaml`) |

## 2. Check prerequisites

| Tool | Validated version | Install |
|---|---|---|
| Azure CLI | 2.91 | <https://aka.ms/azcli> |
| Azure Developer CLI | 1.37.2 (≥ 1.32 required) | <https://aka.ms/azd> |
| `azure.ai.agents` extension | 1.0.0-beta.23 (≥ beta.13) | `azd extension install azure.ai.agents --source azd` |
| `microsoft.foundry` extension | 1.0.0-beta.4 | `azd extension install microsoft.foundry --source azd` |
| Python | 3.13 | Windows: `py -0` should list 3.13 |
| Git | any | Windows: Git Bash is useful for `.sh` helpers |

```bash
az version; azd version; azd extension list
```

## 3. Sign in

Use device code so the agent can show the user a code. Ask the user to complete each sign-in, then continue.

```bash
az login --tenant <TENANT_ID> --use-device-code
azd auth login --tenant-id <TENANT_ID> --use-device-code
az account set --subscription <SUBSCRIPTION_ID>
az account show --query "{sub:name, tenant:tenantId, user:user.name}"
```

`azd` tokens expire after 90 days of inactivity (`AADSTS700082`). Re-run `azd auth login` if you see it.

## 4. Check model quota

Need ≥ 10 free units of `OpenAI.GlobalStandard.gpt-5.6-sol` in the region.

```powershell
az cognitiveservices usage list -l northcentralus -o json | ConvertFrom-Json |
  ? { $_.name.value -match 'gpt-5.6-sol' } | % { "$($_.name.value) $($_.currentValue)/$($_.limit)" }
```

```bash
az cognitiveservices usage list -l northcentralus \
  --query "[?contains(name.value,'gpt-5.6-sol')].{name:name.value,used:currentValue,limit:limit}" -o table
```

No quota? Pick another region from the [availability table](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure-region-availability) or change the model in `deployment/azure.yaml`. Tell the user why.

## 5. Test the Python rules (no cloud)

```bash
py -3.13 -m unittest discover -s deployment/src/agent-framework-agent-with-local-tools-responses/tests -v      # Windows
python3.13 -m unittest discover -s deployment/src/agent-framework-agent-with-local-tools-responses/tests -v    # macOS/Linux
```

Expect `Ran 4 tests … OK`.

## 6. Create the azd environment

```bash
cd deployment
azd env new <ENV_NAME> --subscription <SUBSCRIPTION_ID> --location <LOCATION> --no-prompt
azd env set AZURE_SUBSCRIPTION_ID <SUBSCRIPTION_ID>
azd env set AZURE_TENANT_ID <TENANT_ID>
azd env set AZURE_LOCATION <LOCATION>
azd env set AZURE_AI_MODEL_DEPLOYMENT_NAME gpt-5.6-sol
azd env set AZURE_RESOURCE_GROUP <RESOURCE_GROUP>     # forces the exact RG name
```

`AZURE_RESOURCE_GROUP` feeds the `microsoft.foundry` provider's `resourceGroupName` parameter. Confirm before creating anything:

```bash
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd provision --preview --no-prompt
```

Expect `Create : Resource group : <RESOURCE_GROUP>`, plus the AI Services account, model deployment, and project.

## 7. Provision

```bash
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd provision --no-state --no-prompt     # ~1–2 min
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent doctor
```

Expect only one failed check: `Hosted agents are active … run azd deploy`. That's correct at this stage.

## 8. Write the local `.env` files

macOS/Linux (from repo root):

```bash
bash scripts/configure-local-env.sh
```

Windows PowerShell (same result):

```powershell
Push-Location deployment
$ep = azd env get-value FOUNDRY_PROJECT_ENDPOINT; $m = azd env get-value AZURE_AI_MODEL_DEPLOYMENT_NAME
Pop-Location
"FOUNDRY_PROJECT_ENDPOINT=$ep`nFOUNDRY_MODEL_NAME=$m`nFOUNDRY_PROMPT_AGENT_NAME=field-demo-support-triage-prompt`nDELETE_AFTER_RUN=false`n" |
  Set-Content -NoNewline -Encoding ascii prompt_agent\.env
"FOUNDRY_PROJECT_ENDPOINT=$ep`nAZURE_AI_MODEL_DEPLOYMENT_NAME=$m`n" |
  Set-Content -NoNewline -Encoding ascii deployment\src\agent-framework-agent-with-local-tools-responses\.env
```

Both files are git-ignored.

## 9. Create the Prompt Agent (once)

```bash
# macOS/Linux
python3.13 -m venv prompt_agent/.venv
prompt_agent/.venv/bin/python -m pip install -r prompt_agent/requirements.txt
prompt_agent/.venv/bin/python prompt_agent/create_and_run.py
```

```powershell
# Windows
py -3.13 -m venv prompt_agent\.venv
prompt_agent\.venv\Scripts\python.exe -m pip install -r prompt_agent\requirements.txt
$env:PYTHONIOENCODING='utf-8'; prompt_agent\.venv\Scripts\python.exe prompt_agent\create_and_run.py
```

Expect `Prompt Agent created: … version=1`, then P0 / 8 / four reason codes.

## 10. Run the Hosted Agent locally

```bash
# macOS/Linux
python3.13 -m venv deployment/src/agent-framework-agent-with-local-tools-responses/.venv
deployment/src/agent-framework-agent-with-local-tools-responses/.venv/bin/python -m pip install \
  -r deployment/src/agent-framework-agent-with-local-tools-responses/requirements.txt
bash scripts/run-local-demo.sh
```

```powershell
# Windows
$src = 'deployment\src\agent-framework-agent-with-local-tools-responses'
py -3.13 -m venv "$src\.venv"
& "$src\.venv\Scripts\python.exe" -m pip install -r "$src\requirements.txt"
./scripts/run-local-demo.ps1
```

The script starts `azd ai agent run --no-client`, waits for `localhost:8088`, invokes once, prints the tool-call count, and stops the server. Expect P0 / 8 and `Python tool calls (calculate_case_priority): 1`. The pip install takes a few minutes the first time.

## 11. Deploy the Hosted Agent

```bash
cd deployment
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd deploy field-demo-support-triage-hosted --no-prompt   # ~2 min
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent show field-demo-support-triage-hosted --output json
```

Expect `"status": "active"`, `"version": "1"`. This is a code deploy: no container registry is created. The warning `AZURE_CONTAINER_REGISTRY_ENDPOINT not set; skipping ACR role check` is harmless. The deploy output prints the Hosted Agent's portal link.

## 12. Connect tracing (Log Analytics + Application Insights)

The project has no App Insights after provisioning. This step does what the portal's **Agents → Traces → Connect** button does.

```bash
RG=<RESOURCE_GROUP>; LOC=<LOCATION>; LAW=log-<name>; APPI=appi-<name>
ACCOUNT=$(cd deployment && azd env get-value AZURE_AI_ACCOUNT_NAME)
PROJECT=$(cd deployment && azd env get-value AZURE_AI_PROJECT_NAME)

az extension add -n application-insights --only-show-errors
az monitor log-analytics workspace create -g $RG -n $LAW -l $LOC --sku PerGB2018 --retention-time 30
az monitor app-insights component create -g $RG -a $APPI -l $LOC --kind web --application-type web \
  --workspace "$(az monitor log-analytics workspace show -g $RG -n $LAW --query id -o tsv)"
```

Create the project connection (category `AppInsights`). The connection string goes in a temp file that is deleted right after.

```bash
# bash
APPI_ID=$(az monitor app-insights component show -g $RG -a $APPI --query id -o tsv)
APPI_CS=$(az monitor app-insights component show -g $RG -a $APPI --query connectionString -o tsv)
TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
cat >"$TMP" <<EOF
{"properties":{"category":"AppInsights","target":"$APPI_ID","authType":"ApiKey","isSharedToAll":false,
 "credentials":{"key":"$APPI_CS"},"metadata":{"ApiType":"Azure","ResourceId":"$APPI_ID"}}}
EOF
az rest --method put --body "@$TMP" --url "https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/$RG/providers/Microsoft.CognitiveServices/accounts/$ACCOUNT/projects/$PROJECT/connections/$APPI?api-version=2026-07-01"
(cd deployment && azd env set APPLICATIONINSIGHTS_CONNECTION_STRING "$APPI_CS")
```

```powershell
# PowerShell ($RG, $APPI, $ACCOUNT, $PROJECT set as above)
$appi = az monitor app-insights component show -g $RG -a $APPI -o json | ConvertFrom-Json
$body = @{ properties = @{ category='AppInsights'; target=$appi.id; authType='ApiKey'; isSharedToAll=$false
  credentials=@{ key=$appi.connectionString }; metadata=@{ ApiType='Azure'; ResourceId=$appi.id } } } | ConvertTo-Json -Depth 5
$tmp = New-TemporaryFile; Set-Content $tmp $body -Encoding utf8
try { az rest --method put --body "@$tmp" --url "https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/$RG/providers/Microsoft.CognitiveServices/accounts/$ACCOUNT/projects/$PROJECT/connections/${APPI}?api-version=2026-07-01" }
finally { Remove-Item $tmp }
Push-Location deployment; azd env set APPLICATIONINSIGHTS_CONNECTION_STRING $appi.connectionString; Pop-Location
```

**No redeploy needed.** Foundry injects `APPLICATIONINSIGHTS_CONNECTION_STRING` into every new Hosted Agent session. Invoke once, then confirm:

```bash
cd deployment
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd ai agent monitor field-demo-support-triage-hosted --tail 200 | grep appinsights_configured
```

Expect `appinsights_configured=True`. The log also shows `ModuleNotFoundError: No module named 'agents'` once per container start. That's an optional instrumentation for a different SDK; ignore it.

**RBAC:** the user who created the resources can query them. Teammates who only need to read traces need **Log Analytics Reader** on the App Insights resource.

## 13. Verify both deployed agents

```bash
bash scripts/run-customer-demo.sh          # macOS/Linux
```

```powershell
# Windows
$env:PYTHONIOENCODING='utf-8'; prompt_agent\.venv\Scripts\python.exe prompt_agent\invoke.py
Push-Location deployment
azd ai agent invoke field-demo-support-triage-hosted --new-session --new-conversation 'Triage this support case. Customer: Contoso Retail. Annual contract: $240,000. Production outage: 95 minutes. Regulated regions affected: 2. Renewal in: 21 days. Summarize the priority, reason codes, first response, and next three actions.'
Pop-Location
```

`azd ai agent invoke` prints the answer twice. It's one call.

Portal links: `bash scripts/show-portal-links.sh`. On Windows, compute the subscription segment with Python. .NET `Guid.ToByteArray()` uses a different byte order and gives a wrong link.

```powershell
Push-Location deployment; $sub = azd env get-value AZURE_SUBSCRIPTION_ID; $rg = azd env get-value AZURE_RESOURCE_GROUP
$acct = azd env get-value AZURE_AI_ACCOUNT_NAME; $proj = azd env get-value AZURE_AI_PROJECT_NAME
$ver = azd env get-value AGENT_FIELD_DEMO_SUPPORT_TRIAGE_HOSTED_VERSION; Pop-Location
$enc = py -3.13 -c "import base64,uuid,sys;print(base64.urlsafe_b64encode(uuid.UUID(sys.argv[1]).bytes).rstrip(b'=').decode())" $sub
$base = "https://ai.azure.com/nextgen/r/$enc,$rg,,$acct,$proj/build/agents"
"$base/field-demo-support-triage-prompt/build"; "$base/field-demo-support-triage-hosted/build?version=$ver"
```

Wait 2–5 minutes after invoking, then check traces with KQL:

```kql
dependencies
| where timestamp > ago(1h)
| summarize n = count() by cloud_RoleName, name, op = tostring(customDimensions["gen_ai.operation.name"])
```

```bash
# bash
az monitor app-insights query -g $RG --app $APPI --analytics-query '<KQL>'
```

```powershell
# PowerShell: call the REST API (az.cmd mangles quotes and newlines in KQL on Windows)
$appId = az monitor app-insights component show -g $RG -a $APPI --query appId -o tsv
$tok = az account get-access-token --resource https://api.applicationinsights.io --query accessToken -o tsv
(Invoke-RestMethod -Method Post -Uri "https://api.applicationinsights.io/v1/apps/$appId/query" `
  -Headers @{Authorization="Bearer $tok"} -ContentType 'application/json' -Body (@{query='<KQL>'} | ConvertTo-Json)).tables[0].rows
```

## 14. Expected results

| Check | Expected |
|---|---|
| Unit tests | 4 pass |
| Prompt Agent (95 min) | P0, 8, `OUTAGE_60` `STRATEGIC_CONTRACT` `REGULATED_IMPACT` `RENEWAL_30` |
| Hosted Agent local + deployed (95 min) | same, plus 1 `calculate_case_priority` call |
| Both agents (30 min) | P1, 5, no `OUTAGE_60` |
| `azd ai agent doctor` after deploy | 11 passed, 0 failed |
| KQL `dependencies` | `execute_tool calculate_case_priority`, `chat gpt-5.6-sol` (role = hosted agent); `invoke_agent field-demo-support-triage-prompt:1` + `chat` (role = `responsesapi`) |

## Windows vs macOS/Linux

| Upstream (bash) | Windows equivalent |
|---|---|
| `python3.13` | `py -3.13` |
| `.venv/bin/python` | `.venv\Scripts\python.exe` |
| `source .venv/bin/activate` | not needed: `run-local-demo.ps1` sets `VIRTUAL_ENV` and `PATH` |
| `scripts/configure-local-env.sh` | PowerShell block in step 8 (or Git Bash) |
| `scripts/show-portal-links.sh` | PowerShell block in step 13 |
| `scripts/run-customer-demo.sh` | PowerShell block in step 13 (or Git Bash) |
| `az monitor app-insights query` | REST call in step 13 |
| Unicode output | set `PYTHONIOENCODING=utf-8` |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `AADSTS700082 refresh token expired` | `azd auth login --tenant-id <TENANT_ID> --use-device-code` |
| RG gets an auto name (`rg-<env>`) | `azd env set AZURE_RESOURCE_GROUP …` before provisioning; check with `--preview` |
| Doctor: `Hosted agents are active` fails | expected before step 11; run `azd deploy` |
| Model not found | `azd env get-value AZURE_AI_MODEL_DEPLOYMENT_NAME` must match `azure.yaml`; rewrite `.env` files |
| No traces | connection missing, or wait 2–5 min; new session needed (`--new-session`) |
| Port 8088 busy | stop the earlier `azd ai agent run` (find PID with `Get-NetTCPConnection -LocalPort 8088` or `lsof -i :8088`) |

## 15. Clean up

Get user approval first. This deletes everything in the resource group.

```bash
cd deployment
AZURE_DEV_USER_AGENT=microsoft_foundry_skill azd down --force --purge
az group exists --name <RESOURCE_GROUP>       # if true (monitoring resources remain):
az group delete --name <RESOURCE_GROUP> --yes
```

Optional local cleanup: delete both `.venv` folders and both `.env` files.
