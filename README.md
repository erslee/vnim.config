# Neovim config

## Claude mode (`vc`)

`vc` opens a Neovim that holds only Claude Code terminals: an info sidebar on the left (sessions, agents, loops, limits)
and one window on the right where the Claudes take turns. New Claudes open in that window instead of as splits.
Claude mode remembers the Claudes per directory, so the next time you run `vc` in the same directory it brings them back.

### Setup

1. Add the `vc` function to `~/.zshrc`:

   ```zsh
   vc() { CLAUDE_MODE_ARGS="${(j: :)${(q)@}}" nvim --cmd "let g:claude_mode = 1"; }
   ```

2. Point Claude Code's status line and hooks at `scripts/claude-status` in `~/.claude/settings.json`.
   The status line, info buffer and session restore all read the data the script writes.

   ```json
   "statusLine": { "type": "command", "command": "~/.config/nvim/scripts/claude-status statusline" },
   "hooks": {
     "SessionStart":     [{ "hooks": [{ "type": "command", "command": "~/.config/nvim/scripts/claude-status hook" }] }],
     "SessionEnd":       [{ "hooks": [{ "type": "command", "command": "~/.config/nvim/scripts/claude-status hook" }] }],
     "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "~/.config/nvim/scripts/claude-status hook" }] }],
     "PostToolUse":      [{ "hooks": [{ "type": "command", "command": "~/.config/nvim/scripts/claude-status hook" }] }],
     "Notification":     [{ "hooks": [{ "type": "command", "command": "~/.config/nvim/scripts/claude-status hook" }] }],
     "Stop":             [{ "hooks": [{ "type": "command", "command": "~/.config/nvim/scripts/claude-status hook" }] }],
     "SubagentStart":    [{ "hooks": [{ "type": "command", "command": "~/.config/nvim/scripts/claude-status hook" }] }],
     "SubagentStop":     [{ "hooks": [{ "type": "command", "command": "~/.config/nvim/scripts/claude-status hook" }] }]
   }
   ```

### Usage

```zsh
vc                                         # restore this directory's Claudes, or start a new one
vc --model haiku --permission-mode auto    # arguments for a new Claude (used only when nothing is saved)
```

- vc saves the open Claudes every 5 s and when Neovim exits. Each one is restored with `--resume <id>`, keeping its directory and the arguments it was started with.
- When a Claude exits, the right window shows another one. When the last Claude exits, Neovim quits.
- Switching to a Claude window puts you in insert mode.
- `caffeinate -i` keeps the Mac awake while vc runs; the tabline shows `awake` / `off`.

### Start a Claude from a shell command

Press `<C-\>p` or `<leader>ap`, then paste a command like:

```
cd ~/.poseidon-pr-autoreview && claude --model haiku --permission-mode auto /poseidon-pr-autoreview:start
```

That opens a new Claude (in `vc`, in the right window) in that directory with those arguments. The command must be `[cd <dir> &&] claude [args]` and contain only one `claude`, without `&&`, `;` or `|` after it.

### Keys

| Claude terminal | Normal mode   | Action                                   |
| --------------- | ------------- | ---------------------------------------- |
| `<C-\>n`        | `<leader>av`  | New Claude (split; in `vc` right window) |
| `<C-\>N`        | `<leader>an`  | New Claude in the current window         |
| `<C-\>p`        | `<leader>ap`  | New Claude from a pasted command         |
| `<C-\>s`        | `<leader>aD`  | Info sidebar / info in current window    |
| `<C-\>k`        | `<leader>ak`  | Toggle caffeinate (or click the tabline) |
| `<C-h/j/k/l>`   | `<C-w>h/j/k/l` | Move between windows                    |

Info sidebar (`▶` shown, `●` running hidden): `<CR>` shows that Claude in the right window, `n` opens a new Claude, `p` starts one from a command, `R` refreshes and `q` closes.
