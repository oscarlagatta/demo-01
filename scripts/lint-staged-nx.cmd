@echo off
REM Windows batch wrapper for lint-staged-nx
REM This script detects the environment and calls the appropriate script

setlocal enabledelayedexpansion

REM Check if PowerShell is available
powershell -Command "exit 0" >nul 2>&1
if %errorlevel% equ 0 (
    REM PowerShell is available, use the PowerShell script
    powershell -ExecutionPolicy Bypass -File "%~dp0lint-staged-nx.ps1" %*
) else (
    REM Fallback to basic ESLint command
    echo Warning: PowerShell not available, using basic ESLint...
    npx eslint --fix %*
)

exit /b %errorlevel%
