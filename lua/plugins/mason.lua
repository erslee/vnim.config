-- return {
-- 	"williamboman/mason.nvim",
-- 	lazy = false,
-- 	priority = 1000,
-- 	dependencies = {
-- 		"neovim/nvim-lspconfig",
-- 		"williamboman/mason-lspconfig.nvim",
-- 		"mfussenegger/nvim-dap",
-- 		"jay-babu/mason-nvim-dap.nvim",
-- 	},
-- 	config = function()
-- 		require("mason").setup()
-- 		require("mason-lspconfig").setup({
-- 			ensure_installed = { "ts_ls" },
-- 			automatic_installation = true,
-- 		})
-- 		require("lspconfig").ts_ls.setup({})
-- 		require("mason-nvim-dap").setup({
-- 			ensure_installed = { "js", "node2" },
-- 		})
-- 	end,
-- }

return {
	-- Mason: Manage LSPs, Linters, Formatters
	{ "williamboman/mason.nvim", config = true },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "neovim/nvim-lspconfig" },
	{ "jay-babu/mason-null-ls.nvim" }, -- Mason integration for null-ls
	{
		"nvimtools/none-ls.nvim",
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.prettierd.with({
						filetypes = {
							"javascript",
							"typescript",
							"css",
							"html",
							"json",
							"yaml",
							"markdown",
							"typescriptreact",
						},
					}),
					null_ls.builtins.formatting.stylua,
				},
				on_attach = function(client, bufnr)
					if client.supports_method("textDocument/formatting") then
						-- Format on save
						vim.api.nvim_create_autocmd("BufWritePre", {
							buffer = bufnr,
							callback = function()
								vim.lsp.buf.format({ async = false })
							end,
						})
					end
				end,
			})

			vim.keymap.set("n", "<leader>ft", function()
				vim.lsp.buf.format({ async = false })
			end, { noremap = true, silent = true })
		end,
	}, -- null-ls (for formatting & linting)

	-- Treesitter: Better Syntax Highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"lua",
					"typescript",
					"python",
					"json",
					"html",
					"css",
					"javascript",
					"sql",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- Autocompletion: nvim-cmp + LSP + Snippets
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
			"L3MON4D3/LuaSnip",
			"rafamadriz/friendly-snippets",
			"onsails/lspkind.nvim", -- Icons
		},
		config = function()
			local has_words_before = function()
				if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
					return false
				end
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
			end
			local cmp = require("cmp")
			local lspkind = require("lspkind")
			lspkind.init({
				symbol_map = {
					Copilot = "",
				},
			})

			vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<D-/>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = vim.schedule_wrap(function(fallback)
						if cmp.visible() and has_words_before() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						else
							fallback()
						end
					end),
					-- ["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
				}),
				sources = cmp.config.sources({
					-- { name = "copilot" },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
				formatting = {
					format = lspkind.cmp_format({ mode = "symbol_text", maxwidth = 50 }),
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
			})
		end,
	},

	-- Copilot
	-- {
	--   "zbirenbaum/copilot-cmp",
	--   config = function()
	--     require("copilot_cmp").setup()
	--   end,
	-- },

	-- LSP Configuration with Keybindings
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Keybindings for LSP
			local on_attach = function(client, bufnr)
				local opts = { noremap = true, silent = true, buffer = bufnr }

				-- vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>ck", vim.lsp.buf.signature_help, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "<leader>ce", vim.diagnostic.open_float, opts)
				vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
				vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
			end

			-- Enable LSP servers
			local servers = { "lua_ls", "ts_ls", "pyright", "terraformls" }
			for _, server in ipairs(servers) do
				lspconfig[server].setup({
					capabilities = capabilities,
					on_attach = on_attach,
				})
			end

			-- Floating Borders for LSP Popups
			vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
			vim.lsp.handlers["textDocument/signatureHelp"] =
				vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
		end,
	},
	-- {
	--   "nvimdev/lspsaga.nvim",
	--   config = function()
	--     require("lspsaga").setup({
	--       ui = {
	--         border = "rounded",
	--         title = false,
	--         code_action = "",
	--       },
	--       symbol_in_winbar = {
	--         in_custom = true,
	--         enable = true,
	--         separator = " > ",
	--         show_file = true,
	--         click_support = false,
	--       },
	--     })
	--   end,
	--   dependencies = {
	--     "nvim-treesitter/nvim-treesitter", -- optional
	--     "nvim-tree/nvim-web-devicons",  -- optional
	--   },
	--   keys = {
	--     { "<leader>l",  desc = "Lsp Saga" },
	--     { "<leader>ls", "<cmd>Lspsaga show_line_diagnostics<cr>",   desc = "Line Diagnostics" },
	--     { "<leader>lS", "<cmd>Lspsaga show_cursor_diagnostics<cr>", desc = "Cursor Diagnostics" },
	--     { "<leader>lR", "<cmd>Lspsaga rename ++project<cr>",        desc = "Rename" },
	--     { "<leader>lr", "<cmd>Lspsaga rename ++project<cr>",        desc = "Rename" },
	--     { "<leader>la", "<cmd>Lspsaga code_action<cr>",             desc = "Code Action" },
	--     { "K",          "<cmd>Lspsaga hover_doc<cr>",               desc = "Hover Doc" },
	--     { "<leader>lH", "<cmd>Lspsaga signature_help<cr>",          desc = "Signature Help" },
	--     { "<leader>ld", "<cmd>Lspsaga show_line_diagnostics<cr>",   desc = "Line Diagnostics" },
	--     { "[e",         "<cmd>Lspsaga diagnostic_jump_prev<cr>",    desc = "Prev Diagnostic" },
	--     { "]e",         "<cmd>Lspsaga diagnostic_jump_next<cr>",    desc = "Next Diagnostic" },
	--     { "gd",         "<cmd>Lspsaga goto_definition<cr>",         desc = "Goto Definition" },
	--     { "gD",         "<cmd>Lspsaga peek_definition<cr>",         desc = "Peek Definition" },
	--     { "gt",         "<cmd>Lspsaga goto_type_definition<cr>",    desc = "Goto Type Definition" },
	--     { "gT",         "<cmd>Lspsaga peek_type_definition<cr>",    desc = "Peek Type Definition" },
	--     { "gr",         "<cmd>Lspsaga finder<cr>",                  desc = "Finder" },
	--     { "gp",         "<cmd>Lspsaga outline<cr>",                 desc = "Outline" },
	--     { "<leader>lq", "<cmd>Lspsaga term_toggle<cr>",             desc = "Toggle Terminal" },
	--   },
	-- },
}
