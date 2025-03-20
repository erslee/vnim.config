return {
	"lewis6991/gitsigns.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("gitsigns").setup({
			current_line_blame = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
				delay = 1000,
				ignore_whitespace = false,
				virt_text_priority = 100,
				use_focus = true,
			},
			current_line_blame_formatter = "<author>, <author_time:%r> - <summary>",
		})

		-- keybindings
		vim.api.nvim_set_keymap(
			"i",
			"<esc>",
			[[pumvisible() ? "\<c-e><esc>" : "\<esc>"]],
			{ expr = true, silent = true }
		)
		vim.api.nvim_set_keymap(
			"i",
			"<c-c>",
			[[pumvisible() ? "\<c-e><c-c>" : "\<c-c>"]],
			{ expr = true, silent = true }
		)
		vim.api.nvim_set_keymap("i", "<bs>", [[pumvisible() ? "\<c-e><bs>" : "\<bs>"]], { expr = true, silent = true })
		vim.api.nvim_set_keymap(
			"i",
			"<cr>",
			[[pumvisible() ? (complete_info().selected == -1 ? "\<c-e><cr>" : "\<c-y>") : "\<cr>"]],
			{ expr = true, silent = true }
		)
		vim.api.nvim_set_keymap("i", "<tab>", [[pumvisible() ? "\<c-n>" : "\<tab>"]], { expr = true, silent = true })
		vim.api.nvim_set_keymap("i", "<s-tab>", [[pumvisible() ? "\<c-p>" : "\<bs>"]], { expr = true, silent = true })
	end,
}
