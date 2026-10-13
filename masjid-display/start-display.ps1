# masjid-display/start-display.ps1
#
# Starts the masjid display:
#   1. starts the local web server (serve-web.ps1) if it isn't running,
#   2. waits until the app is reachable,
#   3. opens it in Google Chrome in full-screen kiosk mode,
#   4. reopens Chrome if it's closed or crashes,
#   5. keeps the screen from sleeping while running.
#
# Runs automatically at sign-in once setup.bat has been run.
# Stop it with stop-display.ps1. To leave the kiosk temporarily: Alt+F4
# (it reopens after a few seconds unless stop-display.ps1 was run).
#
# Options:
#   -Port 8080     port for the local web server
#   -WebRoot <dir> folder with the web build (default: ..\build\web)
#   -DryRun        start the server and print the Chrome command, but don't
#                  open Chrome (for testing)

param(
    [int]$Port = 8080,
    [string]$WebRoot = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\web'),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$url = "http://localhost:$Port/"
$stopFlag = Join-Path $PSScriptRoot 'stop.flag'
$profileDir = Join-Path $PSScriptRoot 'chrome-profile'
$logDir = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'display.log'

function Write-Log([string]$message) {
    $line = '{0:yyyy-MM-dd HH:mm:ss}  {1}' -f (Get-Date), $message
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

function Test-AppReachable {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
        return $r.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Find-Chrome {
    $candidates = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) { return $path }
    }
    return $null
}

function Test-KioskChromeRunning {
    # Our kiosk Chrome uses its own profile folder, so it's identifiable and
    # doesn't interfere with anyone's normal Chrome.
    $escaped = [Regex]::Escape($profileDir)
    return [bool](Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe'" |
        Where-Object { $_.CommandLine -match $escaped } |
        Select-Object -First 1)
}

# Keep the display and PC awake while this script runs (no global setting
# is changed; normal sleep rules return when the script stops).
Add-Type -Namespace MasjidDisplay -Name Power -MemberDefinition @'
[DllImport("kernel32.dll")]
public static extern uint SetThreadExecutionState(uint esFlags);
'@
$ES_CONTINUOUS = [uint32]'0x80000000'
$ES_SYSTEM_REQUIRED = [uint32]'0x00000001'
$ES_DISPLAY_REQUIRED = [uint32]'0x00000002'

Write-Log "Starting masjid display ($url)"
Remove-Item -Path $stopFlag -ErrorAction SilentlyContinue

# 1. Web server
if (Test-AppReachable) {
    Write-Log 'Web server already running'
} else {
    if (-not (Test-Path (Join-Path $WebRoot 'index.html'))) {
        Write-Log "ERROR: no web build in '$WebRoot' (run setup.bat)"
        exit 1
    }
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$(Join-Path $PSScriptRoot 'serve-web.ps1')`"",
        '-Root', "`"$WebRoot`"", '-Port', $Port
    )
    Write-Log 'Web server starting...'
}

# 2. Wait for it (up to 60 s)
$deadline = (Get-Date).AddSeconds(60)
while (-not (Test-AppReachable)) {
    if ((Get-Date) -gt $deadline) {
        Write-Log 'ERROR: web server did not respond within 60 seconds'
        exit 1
    }
    Start-Sleep -Seconds 1
}
Write-Log 'Web server is up'

# 3. Chrome in kiosk mode
$chrome = Find-Chrome
if (-not $chrome) {
    Write-Log 'ERROR: Google Chrome not found. Install Chrome and try again.'
    exit 1
}
$chromeArgs = @(
    '--kiosk', $url,
    "--user-data-dir=`"$profileDir`"",
    '--no-first-run',
    '--no-default-browser-check',
    '--noerrdialogs',
    '--disable-session-crashed-bubble',
    '--disable-features=Translate',
    '--overscroll-history-navigation=0'
)

if ($DryRun) {
    Write-Log "DryRun: would run `"$chrome`" $($chromeArgs -join ' ')"
    exit 0
}

# 4. Keep it open
while (-not (Test-Path $stopFlag)) {
    [MasjidDisplay.Power]::SetThreadExecutionState(
        $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED) | Out-Null

    if (-not (Test-KioskChromeRunning)) {
        if (-not (Test-AppReachable)) {
            Write-Log 'Web server not responding; restarting it'
            Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass',
                '-File', "`"$(Join-Path $PSScriptRoot 'serve-web.ps1')`"",
                '-Root', "`"$WebRoot`"", '-Port', $Port
            )
            Start-Sleep -Seconds 3
        }
        Write-Log 'Opening Chrome (kiosk)'
        Start-Process -FilePath $chrome -ArgumentList $chromeArgs
    }
    Start-Sleep -Seconds 10
}

Write-Log 'Stop requested; exiting'
[MasjidDisplay.Power]::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null
