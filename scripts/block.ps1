# League of Legends blocker
# Usage: double-click block.bat
param([switch]$Elevated)

$video = "https://www.youtube.com/watch?v=PZ7lDrwYdZc"
$folder = "$env:ProgramData\LolBlock"
$videoShown = "$folder\video-shown"
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Log file next to block.bat
$log = Join-Path (Split-Path $PSScriptRoot) "lolblock.log"
function Log($msg) {
    $role = if ($admin) { "admin" } else { "user" }
    try { Add-Content -Path $log -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [block/$role] $msg" -Encoding UTF8 } catch {}
}
function Open-Video {
    try { Start-Process $video; Log "Opened video." }
    catch { Log "Could not open video: $($_.Exception.Message)" }
}

Log "Started. Elevated flag: $Elevated"

# If not running as admin, restart self as admin.
# On first-time setup the video is opened from here, as the normal user,
# because a browser launched as admin often fails to open.
if (-not $admin) {
    $firstTime = -not (Test-Path $videoShown)
    Log "First-time setup: $firstTime. Asking for admin rights."
    try { $p = Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated" -Verb RunAs -PassThru }
    catch { Log "Admin rights declined: $($_.Exception.Message)"; exit }
    if ($firstTime) {
        # The admin window creates the marker file when setup is done
        Log "Waiting for setup to finish."
        while (-not (Test-Path $videoShown) -and -not $p.HasExited) { Start-Sleep -Milliseconds 500 }
        if (Test-Path $videoShown) { Open-Video }
        else { Log "Admin window closed before setup finished. Video not opened." }
    }
    Log "Launcher finished."
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
# The hosts file is often briefly locked by antivirus or the DNS service, so retry
for ($try = 1; $try -le 20; $try++) {
    try { [IO.File]::WriteAllLines($hosts, [string[]]$lines); Log "Hosts file updated (attempt $try)."; break }
    catch {
        if ($try -eq 20) {
            Log "Hosts file update failed: $($_.Exception.Message)"
            Write-Host "Could not update the hosts file: it is locked by another program." -ForegroundColor Red
        }
        else { Start-Sleep -Milliseconds 500 }
    }
}
ipconfig /flushdns | Out-Null

# 2) Background watchdog: kills any League/Riot process every 3 seconds
#    (installer, Riot Client, the game itself)
New-Item -ItemType Directory -Force $folder | Out-Null
@'
while ($true) {
    Get-Process | Where-Object { $_.ProcessName -match 'League|Riot' } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}
'@ | Set-Content "$folder\watchdog.ps1" -Encoding ASCII

try {
    $action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$folder\watchdog.ps1`""
    $trigger  = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "LolBlock" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Force -ErrorAction Stop | Out-Null
    Start-ScheduledTask -TaskName "LolBlock" -ErrorAction Stop
    Log "Watchdog task registered and started."
}
catch { Log "Watchdog task failed: $($_.Exception.Message)" }

Write-Host ""
Write-Host "Done. League of Legends is now blocked." -ForegroundColor Green
Write-Host "You are more than this. GG." -ForegroundColor Green

# First-time setup only: show a video. When started from block.bat, creating
# the marker file tells the non-admin launcher to open it.
if (-not (Test-Path $videoShown)) {
    New-Item -ItemType File $videoShown -Force | Out-Null
    Log "First-time setup: created video marker."
    if (-not $Elevated) { Open-Video }
}
else { Log "Video marker already exists. Video not opened." }

Log "Setup finished."
Read-Host "Press Enter to close"
