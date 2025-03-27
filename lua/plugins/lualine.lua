return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"arkav/lualine-lsp-progress",
		"AndreM222/copilot-lualine",
	},
	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				-- component_separators = { left = '', right = ''},
				section_separators = { left = "", right = "" },
				-- section_separators = { left = '', right = ''},
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				always_show_tabline = true,
				globalstatus = false,
				refresh = {
					statusline = 100,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "filename", "diff", "diagnostics" },
				lualine_c = { "searchcount", "selectioncount" },
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = {
					{
						"copilot",
						-- Default values
						symbols = {
							status = {
								icons = {
									enabled = " ",
									sleep = " ", -- auto-trigger disabled
									disabled = " ",
									warning = " ",
									unknown = " ",
								},
								hl = {
									enabled = "#50FA7B",
									sleep = "#AEB7D0",
									disabled = "#6272A4",
									warning = "#FFB86C",
									unknown = "#FF5555",
								},
							},
							spinners = "dots", -- has some premade spinners
							spinner_color = "#6272A4",
						},
						show_colors = false,
						show_loading = true,
					},
					"progress",
					"lsp_progress",
				},
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "buffers" },
				lualine_x = {},
				lualine_y = { "CurrentSessionName", "branch" },
				lualine_z = { "tabs" },
			},
			winbar = {
				-- lualine_a = {},
				-- lualine_b = {},
				-- lualine_c = {'filename'},
				-- lualine_x = {},
				-- lualine_y = {},
				-- lualine_z = {}
			},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
