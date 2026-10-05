@echo off
chcp 65001 >nul

:: Relaunch as administrator if needed (the cleaner touches HKLM, services and drivers).
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rockstar-cleaner.ps1"
pause
