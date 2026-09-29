@echo off
rem sb -- the Second Brain command (Mission 236). Launcher for PowerShell and cmd
rem on Windows: runs tools\sb\sb.py through uv. No .ps1 on purpose: a machine
rem whose execution policy blocks scripts still runs a .cmd.
setlocal
where uv >nul 2>nul || goto :python
uv run --no-project --quiet python "%~dp0..\sb.py" %*
exit /b %ERRORLEVEL%
:python
where py >nul 2>nul || goto :none
py -3 "%~dp0..\sb.py" %*
exit /b %ERRORLEVEL%
:none
echo REFUS : sb needs uv or Python 3.8+ on the PATH (sb install). 1>&2
exit /b 1
