return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	opts = function()
		-- Tag lets scripts/claude-status map this terminal to its Claude session id
		return { env = { NVIM_CLAUDE_TERM = require("claude.terminals").MAIN_TERM_ID } }
	end,
	keys = {
		{ "<leader>a", nil, desc = "AI/Claude Code" },
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
		{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
		{
			"<leader>as",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file from explorer",
			ft = { "snacks_picker_list" },
		},
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
		{
			"<leader>av",
			function()
				require("claude.terminals").new("vertical")
			end,
			desc = "New Claude (vertical split)",
		},
		{
			"<leader>an",
			function()
				require("claude.terminals").new("vertical", { here = true })
			end,
			desc = "New Claude (current window)",
		},
		{
			"<leader>ah",
			function()
				require("claude.terminals").new("horizontal")
			end,
			desc = "New Claude (horizontal split)",
		},
		{
			"<leader>ap",
			function()
				require("claude.launch").prompt()
			end,
			desc = "New Claude from command ([cd dir &&] claude args)",
		},
		{
			"<leader>ak",
			function()
				require("claude.caffeinate").toggle()
			end,
			desc = "Toggle caffeinate (keep Mac awake)",
		},
		{
			"<leader>aD",
			function()
				require("claude.dashboard").open()
			end,
			desc = "Claude info (sessions, agents, loops)",
		},
	},
}
