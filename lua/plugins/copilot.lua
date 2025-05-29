return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			-- suggestion = { enabled = false },
			panel = { enabled = false },
			suggestion = {
				enabled = false,
				auto_trigger = false,
				hide_during_completion = true,
				debounce = 75,
				keymap = {
					accept = "<C-i>",
					accept_word = false,
					accept_line = false,
					next = "<c-]>",
					prev = "<c-[>",
					dismiss = false,
				},
			},
			copilot_model = "gpt-4o-copilot",
			should_attach = function(_, bufname)
				if string.match(bufname, "env") then
					return false
				end

				return true
			end,
		})
	end,
	keys = {
		-- { "<c-I>", ":lua require'copilot.suggestion'.accept_line()<cr>", desc = "Copilot accept line", mode = { "i" } },
		-- { "<c-]>", ":lua require'copilot.suggestion'.next()<cr>", desc = "Find Files", mode = { "i" } },
		{ "<leader>uo", ":lua require'copilot.suggestion'.toggle_auto_trigger()<cr>", desc = "Copilot toggle" },
	},
}
