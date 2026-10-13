@echo off
rem Double-click to set up (or update) the masjid display. See README.md.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
echo.
pause
