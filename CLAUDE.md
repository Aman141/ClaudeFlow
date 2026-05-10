# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code **plugin** named `claudeflow` — my personal collection of Claude Code extensions for AI engineering work. It is consumed by Claude Code itself (not run as a standalone program), so there is no build, test, or lint toolchain.

Plugin manifest: `.claude-plugin/plugin.json`.

## Layout

The repo follows the Claude Code plugin convention. Top-level directories map to plugin component types:

- `agents/` — subagent definitions (markdown files with frontmatter describing the agent's tools, model, and system prompt).
- `hooks/` — hook scripts invoked by Claude Code lifecycle events (PreToolUse, PostToolUse, Stop, etc.), wired up in `settings.json`.
- `skills/` — skill definitions (user-invocable via `/skill-name` or auto-loaded by description matching).
- `settings.json` — plugin-level Claude Code settings (permissions, hooks, env).

All of these directories are currently empty scaffolding; new extensions are added by dropping files into the appropriate directory and (for hooks/permissions) registering them in `settings.json`.

## Adding a new component

See @CONTRIBUTING.md for reference.

Because this repo ships as a plugin, prefer editing `settings.json` for behavior that must be enforced by the harness (permissions, hooks) rather than relying on instructions in prose — the harness executes settings, not prose.
