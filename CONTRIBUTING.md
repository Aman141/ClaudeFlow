# Contributing

This repo is the source of truth for the `claudeflow` plugin. Add components
in the canonical directories (`skills/`, `agents/`, `hooks/`), then
regenerate the cross-framework adapters.

## Golden rule

**Only edit files under `skills/`, `agents/`, `hooks/`, `settings.json`, and
`.claude-plugin/`.** Everything under `.cursor/`, `.github/prompts/`,
`.github/chatmodes/`, and `.gemini/` is generated — changes there will be
lost on the next run of `scripts/generate-adapters.py`.

## Adding a skill

A skill is a user-invocable procedure or piece of guidance. Create:

```
skills/<name>/SKILL.md
```

with frontmatter:

```markdown
---
name: <name>
description: One sentence the harness matches against to decide when to surface this skill. Be specific about the trigger — "Use when ..." works well.
---

# <Title>

<body — steps, rubric, assumptions, examples>
```

Guidelines:

- The `description` is load-bearing for auto-surfacing — write it for the
  model, not for humans. State *when* to use the skill.
- Keep the body framework-agnostic. Refer to MCP tool prefixes
  (`mcp__gitlab__`, `mcp__notion__`) when a specific integration is
  required, but avoid hard-coding Claude Code tool names (`Read`, `Grep`,
  ...) in the body — the adapters drop the `tools:` frontmatter and other
  frameworks expose different tool sets.
- Cross-reference other skills by name (e.g. "follow the `fetch-notion-task`
  skill"); the generator does not rewrite these.

## Adding an agent

Agents are sub-agents delegated to by the top-level model. Create:

```
agents/<name>.md
```

with frontmatter:

```markdown
---
name: <name>
description: One sentence describing when to delegate to this agent.
tools: <comma-separated tool list or wildcard patterns, Claude-specific>
model: inherit
---

<system prompt>
```

Agent adapters:

- **Cursor** — emitted as a manual rule (`.cursor/rules/<name>.mdc`).
- **Copilot** — emitted as a custom chat mode
  (`.github/chatmodes/<name>.chatmode.md`).
- **Gemini CLI** — not emitted (sub-agent format is less stable; revisit).

## Adding a hook

Hooks are Claude Code-only (no cross-framework equivalent).

1. Add the script under `hooks/` (make it executable).
2. Register it in `settings.json` under the matching event, e.g.:

   ```json
   {
     "hooks": {
       "PreToolUse": [
         { "matcher": "Bash", "hooks": [{ "type": "command", "command": "$CLAUDE_PLUGIN_ROOT/hooks/<script>" }] }
       ]
     }
   }
   ```

Prefer enforcing behavior via hooks/permissions in `settings.json` over
prose instructions — the harness executes settings, not prose.

## Adding an MCP server

Edit `.mcp.json`. All four target frameworks (Claude Code, Cursor, Copilot,
Gemini CLI) support MCP, so one entry serves everyone.

## Regenerating adapters

After any change under `skills/` or `agents/`:

```
python3 scripts/generate-adapters.py
```

The script is stdlib-only, idempotent, and wipes the output directories
before rewriting them. Commit the regenerated files together with the
source change so downstream users of non-Claude frameworks get the update.

## Checklist before committing

- [ ] Source file (`skills/…/SKILL.md`, `agents/*.md`, hook, or
      `settings.json`) updated.
- [ ] Cross-references to other skills/agents use the new name, if renamed.
- [ ] `python3 scripts/generate-adapters.py` run; generated files included
      in the commit.
- [ ] `README.md` content listing updated if a skill/agent was added or
      removed.
