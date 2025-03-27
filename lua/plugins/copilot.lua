return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			suggestion = {
				enabled = true,
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
		})
	end,
	keys = {
		-- { "<c-I>", ":lua require'copilot.suggestion'.accept_line()<cr>", desc = "Copilot accept line", mode = { "i" } },
		-- { "<c-]>", ":lua require'copilot.suggestion'.next()<cr>", desc = "Find Files", mode = { "i" } },
		{ "<leader>oc", ":lua require'copilot.suggestion'.toggle_auto_trigger()<cr>", desc = "Copilot toggle" },

		-- { "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
		-- { "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
	},
}
