# Removes the block. Deliberately annoying: makes you wait 10 minutes first.
param([switch]$Elevated)

$video = "https://www.youtube.com/watch?v=l60MnDJklnM"
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Log file next to unblock.bat
$log = Join-Path (Split-Path $PSScriptRoot) "lolblock.log"
function Log($msg) {
    $role = if ($admin) { "admin" } else { "user" }
    try { Add-Content -Path $log -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [unblock/$role] $msg" -Encoding UTF8 } catch {}
}
function Open-Video {
    try { Start-Process $video; Log "Opened video." }
    catch { Log "Could not open video: $($_.Exception.Message)" }
}

Log "Started. Elevated flag: $Elevated"

# Open a video as soon as someone tries to remove the block. It is opened
# before switching to admin, because a browser launched as admin often fails to open.
if (-not $admin) {
    Open-Video
    Log "Asking for admin rights."
    try { Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated" -Verb RunAs }
    catch { Log "Admin rights declined: $($_.Exception.Message)" }
    exit
}
if (-not $Elevated) { Open-Video }

Write-Host "Cravings usually pass within 10 minutes. Wait, drink some water, take a walk." -ForegroundColor Yellow
Log "Waiting 10 minutes."
for ($i = 600; $i -gt 0; $i--) {
    Write-Progress -Activity "Waiting before removing the block" -SecondsRemaining $i
    Start-Sleep -Seconds 1
}

$sentence = "I really want this and I accept the consequences"
if ((Read-Host "To continue, type exactly: '$sentence'") -ne $sentence) {
    Log "Sentence did not match. Block kept."
    Write-Host "Did not match. The block stays." -ForegroundColor Green
    exit
}

Stop-ScheduledTask -TaskName "LolBlock" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "LolBlock" -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item "$env:ProgramData\LolBlock" -Recurse -Force -ErrorAction SilentlyContinue
Log "Watchdog task and ProgramData folder removed."

$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$lines = Get-Content $hosts | Where-Object { $_ -notmatch '# LOLBLOCK' }
# The hosts file is often briefly locked by antivirus or the DNS service, so retry
for ($try = 1; $try -le 20; $try++) {
    try { [IO.File]::WriteAllLines($hosts, [string[]]$lines); Log "Hosts file cleaned (attempt $try)."; break }
    catch {
        if ($try -eq 20) {
            Log "Hosts file update failed: $($_.Exception.Message)"
            Write-Host "Could not update the hosts file: it is locked by another program." -ForegroundColor Red
        }
        else { Start-Sleep -Milliseconds 500 }
    }
}
ipconfig /flushdns | Out-Null

Log "Block removed."
Write-Host "Block removed." -ForegroundColor Red
Read-Host "Press Enter to close"
