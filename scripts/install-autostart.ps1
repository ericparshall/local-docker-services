# Install a logon Scheduled Task that brings all local-docker-services stacks up
# after Docker Desktop starts. Run once (elevated not required for current-user task).
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Script = Join-Path $PSScriptRoot 'ensure-all-up.ps1'
$TaskName = 'LocalDockerServices-EnsureUp'

if (-not (Test-Path $Script)) { throw "Missing $Script" }

$action = New-ScheduledTaskAction `
  -Execute 'powershell.exe' `
  -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Script`""

# At logon + a short delay so Docker Desktop can boot
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$triggerLogon.Delay = 'PT45S'

$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -MultipleInstances IgnoreNew `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $action `
  -Trigger $triggerLogon `
  -Settings $settings `
  -Principal $principal `
  -Description "Start local-docker-services compose stacks after login (waits for Docker)." `
  -Force | Out-Null

Write-Host "Installed Scheduled Task: $TaskName"
Write-Host "  Script: $Script"
Write-Host "  Trigger: At logon (+45s delay) for $env:USERNAME"
Get-ScheduledTask -TaskName $TaskName | Format-List TaskName, State
