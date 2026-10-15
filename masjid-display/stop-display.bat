@echo off
rem Double-click to stop the masjid display. Run setup.bat to start it again.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-display.ps1" %*
echo.
pause
