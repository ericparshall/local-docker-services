# Ensure every local-docker-services stack is running after login / Docker restart.
# Safe to re-run: docker compose up -d is idempotent.
$ErrorActionPreference = 'Continue'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$LogDir = Join-Path $Root 'logs'
$Log = Join-Path $LogDir 'ensure-all-up.log'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Log([string]$msg) {
  $line = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
  Add-Content -Path $Log -Value $line
  Write-Host $line
}

function Wait-Docker([int]$timeoutSec = 300) {
  $deadline = (Get-Date).AddSeconds($timeoutSec)
  while ((Get-Date) -lt $deadline) {
    try {
      $null = & docker info 2>$null
      if ($LASTEXITCODE -eq 0) { return $true }
    } catch {}
    Start-Sleep -Seconds 3
  }
  return $false
}

Write-Log "ensure-all-up starting (root=$Root)"
if (-not (Wait-Docker 300)) {
  Write-Log "ERROR: Docker engine not ready within timeout"
  exit 1
}
Write-Log "Docker engine ready"

$services = Get-ChildItem -Path (Join-Path $Root 'services') -Directory -ErrorAction SilentlyContinue
$failed = 0
foreach ($svc in $services) {
  $compose = Join-Path $svc.FullName 'compose.yml'
  if (-not (Test-Path $compose)) {
    Write-Log "skip $($svc.Name): no compose.yml"
    continue
  }
  Write-Log "up $($svc.Name)..."
  Push-Location $svc.FullName
  try {
    & docker compose up -d 2>&1 | ForEach-Object { Write-Log "  $_" }
    if ($LASTEXITCODE -ne 0) {
      Write-Log "ERROR: docker compose up failed for $($svc.Name) (exit $LASTEXITCODE)"
      $failed++
    } else {
      Write-Log "ok $($svc.Name)"
    }
  } finally {
    Pop-Location
  }
}

Write-Log "done (failures=$failed)"
exit $failed
