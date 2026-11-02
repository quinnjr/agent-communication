# agent-communication installer for Windows (PowerShell).
#
#   irm https://raw.githubusercontent.com/quinnjr/agent-communication/main/install.ps1 | iex
#
# With options:
#
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/quinnjr/agent-communication/main/install.ps1))) -Harness auto
#
# Options: -Version <tag>, -BinDir <dir in WSL>, -Harness <claude-code|
# opencode|kiro|auto> (repeatable as a list), -Service, -FromSource,
# -Distro <WSL distribution>.
#
# agent-communication runs on Linux, so on Windows it lives inside WSL, next to the
# agents that use it: run Claude Code, opencode or kiro-cli in WSL too. This
# script runs install.sh in your default WSL distribution (or -Distro).
#
# Everything runs in a script block with its own scope: `iex` runs a script
# in the caller's scope, where a top-level param() would overwrite (and its
# cleanup remove) the caller's variables of the same names.

& {
    param(
        # Release to install, e.g. v0.1.0 (default: latest).
        [string]$Version = $(if ($env:AGENT_COMMUNICATION_VERSION) { $env:AGENT_COMMUNICATION_VERSION } else { 'latest' }),
        # Directory inside WSL for the binary (default: ~/.local/bin).
        [string]$BinDir = $env:AGENT_COMMUNICATION_INSTALL_DIR,
        # Afterwards run `agent-communication install --harness <name>` in WSL:
        # claude-code, opencode, kiro, or auto (each one on PATH in WSL).
        [string[]]$Harness = @(),
        # Afterwards run `agent-communication install --service` (systemd in WSL).
        [switch]$Service,
        # Build with cargo inside WSL instead of downloading a binary.
        [switch]$FromSource,
        # WSL distribution to install into (default: the default distribution).
        [string]$Distro = $env:AGENT_COMMUNICATION_WSL_DISTRO
    )

    function Install-AgentCommunication {
        $url = if ($env:AGENT_COMMUNICATION_INSTALL_URL) { $env:AGENT_COMMUNICATION_INSTALL_URL } else {
            'https://raw.githubusercontent.com/quinnjr/agent-communication/main/install.sh'
        }

        if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
            Write-Host "agent-communication: error: WSL is not installed. agent-communication runs inside WSL." -ForegroundColor Red
            Write-Host "Install it with 'wsl --install' (then restart), and run this again."
            return 1
        }

        $wsl = @()
        if ($Distro) { $wsl += @('-d', $Distro) }

        & wsl.exe @wsl -e true 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $which = if ($Distro) { "the WSL distribution '$Distro'" } else { 'a default WSL distribution' }
            Write-Host "agent-communication: error: could not start $which." -ForegroundColor Red
            Write-Host "Install one with 'wsl --install -d Ubuntu', or pick one with -Distro (see 'wsl -l')."
            return 1
        }

        $opts = @()
        if ($Version -and $Version -ne 'latest') { $opts += @('--version', $Version) }
        if ($BinDir) { $opts += @('--bin-dir', $BinDir) }
        # -File passes `-Harness a,b` as one string, not a list.
        foreach ($h in ($Harness -split ',')) {
            if ($h.Trim()) { $opts += @('--harness', $h.Trim()) }
        }
        if ($Service) { $opts += '--service' }
        if ($FromSource) { $opts += '--from-source' }

        # Download install.sh inside WSL and run it there with the options.
        # No double quotes in it, since Windows PowerShell 5.1 does not escape
        # them for wsl.exe; an empty IFS keeps each option whole in the
        # unquoted $@.
        $fetch = 't=$(mktemp) && { curl -fsSL $0 -o $t || wget -qO $t $0; } && { IFS=; set -f; sh $t $@; }; r=$?; rm -f $t; exit $r'
        & wsl.exe @wsl -e sh -c $fetch $url @opts | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Host "agent-communication: installation failed (exit $LASTEXITCODE)." -ForegroundColor Red
            return 1
        }

        Write-Host ""
        Write-Host "agent-communication is installed in WSL. Run your agents inside WSL (e.g. 'wsl' then 'claude')."
        return 0
    }

    $status = Install-AgentCommunication
    if ($PSCommandPath) {
        # Run as a file (powershell -File install.ps1): report through the
        # exit code.
        exit $status
    }
    # Through iex or a script block, `exit` would close the caller's window.
    $global:LASTEXITCODE = $status
} @args
