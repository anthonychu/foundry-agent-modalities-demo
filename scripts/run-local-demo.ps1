<#
.SYNOPSIS
  Start the Hosted Agent on localhost:8088, send it the Contoso case, then stop it.
.EXAMPLE
  ./scripts/run-local-demo.ps1                    # 95-minute outage (P0, score 8)
  ./scripts/run-local-demo.ps1 -OutageMinutes 30  # 30-minute outage (P1, score 5)
#>
param(
    [int]$OutageMinutes = 95,
    [int]$TimeoutSeconds = 300
)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$deployment = Join-Path $root 'deployment'
$source = Join-Path $deployment 'src\agent-framework-agent-with-local-tools-responses'
$venv = Join-Path $source '.venv'

if (-not (Test-Path (Join-Path $venv 'Scripts\python.exe'))) {
    throw "Hosted Agent venv not found at $venv. Follow ai-deployment.md first."
}
if (-not (Test-Path (Join-Path $source '.env'))) {
    throw "$source\.env is missing. Follow ai-deployment.md (configure local env) first."
}

$case = Get-Content (Join-Path $root 'sample_case.json') -Raw | ConvertFrom-Json
$prompt = "Triage this support case. Customer: $($case.customer). " +
    "Annual contract: `$$('{0:N0}' -f $case.annual_contract_usd). " +
    "Production outage: $OutageMinutes minutes. " +
    "Regulated regions affected: $($case.regulated_regions). " +
    "Renewal in: $($case.renewal_days) days. $($case.request)"

$env:VIRTUAL_ENV = $venv
$env:PATH = "$venv\Scripts;$env:PATH"
$env:PYTHONIOENCODING = 'utf-8'
$env:AZURE_DEV_USER_AGENT = 'microsoft_foundry_skill'

$log = Join-Path ([IO.Path]::GetTempPath()) "local-agent-$PID.log"
$errLog = "$log.err"
Write-Host "Starting local Hosted Agent (log: $log)..."
$server = Start-Process -FilePath 'azd' -ArgumentList 'ai', 'agent', 'run', '--no-client' `
    -WorkingDirectory $deployment -RedirectStandardOutput $log -RedirectStandardError $errLog `
    -NoNewWindow -PassThru

try {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while (-not (Select-String -Path $log, $errLog -Pattern 'Running on http' -Quiet -ErrorAction SilentlyContinue)) {
        if ($server.HasExited) { Get-Content $log, $errLog -Tail 30; throw 'Local agent exited early.' }
        if ((Get-Date) -gt $deadline) { throw "Agent not ready after $TimeoutSeconds s. See $log" }
        Start-Sleep -Seconds 2
    }
    Write-Host "Ready on http://localhost:8088`n"
    Write-Host "Prompt: $prompt`n"

    Push-Location $deployment
    try {
        azd ai agent invoke field-demo-support-triage-hosted --local --new-session --new-conversation $prompt
    } finally { Pop-Location }

    Start-Sleep -Seconds 1
    $calls = (Select-String -Path $log, $errLog -Pattern 'Function calculate_case_priority succeeded' -ErrorAction SilentlyContinue).Count
    Write-Host "`nPython tool calls (calculate_case_priority): $calls"
}
finally {
    Write-Host 'Stopping local agent...'
    & taskkill.exe /PID $server.Id /T /F | Out-Null
}
