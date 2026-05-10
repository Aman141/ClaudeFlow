# ClaudeFlow

My personal Claude Code plugin — skills, agents, and hooks I use day-to-day as an AI Engineer. The canonical sources are framework-agnostic markdown; Claude Code-specific bits (hooks, plugin manifest) live alongside them and are ignored by other tools.

Generated adapters for Cursor, Copilot, and Gemini CLI mean the same skills work across whichever editor I'm in.

## What's in here

**Skills** (`skills/`)

- `fetch-notion-task` — resolve a Notion task ID (`DS-123`) to its page and extract acceptance criteria
- `implement-notion-task` — fetch a Notion task, plan the implementation, write the code, and self-verify against the criteria
- `review-mr` — procedure and rubric for reviewing a GitLab/GitHub merge request

**Agents** (`agents/`)

- `mr-reviewer` — end-to-end MR reviewer: fetches the linked Notion task, reads the diff, posts inline comments, returns a structured summary

**Hooks** (`hooks/`)

- `inject-temporal-context.sh` — injects current date and training-cutoff warning at session start so the model knows how stale its knowledge is
- `session-start-gitlab-policy.sh` — enforces MCP-only GitLab access; blocks `curl`/`glab`/`wget` fallbacks

## Project layout

```
.claude-plugin/plugin.json   Claude Code plugin manifest
agents/                      Sub-agent definitions (canonical)
skills/                      User-invocable skills (canonical)
hooks/                       SessionStart hook scripts
settings.json                Plugin settings (permissions, hooks)
.mcp.json                    MCP server config — portable across frameworks
scripts/generate-adapters.py Generates cross-framework adapters from skills/ and agents/
.cursor/rules/               Generated — Cursor rules
.github/prompts/             Generated — Copilot reusable prompts
.github/chatmodes/           Generated — Copilot custom chat modes
.gemini/commands/claudeflow/  Generated — Gemini CLI namespaced commands
```

Don't edit anything under `.cursor/`, `.github/prompts/`, `.github/chatmodes/`, or `.gemini/` — it's all regenerated from `skills/` and `agents/`.

## Usage

### Claude Code

Install as a local plugin:

```bash
# In a Claude Code session:
/plugin marketplace add ~/src/claudeflow
/plugin install claudeflow@claudeflow
```

Or reference from user settings:

```jsonc
// ~/.claude/settings.json
{
  "plugins": { "claudeflow": { "path": "/Users/you/src/claudeflow" } },
}
```

Skills surface automatically when the description matches, or invoke them directly:

```text
/claudeflow:review-mr
/claudeflow:fetch-notion-task
/claudeflow:implement-notion-task
```

#### Development mode

Claude Code reads files directly from the working copy — no reinstall needed between saves.

1. Clone and register:

   ```bash
   git clone <REPO_URL> ~/src/claudeflow
   # In a Claude Code session:
   /plugin marketplace add ~/src/claudeflow
   /plugin install claudeflow@claudeflow
   ```

2. Verify it's active:

   ```text
   /plugin list
   ```

3. To uninstall:

   ```text
   /plugin uninstall claudeflow@claudeflow
   /plugin marketplace remove claudeflow
   ```

Changes take effect on the next session — skill and agent definitions are loaded at session start.

Example prompts:

```text
review !42 in datascience/ingest
use the mr-reviewer agent to review !42 — read the task DS-123 first
fetch task DS-456 and list the acceptance criteria
implement DS-789
```

### Cursor

Rules auto-load when you open the repo in Cursor. For cross-project availability:

```bash
mkdir -p ~/.cursor/rules
cp .cursor/rules/*.mdc ~/.cursor/rules/
```

Add the MCP servers by copying `.mcp.json` entries into `~/.cursor/mcp.json`.

Example prompts:

```text
@review-mr review this MR: https://your-gitlab.com/your-project/-/merge_requests/42
@fetch-notion-task TASK-456
@mr-reviewer take MR !42 in your-project end-to-end
```

### GitHub Copilot (VS Code)

Enable prompt files in VS Code settings (one-time):

```jsonc
{
  "chat.promptFiles": true,
  "chat.modeFilesLocations": [".github/chatmodes"],
}
```

Files under `.github/prompts/` and `.github/chatmodes/` are picked up automatically when the repo is open. For cross-repo availability, copy them into your user-scope prompts/chatmodes directory (see VS Code docs for the current path).

Add MCP servers by copying `.mcp.json` entries into `.vscode/mcp.json`.

Example prompts:

```text
/review-mr  (then paste the MR URL when prompted)
/fetch-notion-task  DS-456
```

For the agent-style mode, select **mr-reviewer** from the chat mode picker:

```text
Review !42 in datascience/ingest
```

### Gemini CLI

Commands auto-discover when you run `gemini` from this repo. For global availability:

```bash
mkdir -p ~/.gemini/commands/claudeflow
cp .gemini/commands/claudeflow/*.toml ~/.gemini/commands/claudeflow/
```

Add MCP servers to `~/.gemini/settings.json`:

```jsonc
{
  "mcpServers": {
    /* copy from .mcp.json */
  },
}
```

Example prompts:

```text
/claudeflow:review-mr
Review !42 in datascience/ingest and focus on the error-handling changes.

/claudeflow:fetch-notion-task DS-456
```

## MCP servers

`.mcp.json` declares two servers used by every component:

- **gitlab** — [`@zereight/mcp-gitlab`](https://www.npmjs.com/package/@zereight/mcp-gitlab), launched via `npx`, pointed at your GitLab API URL (set in `.mcp.json`)
- **notion** — hosted server at `https://mcp.notion.com/mcp` (HTTP transport, OAuth on first use)

### Prerequisites

1. **Node.js ≥ 18** (provides `npx`):

   ```bash
   node --version && npx --version
   ```

2. **GitLab personal access token.** Create one at `your-gitlab.com/-/user_settings/personal_access_tokens` with `api` and `read_repository` scopes, then export it:

   ```bash
   # ~/.zshrc
   export GITLAB_PERSONAL_ACCESS_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
   ```

   Confirm it's set:

   ```bash
   echo "${GITLAB_PERSONAL_ACCESS_TOKEN:0:6}…"   # should print glpat-…
   ```

3. **Notion access.** The hosted Notion MCP server is gated by a connector you need to create in your Claude.ai account.

   a. Go to [claude.ai/settings/connectors](https://claude.ai/settings/connectors) → **Add connector → Notion**. Sign in to your Notion workspace and share the task database you want accessible (sharing a parent page is enough — access is inherited).

   b. On first use, the Notion MCP will open a browser tab to complete OAuth. Sign in with the same account used in step (a).

   c. If a task comes back "not found" for a valid ID, the page hasn't been shared with the connector. Open it in Notion → **… → Connections → Claude** and enable it.

### Per-framework config paths

| Framework         | MCP config path                                                      |
| ----------------- | -------------------------------------------------------------------- |
| Claude Code       | `.mcp.json` (project) or `~/.claude/mcp.json` (user)                 |
| Cursor            | `.cursor/mcp.json` (project) or `~/.cursor/mcp.json` (user)          |
| Copilot (VS Code) | `.vscode/mcp.json`                                                   |
| Gemini CLI        | `mcpServers` in `.gemini/settings.json` or `~/.gemini/settings.json` |

Symlink shortcuts:

```bash
ln -s "$PWD/.mcp.json" ~/.cursor/mcp.json
mkdir -p .vscode && ln -s ../.mcp.json .vscode/mcp.json
```

### Smoke test

```text
use the gitlab MCP to list my open merge requests
use the notion MCP to fetch page DS-123
```

401 from GitLab → token missing or unexported. "Not found" from Notion → page not shared with the connector.

## Adding components

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow. After any change under `skills/` or `agents/`:

```bash
python3 scripts/generate-adapters.py
```

The generator is stdlib-only and idempotent — it wipes and rewrites the generated directories on every run.
