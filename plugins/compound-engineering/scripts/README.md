# Hook Scripts

This directory contains scripts for Claude Code hooks that enable automatic validation and linting.

## Available Scripts

### `lint-on-edit.sh`
**Type:** PostToolUse hook
**Trigger:** After Edit or Write operations
**Purpose:** Auto-runs appropriate linter based on file extension

Supports:
- TypeScript/JavaScript: ESLint + Prettier
- Python: Ruff or Black
- CSS/SCSS: Prettier
- JSON: Prettier

**Used by agents:**
- `senior-typescript-reviewer`
- `senior-python-reviewer`
- `code-simplicity-reviewer`

### `check-ui-file.sh`
**Type:** PostToolUse hook
**Trigger:** After Edit or Write operations
**Purpose:** Detects if edited file is UI-related and reminds that browser testing is mandatory

Detects UI patterns:
- `*.tsx`, `*.jsx`, `*.css`, `*.scss`
- `components/`, `pages/`, `app/`, `views/`
- `layouts/`, `templates/`, `styles/`
- `store/`, `context/`, `hooks/use*`
- Form/input/validation related files
- `tailwind.config.*`, `theme.*`

**Output when UI file detected:**
```
⚠️  UI FILE MODIFIED: src/components/Button.tsx
   → Browser testing is MANDATORY before PR creation
   → Run /test-browser after review completes
```

**Used by agents:**
- `senior-typescript-reviewer`
- `senior-python-reviewer`
- `code-simplicity-reviewer`

### `run-tests-after-review.sh`
**Type:** SubagentStop hook (project-level)
**Trigger:** After review agents complete
**Purpose:** Auto-runs test suite after code review

Detects project type and runs:
- Node.js: `npm test`
- Python: `pytest` or `unittest`
- Rust: `cargo test`
- Go: `go test ./...`

## Enabling Hooks

### Agent-level hooks (already configured)

The review agents already have PostToolUse hooks in their frontmatter:
```yaml
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./plugins/compound-engineering/scripts/lint-on-edit.sh"
        - type: command
          command: "./plugins/compound-engineering/scripts/check-ui-file.sh"
```

### Project-level SubagentStop hook

Add this to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": "senior-typescript-reviewer|senior-python-reviewer|code-simplicity-reviewer|security-sentinel|architecture-strategist",
        "hooks": [
          {
            "type": "command",
            "command": "./plugins/compound-engineering/scripts/run-tests-after-review.sh"
          }
        ]
      }
    ]
  }
}
```

Or add it globally in `~/.claude/settings.json` to apply to all projects.

## How Hooks Work

1. **PostToolUse hooks** run after a tool completes
   - Always advisory (exit 0)
   - Used for linting, formatting, notifications

2. **SubagentStop hooks** run when a subagent finishes
   - Project-level only (in settings.json)
   - Used for cleanup, final validation, test runs

## Hook Input Format

Hooks receive JSON via stdin with tool information:

```json
{
  "tool_input": {
    "file_path": "/path/to/file.ts",
    "content": "file contents..."
  }
}
```

Use `jq` to parse:
```bash
FILE_PATH=$(cat | jq -r '.tool_input.file_path // empty')
```
