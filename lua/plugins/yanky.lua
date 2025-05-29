return {
	"gbprod/yanky.nvim",
	opts = {},
	config = function()
		require("yanky").setup({
			ring = {
				history_length = 100,
				max_length = 100,
			},
			system_clipboard = {
				sync_with_ring = true,
			},
			picker = {
				telescope = {
					use_default_mappings = false,
				},
			},
			highlight = {
				on_put = true,
				on_yank = true,
				timer = 150,
			},
		})
		vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Yanky Put After" })
		vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Yanky Put Before" })
		vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Yanky G Put After" })
		vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Yanky G Put Before" })

		vim.keymap.set("n", "<leader>y", "<Plug>(YankyYank)", { desc = "Yanky Yank" })
		vim.keymap.set("n", "<leader>yp", "<Plug>(YankyPreviousEntry)", { desc = "Yanky Previous Entry" })
		vim.keymap.set("n", "<leader>yn", "<Plug>(YankyNextEntry)", { desc = "Yanky Next Entry" })
		vim.keymap.set("n", "<leader>yh", ":YankyRingHistory<cr>", { desc = "Yanky Ring History" })
	end,
}
