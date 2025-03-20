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
  { "williamboman/mason.nvim",          config = true },
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
            filetypes = { "javascript", "typescript", "css", "html", "json", "yaml", "markdown" },
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
        ensure_installed = { "lua", "typescript", "python", "json", "html", "css", "javascript", "sql" },
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
      local cmp = require("cmp")
      local lspkind = require("lspkind")

      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<D-/>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          format = lspkind.cmp_format({ mode = "symbol_text", maxwidth = 50 }),
        },
      })
    end,
  },

  -- LSP Configuration with Keybindings
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Keybindings for LSP
      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
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
}
