# Changelog

## Unreleased

- Renamed from agentmail to **agent-communication**. The crate, binary,
  MCP server name, opencode plugin (`agent-communication.js`), systemd unit
  (`agent-communication.service`), data directory, socket, lock files and
  install markers all use the new name, and every environment variable
  moved from `AGENTMAIL_*` to `AGENT_COMMUNICATION_*`. The GitHub repository
  is now `quinnjr/agent-communication`.
- There is no automatic migration from 0.1.0. Before installing, run
  `agentmail uninstall --harness <h>` for each harness you set up (and
  `agentmail uninstall --service` if you used the systemd unit), then
  `agent-communication install` again. Mail in
  `~/.local/share/agentmail/` is not carried over.

## 0.1.0 (2026-10-28)

First release.

- Local mail between coding agents: a daemon (redb, Unix socket), a CLI,
  and an MCP server with 15 tools. Covers addresses, contacts, threads,
  markdown bodies, urgent mail, and blocking questions with a deadlock
  guard.
- Harness integration for Claude Code, opencode 2.x and kiro-cli (V3):
  hooks, an opencode plugin, session binding, and waking idle agents.
  `agentmail install` / `uninstall` wire each one up, and
  `agentmail install --service` sets up the systemd user unit.
- Installers: `install.sh` (Linux/WSL), and `install.ps1` / `install.cmd`
  (Windows, into WSL). They download the static binary from GitHub
  releases and verify it with SHA-256.
- Prebuilt static binaries for x86_64 and aarch64 Linux (musl).
