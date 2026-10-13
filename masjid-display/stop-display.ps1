# masjid-display/stop-display.ps1
#
# Stops the masjid display: the keep-open loop, the kiosk Chrome window and
# the local web server. Run start-display.ps1 (or restart the PC) to start
# it again.

$ErrorActionPreference = 'Continue'
$profileDir = Join-Path $PSScriptRoot 'chrome-profile'

# Tell start-display.ps1's loop to stop (it checks every 10 seconds).
New-Item -ItemType File -Force -Path (Join-Path $PSScriptRoot 'stop.flag') | Out-Null

$profilePattern = [Regex]::Escape($profileDir)
$folderPattern = [Regex]::Escape($PSScriptRoot)

Get-CimInstance Win32_Process | Where-Object {
    ($_.Name -eq 'chrome.exe' -and $_.CommandLine -match $profilePattern) -or
    ($_.Name -eq 'powershell.exe' -and $_.ProcessId -ne $PID -and
        $_.CommandLine -match $folderPattern -and
        $_.CommandLine -match 'serve-web\.ps1|start-display\.ps1')
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

Write-Host 'Masjid display stopped.'
