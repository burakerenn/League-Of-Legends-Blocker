# Removes the block. Deliberately annoying: makes you wait 10 minutes first.

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Cravings usually pass within 10 minutes. Wait, drink some water, take a walk." -ForegroundColor Yellow
for ($i = 600; $i -gt 0; $i--) {
    Write-Progress -Activity "Waiting before removing the block" -SecondsRemaining $i
    Start-Sleep -Seconds 1
}

$sentence = "I really want this and I accept the consequences"
if ((Read-Host "To continue, type exactly: '$sentence'") -ne $sentence) {
    Write-Host "Did not match. The block stays." -ForegroundColor Green
    exit
}

Stop-ScheduledTask -TaskName "LolBlock" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "LolBlock" -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item "$env:ProgramData\LolBlock" -Recurse -Force -ErrorAction SilentlyContinue

$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$lines = Get-Content $hosts | Where-Object { $_ -notmatch '# LOLBLOCK' }
Set-Content -Path $hosts -Value $lines -Encoding ASCII
ipconfig /flushdns | Out-Null

Write-Host "Block removed." -ForegroundColor Red
Read-Host "Press Enter to close"
