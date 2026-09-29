# ValheimAI

A Windows-focused autonomous Valheim companion framework.

## Goal

Run a second Steam/Valheim account as an AI-controlled teammate that can join your server, understand commands, follow players, report status, and later perform autonomous chores such as gathering resources, farming, mining, hauling, repairing and combat support.

## Milestone 1

- Launch Valheim from Steam
- Load a BepInEx client plugin
- Expose local player/game state over WebSocket
- Receive structured actions from a controller process
- Chat command routing
- Follow/stop/status commands
- Safety-first local movement loop

## Architecture

`Valheim -> BepInEx plugin -> localhost WebSocket -> ValheimAI.Controller -> planner/LLM`

The LLM chooses high-level goals. Deterministic local code executes movement and repeated actions so gameplay does not require continuous model calls.

## Important

This repository is an early development scaffold, not yet a production-ready autonomous player. Do not use valuable characters/worlds without backups while testing.

## Repository layout

- `src/ValheimAI.Plugin` - BepInEx plugin loaded into the AI's Valheim client
- `src/ValheimAI.Controller` - Windows controller/launcher and agent host
- `config` - example configuration
- `scripts` - Windows setup/start helpers
- `docs` - implementation roadmap and protocol notes

## First development target

1. Run `scripts\Install-ValheimAI.ps1` once. It detects Steam/Valheim, installs the Valheim BepInEx pack if missing, creates config, and builds available components.
2. Edit `config\settings.json` and set the model API key via environment variable.
3. Run `scripts\Start-ValheimAI.ps1`.
4. The controller starts and Steam launches Valheim.
5. Plugin connects locally at `ws://127.0.0.1:8765/ws/`.
6. Follow/status/resource skills are added on top of that bridge.

## Prior art

This project is intended to learn from existing open-source work such as `valheim-ai-agent`, ValheimMCP and ValBridgeServer where their licenses permit. Before copying source directly, verify each upstream project's current license and preserve required attribution.
