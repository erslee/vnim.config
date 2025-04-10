return {
	"Mr-LLLLL/lualine-ext.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lualine/lualine.nvim",
		-- if you want to open telescope window when click on LSP info of lualine, uncomment it
		-- "nvim-telescope/telescope.nvim"
	},
	opts = {
		separator = {
			left = "",
			right = "",
		},
		init_tab_project = {
			disabled = false,
			-- set this for your colorscheme. I have not default setting in diff colorcheme.
			tabs_color = {
				inactive = {
					fg = "#9da9a0",
					bg = "#4f5b58",
				},
			},
		},
		init_lsp = {
			disabled = false,
		},
		init_tab_date = true,
	},
}
