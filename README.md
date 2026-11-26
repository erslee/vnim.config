# Neovim config

Personal Neovim 0.12 config for macOS, managed with [lazy.nvim](https://github.com/folke/lazy.nvim): LSP, pickers, git, debugging,
automatic sessions and a deep Claude Code integration, including a dedicated Claude mode (`vc`).

## Features

- **Pickers and explorer** ([snacks.nvim](https://github.com/folke/snacks.nvim)): files, grep, buffers, git, LSP symbols, diagnostics,
  help, keymaps and more; file explorer, scratch buffers, zen mode, notifications, lazygit, start dashboard with recent sessions
- **File manager**: [yazi](https://github.com/mikavilpas/yazi.nvim) in a floating window
- **Motion**: [flash.nvim](https://github.com/folke/flash.nvim) jumps, [treewalker](https://github.com/aaronik/treewalker.nvim) syntax-tree moves,
  [harpoon](https://github.com/ThePrimeagen/harpoon) file marks, tmux-aware window moves
- **Editing**: [mini.surround](https://github.com/echasnovski/mini.surround), autopairs, auto-closing HTML/JSX tags, expand region,
  [yanky](https://github.com/gbprod/yanky.nvim) yank history, `x` does not overwrite the clipboard
- **LSP and formatting**: Mason with `ts_ls`, `lua_ls`, `pyright`, `ruff`; nvim-cmp completion; prettierd and stylua via none-ls / formatter.nvim;
  Treesitter with sticky context; [trouble](https://github.com/folke/trouble.nvim) for diagnostics, symbols and references
- **Git**: gitsigns, diffview, lazygit, git pickers and browse
- **Debugging**: nvim-dap with the VS Code JS debugger, `.vscode/launch.json` support, dap-ui
- **Markdown**: rendered in place with [render-markdown](https://github.com/MeanderingProgrammer/render-markdown.nvim)
- **Sessions**: a plain `nvim` restores the session of the directory ([persistence](https://github.com/folke/persistence.nvim)),
  autosaves it as you work, reopens files at the last cursor position, and brings back its Claude terminals with their conversations
- **UI**: lualine with buffers, tabs, LSP progress, git branch, session autosave state and clock; per-window Claude status;
  smooth cursor; `retrobox` colorscheme
- **Claude Code**: [claudecode.nvim](https://github.com/coder/claudecode.nvim) IDE integration, several Claude terminals side by side,
  each with its own status line, an info buffer with every session, its agents and loops, and [Claude mode](#claude-mode-vc)

## Requirements

Neovim 0.12+, git, a Nerd Font, tmux (optional, keeps `vc` Claudes running), [ripgrep](https://github.com/BurntSushi/ripgrep), [jq](https://jqlang.github.io/jq/),
[yazi](https://yazi-rs.github.io/), [lazygit](https://github.com/jesseduffield/lazygit) and the [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI.
LSP servers, formatters and debuggers are installed by Mason on first start.

## Hotkeys

Leader is `Space`. `<leader>?` shows the buffer's keymaps, and which-key lists every group as you type.

### Files, buffers and windows

| Key | Action |
| --- | --- |
| `<leader><space>` | Smart find files |
| `<leader>ff` / `fg` / `fr` / `fc` / `fp` | Find files / git files / recent / config file / projects |
| `<leader>,` or `<leader>fb` | Buffers |
| `<leader>/` or `<leader>sg` | Grep |
| `<leader>sw` | Grep word or selection |
| `<leader>e`, `<leader>bb`, `Cmd-b` | File explorer |
| `f`, `<leader>f`, `<leader>-` | Yazi at the current file |
| `<leader>cw` / `Ctrl-Up` | Yazi in the working directory / resume last Yazi |
| `[b` / `]b`, `<leader>bp` / `<leader>bn` | Previous / next buffer |
| `<leader>bd` / `<leader>bQ` / `<leader>br` | Delete buffer / delete other buffers / reopen last buffer |
| `<leader>s` / `<leader>v` | Split / vertical split |
| `<leader>=` | Equalize windows |
| `Ctrl-h/j/k/l` | Move between windows and tmux panes (also from terminals) |
| `<leader>z` / `<leader>Z` | Zen mode / zoom window |
| `<leader>.` / `<leader>S` | Scratch buffer / pick a scratch buffer |
| `<leader>ww`, `<leader>ss`, `Cmd-s` | Save |
| `<leader>wq` / `<leader>qq` | Close window / quit all |

### Motion and editing

| Key | Action |
| --- | --- |
| `s` / `S` | Flash jump / Flash Treesitter select |
| `r` / `R` (after an operator) | Remote Flash / Treesitter search |
| `Ctrl-s` (in `/` search) | Toggle Flash labels |
| `Cmd-h/j/k/l` | Treewalker: move between syntax nodes |
| `<leader>ha` / `<leader>hl` | Harpoon: add file / list |
| `Ctrl-1..4`, `[h` / `]h` | Harpoon: go to mark 1-4 / previous / next |
| `gsa` / `gsd` / `gsr` | Add / delete / replace surrounding |
| `gsf` / `gsF` / `gsh` | Find right / find left / highlight surrounding |
| `+` / `_` | Expand / shrink region |
| `p` / `P` / `gp` / `gP` | Put (yanky) |
| `<leader>y`, `<leader>yp` / `<leader>yn`, `<leader>yh` | Yank, cycle through yank history, yank history |
| `gc` / `gcc` | Toggle comment |
| `Cmd-h/l`, `Cmd-H/L` (insert) | Word back / forward, line start / end |
| `<leader>um` | Toggle Markdown rendering |
| `Ctrl-/` | Toggle terminal |
| `<leader>tv` / `<leader>ts` | Terminal in a vertical / horizontal split |

### LSP, diagnostics and formatting

| Key | Action |
| --- | --- |
| `gd` / `gI` / `gy` | Definition / implementation / type definition |
| `gr` | References |
| `K` / `<leader>ck` | Hover / signature help |
| `<leader>rn` / `<leader>cR` | Rename symbol / rename file |
| `<leader>ca` / `<leader>ce` | Code action / diagnostic under cursor |
| `[d` / `]d`, `[[` / `]]` | Previous / next diagnostic, previous / next reference |
| `<leader>ft` | Format buffer |
| `<leader>sS` | Workspace symbols |
| `<leader>sd` / `<leader>sD` | Diagnostics / buffer diagnostics (picker) |
| `<leader>xx` / `<leader>xX` | Diagnostics / buffer diagnostics (Trouble) |
| `<leader>cs` / `<leader>cl` | Symbols / LSP references (Trouble) |
| `<leader>xL` / `<leader>xQ` | Location list / quickfix list (Trouble) |

### Search pickers

`<leader>s` followed by: `b` buffer lines · `B` grep open buffers · `"` registers · `/` search history · `c` command history ·
`C` commands · `h` help · `H` highlights · `i` icons · `j` jumps · `k` keymaps · `m` marks · `M` man pages · `l` location list ·
`q` quickfix · `a` autocmds · `p` plugin specs · `u` undo history · `R` resume the last picker.
Also `<leader>:` command history · `<leader>n` notification history · `<leader>un` dismiss notifications · `<leader>uC` colorschemes.

### Git

| Key | Action |
| --- | --- |
| `<leader>gg` | Lazygit |
| `<leader>gs` / `<leader>gd` / `<leader>gS` | Status / diff hunks / stash |
| `<leader>gl` / `<leader>gL` / `<leader>gf` | Log / log of line / log of file |
| `<leader>gb` / `<leader>gB` | Branches / open in browser |

### Debugging

| Key | Action |
| --- | --- |
| `F9` / `<leader>da` | Continue / run (loads `.vscode/launch.json`) |
| `F5` or `<leader>do` / `<leader>dO` | Step over / step out |
| `F4` | Toggle breakpoint |
| `F8` / `F2` | Toggle dap-ui / evaluate |

### Sessions

| Key | Action |
| --- | --- |
| `<leader>qs` / `<leader>ql` / `<leader>qS` | Restore session of this directory / last session / select a session |
| `<leader>qd` | Don't save the session on exit |

### Claude Code

| Key | Action |
| --- | --- |
| `<leader>ac` / `<leader>af` | Toggle / focus the Claude side panel |
| `<leader>ar` / `<leader>aC` | Resume / continue a conversation |
| `<leader>am` | Select model |
| `<leader>ab` / `<leader>as` | Add current file / send selection (or explorer file) to Claude |
| `<leader>aa` / `<leader>ad` | Accept / deny Claude's proposed diff |
| `<leader>av` / `<leader>ah` / `<leader>an` | New Claude in a vertical split / horizontal split / the current window |
| `<leader>ap` | New Claude from a pasted command (see below) |
| `<leader>aD` | Claude info: sessions, agents, loops, limits |
| `<leader>ak` | Toggle caffeinate (keep the Mac awake) |

While typing in a Claude terminal: `Ctrl-\ n` new Claude in a split, `Ctrl-\ N` in this window, `Ctrl-\ p` from a command,
`Ctrl-\ s` info sidebar, `Ctrl-\ k` caffeinate. Switching to a Claude puts you straight into typing.

## Claude Code integration

Each Claude terminal has its own status line: state (working, waiting for you, idle), running agents, model, context use and
the account's 5h / 7d limits. It turns orange when Claude waits for an answer.

The Claude info buffer (`<leader>aD`) lists every Claude session of the last 12h as a tree: this Neovim's sessions first, then
the ones elsewhere; within each, sessions without loops first, then the looping ones. Each session shows its name (the
`/rename` title, else the title Claude generated), directory, model, context, cost and age, with its running agents and
scheduled loops (`/loop`, cron) below it. The order stays fixed: by when each session started.

**Start a Claude from a shell command**: `<leader>ap` (or `Ctrl-\ p`) asks for a command and opens it as a new Claude, e.g.

```
cd ~/dev/my-app && claude --model haiku --permission-mode auto /review
```

The command must be `[cd <dir> &&] claude [args]`, with a single `claude` and no `&&`, `;` or `|` after it. The directory and
arguments are kept, so the Claude comes back the same way when its session is restored.

### Setup

Point Claude Code's status line and hooks at `scripts/claude-status` in `~/.claude/settings.json`. The status lines, the info
buffer and session restore all read what it records.

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

## Claude mode (`vc`)

`vc` opens a Neovim dedicated to Claude Code, kept apart from your editor sessions:

```
┌ info sidebar ┬ Claude ─────────────────────┐
│ sessions     │                             │
│ ├─ ▶ ...     │   the Claude you picked     │
│ └─ ● ...     │                             │
├ token usage ─┴─────────────────────────────┤
│ ▂▅▇▃▁▆█▄▂▃▅▇▆▄▂▁▃▅▇█▆▄▃▂                   │
└────────────────────────────────────────────┘
```

- **Info sidebar** on the left: the session tree described above. `▶` marks the Claude on screen, `●` one running hidden,
  `○` one running in the background.
  `<CR>` shows that Claude on the right, `n` opens a new Claude, `p` one from a command, `R` refreshes, `q` closes.
- **One Claude window** on the right where the Claudes take turns; new Claudes open there instead of as splits.
  When the Claude on screen exits, the window shows another one; when the last one exits, Neovim quits.
- **Token usage chart** across the bottom: tokens over the last 24h for all sessions (input + output + cache writes),
  rescanned every minute. `R` rescans now, `q` closes it.
- **Claudes outlive `vc`** (when tmux is installed): each Claude runs in a hidden tmux session (own server, no status bar,
  no prefix or key bindings), and the `vc` window only shows it. Closing `vc` leaves Claude working and its loops firing.
  The sidebar lists such Claudes under **Background** (`○`); `<CR>` brings one into this `vc`. `/exit` ends a Claude for good.
  Without tmux, Claudes run as plain terminals and stop with `vc`.
- **Restore per directory**: the open Claudes are saved every 5 s and on exit; the next `vc` in the same directory attaches
  to the ones still running and resumes the others (`--resume <id>`) with their directory and launch arguments.
- **Keeps the Mac awake**: `caffeinate -i` runs while `vc` is open; the tabline shows `awake` / `off`, and `Ctrl-\ k`,
  `<leader>ak` or a click on it toggles it.

### Setup

Set up the [Claude Code hooks](#setup) above, then add to `~/.zshrc`:

```zsh
vc() { CLAUDE_MODE_ARGS="${(j: :)${(q)@}}" nvim --cmd "let g:claude_mode = 1"; }
```

### Usage

```zsh
vc                                         # restore this directory's Claudes, or start a new one
vc --model haiku --permission-mode auto    # arguments for a new Claude (used only when nothing is saved)
```

| In a Claude | Normal mode | Action |
| --- | --- | --- |
| `Ctrl-\ n` | `<leader>av` | New Claude (in the Claude window) |
| `Ctrl-\ N` | `<leader>an` | New Claude in the current window |
| `Ctrl-\ p` | `<leader>ap` | New Claude from a pasted command |
| `Ctrl-\ s` | `<leader>aD` | Info sidebar |
| `Ctrl-\ k` | `<leader>ak` | Toggle caffeinate |
| `Ctrl-h/j/k/l` | `Ctrl-h/j/k/l` | Move between the sidebar, Claude and the chart |
