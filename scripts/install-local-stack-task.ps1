$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$supervisorPath = Join-Path $PSScriptRoot 'start-local-stack.ps1'
$taskName = 'AcademyAlys Local Wi-Fi Server'
$powerShellPath = Join-Path $PSHOME 'powershell.exe'
$arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$supervisorPath`""
$action = New-ScheduledTaskAction -Execute $powerShellPath -Argument $arguments -WorkingDirectory $projectRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$trigger.Delay = 'PT30S'
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description 'Keeps the local AcademyAlys API and Wi-Fi HTTPS app available after user sign-in.' `
    -Force | Out-Null

Start-ScheduledTask -TaskName $taskName

Write-Output "Registered and started '$taskName'."
Write-Output 'It starts after you sign in to Windows and restarts the local API/HTTPS app if they stop.'
Write-Output "Logs: $(Join-Path $projectRoot 'logs\local-stack')"
Write-Output 'Keep this PC awake and connected to Wi-Fi for the phone link to remain available.'
