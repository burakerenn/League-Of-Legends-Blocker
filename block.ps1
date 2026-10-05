# League of Legends blocker
# Usage: right-click this file > "Run with PowerShell"

# If not running as admin, restart self as admin
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1) Block Riot websites and download servers via the hosts file
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$domains = @(
    "leagueoflegends.com", "www.leagueoflegends.com", "signup.leagueoflegends.com",
    "riotgames.com", "www.riotgames.com", "auth.riotgames.com", "authenticate.riotgames.com",
    "clientconfig.rpg.riotgames.com", "riotcdn.net", "lol.dyn.riotcdn.net",
    "lol.secure.dyn.riotcdn.net", "riot-client.secure.dyn.riotcdn.net"
)
$lines = @(Get-Content $hosts | Where-Object { $_ -notmatch '# LOLBLOCK' })
$lines += $domains | ForEach-Object { "0.0.0.0 $_ # LOLBLOCK" }
Set-Content -Path $hosts -Value $lines -Encoding ASCII
ipconfig /flushdns | Out-Null

# 2) Background watchdog: kills any League/Riot process every 3 seconds
#    (installer, Riot Client, the game itself)
$folder = "$env:ProgramData\LolBlock"
New-Item -ItemType Directory -Force $folder | Out-Null
@'
while ($true) {
    Get-Process | Where-Object { $_.ProcessName -match 'League|Riot' } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}
'@ | Set-Content "$folder\watchdog.ps1" -Encoding ASCII

$action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$folder\watchdog.ps1`""
$trigger  = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "LolBlock" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Force | Out-Null
Start-ScheduledTask -TaskName "LolBlock"

Write-Host ""
Write-Host "Done. League of Legends is now blocked." -ForegroundColor Green
Write-Host "You are more than this. GG." -ForegroundColor Green
Read-Host "Press Enter to close"
