@echo off
REM Atelier Wildcard — avvio setup su Windows (doppio click)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1" %*
pause
