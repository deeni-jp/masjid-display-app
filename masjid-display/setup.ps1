# masjid-display/setup.ps1
#
# One-step setup for the masjid display PC. Run it from the project folder
# (cloned or copied) by double-clicking setup.bat. It:
#   1. checks Google Chrome is installed (offers to install it),
#   2. builds the web app (installs Flutter first if needed, asking you),
#   3. makes the display start automatically when Windows signs in,
#   4. opens the display now (full-screen Chrome).
#
# Run it again any time to rebuild and restart (e.g. after `git pull`).
#
#   Remove autostart:  setup.bat -Uninstall

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$projectRoot = Split-Path $here -Parent
$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'Masjid Display.lnk'

function Step([string]$message) { Write-Host "`n==> $message" -ForegroundColor Cyan }
function Fail([string]$message) { Write-Host "`nERROR: $message" -ForegroundColor Red; exit 1 }
function Ask([string]$question) {
    return (Read-Host "$question [Y/N]") -match '^(y|yes)$'
}

if ($Uninstall) {
    & (Join-Path $here 'stop-display.ps1')
    Remove-Item -Path $shortcutPath -ErrorAction SilentlyContinue
    Write-Host 'Autostart removed. The display will no longer open at sign-in.'
    exit 0
}

# Files copied from another PC/the internet can be marked as blocked.
Get-ChildItem -Path $here -Filter *.ps1 | Unblock-File

# 1. Chrome ------------------------------------------------------------------
Step 'Checking Google Chrome'
$chromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)
if (-not ($chromePaths | Where-Object { $_ -and (Test-Path $_) })) {
    if ((Get-Command winget -ErrorAction SilentlyContinue) -and (Ask 'Chrome is not installed. Install it now?')) {
        winget install --id Google.Chrome -e --accept-package-agreements --accept-source-agreements
    }
    if (-not ($chromePaths | Where-Object { $_ -and (Test-Path $_) })) {
        Fail 'Google Chrome is required. Install it from https://www.google.com/chrome and run setup again.'
    }
}
Write-Host 'Chrome found.'

# 2. Build the web app -------------------------------------------------------
Step 'Building the app'
$webBuild = Join-Path $projectRoot 'build\web'

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
$localFlutter = Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'
if (-not $flutter -and (Test-Path $localFlutter)) { $flutter = $localFlutter }

if (-not $flutter) {
    if (Test-Path (Join-Path $webBuild 'index.html')) {
        Write-Host 'Flutter is not installed; using the existing build in build\web.'
    } else {
        Write-Host 'Flutter (the tool that builds the app) is not installed.'
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Fail ('Git is needed to download Flutter. Install Git from https://git-scm.com ' +
                  'and run setup again, or copy a ready-made build\web folder into the project.')
        }
        if (-not (Ask "Download Flutter to $env:USERPROFILE\flutter now? (about 2 GB, one time only)")) {
            Fail 'Cannot build the app without Flutter.'
        }
        git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$env:USERPROFILE\flutter"
        if ($LASTEXITCODE -ne 0) { Fail 'Downloading Flutter failed. Check the internet connection and try again.' }
        $flutter = $localFlutter
    }
}

if ($flutter) {
    # The app reads its settings from .env (public values only).
    $envFile = Join-Path $projectRoot '.env'
    if (-not (Test-Path $envFile)) {
        Copy-Item (Join-Path $projectRoot '.env.example') $envFile
        Write-Host 'Created .env from .env.example.'
    }
    Write-Host 'Building (the first build takes several minutes)...'
    Push-Location $projectRoot
    try {
        & $flutter build web --release
        $buildOk = $LASTEXITCODE -eq 0
    } finally {
        Pop-Location
    }
    if (-not $buildOk) { Fail 'Building the app failed (see the messages above).' }
}
Write-Host 'App is ready.'

# 3. Autostart ---------------------------------------------------------------
Step 'Setting up autostart'
$startScript = Join-Path $here 'start-display.ps1'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$startScript`""
$shortcut.WorkingDirectory = $here
$shortcut.WindowStyle = 7  # minimised
$shortcut.Description = 'Opens the masjid prayer-times display in full screen'
$shortcut.Save()
Write-Host 'The display will open automatically every time Windows signs in.'

# 4. Start it now ------------------------------------------------------------
Step 'Opening the display'
& (Join-Path $here 'stop-display.ps1') | Out-Null   # restart cleanly with the new build
Start-Sleep -Seconds 2
Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$startScript`""
)

Write-Host ''
Write-Host 'Done! Chrome will open full screen in a few seconds.' -ForegroundColor Green
Write-Host 'First time only: sign in with the display account (needs a keyboard).'
Write-Host 'Tip: turn on automatic Windows sign-in so the display returns after a'
Write-Host 'power cut - see masjid-display\README.md.'
