@echo off
rem agent-communication installer for Windows (cmd.exe).
rem
rem   curl -fsSLo "%TEMP%\agent-communication-install.cmd" https://raw.githubusercontent.com/quinnjr/agent-communication/main/install.cmd && "%TEMP%\agent-communication-install.cmd"
rem
rem Options are passed on to install.sh, e.g. "--harness auto" or
rem "--version v0.1.0" (run with --help for all of them).
rem
rem agent-communication runs on Linux, so on Windows it lives inside WSL, next to the
rem agents that use it: run Claude Code, opencode or kiro-cli in WSL too. This
rem script runs install.sh in your default WSL distribution, or the one named
rem by AGENT_COMMUNICATION_WSL_DISTRO.
setlocal

where wsl.exe >nul 2>nul
if errorlevel 1 (
    echo agent-communication: error: WSL is not installed. agent-communication runs inside WSL.
    echo Install it with "wsl --install" ^(then restart^), and run this again.
    exit /b 1
)

set "AGENT_COMMUNICATION_URL=https://raw.githubusercontent.com/quinnjr/agent-communication/main/install.sh"
if defined AGENT_COMMUNICATION_INSTALL_URL set "AGENT_COMMUNICATION_URL=%AGENT_COMMUNICATION_INSTALL_URL%"
set "AGENT_COMMUNICATION_WSL="
if defined AGENT_COMMUNICATION_WSL_DISTRO set "AGENT_COMMUNICATION_WSL=-d %AGENT_COMMUNICATION_WSL_DISTRO%"

rem wsl.exe exits -1 when it cannot start a distribution, which
rem "if errorlevel 1" (exit code >= 1) would miss.
wsl.exe %AGENT_COMMUNICATION_WSL% -e true >nul 2>nul
if %errorlevel% neq 0 (
    echo agent-communication: error: could not start a WSL distribution.
    echo Install one with "wsl --install -d Ubuntu", or set AGENT_COMMUNICATION_WSL_DISTRO ^(see "wsl -l"^).
    exit /b 1
)

rem Download install.sh inside WSL and run it there with the options. An
rem empty IFS keeps each option whole in the unquoted $@.
wsl.exe %AGENT_COMMUNICATION_WSL% -e sh -c "t=$(mktemp) && { curl -fsSL $0 -o $t || wget -qO $t $0; } && { IFS=; set -f; sh $t $@; }; r=$?; rm -f $t; exit $r" "%AGENT_COMMUNICATION_URL%" %*
if %errorlevel% neq 0 (
    echo agent-communication: installation failed.
    exit /b 1
)

echo.
echo agent-communication is installed in WSL. Run your agents inside WSL ^(e.g. "wsl" then "claude"^).
exit /b 0
