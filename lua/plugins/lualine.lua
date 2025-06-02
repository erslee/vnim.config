return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "arkav/lualine-lsp-progress",
    "AndreM222/copilot-lualine",
    "letieu/harpoon-lualine",
  },
  -- opts = function(_, opts)
  --   local trouble = require("trouble")
  --   local symbols = trouble.statusline({
  --     mode = "lsp_document_symbols",
  --     groups = {},
  --     title = false,
  --     filter = { range = true },
  --     format = "{kind_icon}{symbol.name:Normal}",
  --     -- The following line is needed to fix the background color
  --     -- Set it to the lualine section you want to use
  --     hl_group = "lualine_c_normal",
  --   })
  --   table.insert(opts.sections.lualine_c, {
  --     symbols.get,
  --     cond = symbols.has,
  --   })
  -- end,
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = true,
        theme = "auto",
        -- component_separators = { left = "", right = "" },
        component_separators = { left = "|", right = "|" },
        -- section_separators = { left = "", right = "" },
        section_separators = { left = "|", right = "|" },

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
        lualine_b = {
          {
            "filename",
            file_status = true, -- Displays file status (readonly status, modified status)
            newfile_status = true, -- Display new file status (new file means no write after created)
            path = 1,        -- 0: Just the filename
            -- 1: Relative path
            -- 2: Absolute path
            -- 3: Absolute path, with tilde as the home directory
            -- 4: Filename and parent dir, with tilde as the home directory

            shorting_target = 40, -- Shortens path to leave 40 spaces in the window
            -- for other components. (terrible name, any suggestions?)
            symbols = {
              modified = "[+]", -- Text to show when the file is modified.
              readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
              unnamed = "[No Name]", -- Text to show for unnamed buffers.
              newfile = "[New]", -- Text to show for newly created file before first write
            },
          },
          "diff",
          "diagnostics",
        },
        lualine_c = {
          {
            "harpoon2",
            icon = "♥",
            indicators = { "1", "2", "3", "4" },
            active_indicators = { "1", "2", "3", "4" },
            color_active = { fg = "#00ff00" },
            _separator = " ",
            no_harpoon = "Harpoon not loaded",
          },
          "searchcount",
          "selectioncount",
        },
        lualine_x = {
          {
            function()
              return "  " .. require("dap").status()
            end,
            cond = function()
              return package.loaded["dap"] and require("dap").status() ~= ""
            end,
            color = function()
              return {
                -- fg = Snacks.util.color("Debug")
                fg = "#FF79C6",
              }
            end,
          },
          "encoding",
          "fileformat",
          {
            "filetype",
            icon_only = true, -- Display only an icon for filetype
          },
        },
        lualine_y = {
          "progress",
        },
        lualine_z = {
          "location",
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            "filename",
            file_status = true, -- Displays file status (readonly status, modified status)
            newfile_status = true, -- Display new file status (new file means no write after created)
            path = 1,        -- 0: Just the filename
            -- 1: Relative path
            -- 2: Absolute path
            -- 3: Absolute path, with tilde as the home directory
            -- 4: Filename and parent dir, with tilde as the home directory

            shorting_target = 40, -- Shortens path to leave 40 spaces in the window
            -- for other components. (terrible name, any suggestions?)
            symbols = {
              modified = "[+]", -- Text to show when the file is modified.
              readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
              unnamed = "[No Name]", -- Text to show for unnamed buffers.
              newfile = "[New]", -- Text to show for newly created file before first write
            },
          },
          "diff",
          "diagnostics",
        },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            "buffers",
            show_filename_only = false, -- Shows shortened relative path when set to false.
            hide_filename_extension = false, -- Hide filename extension when set to true.
            show_modified_status = true, -- Shows indicator when the buffer is modified.

            mode = 2,                  -- 0: Shows buffer name
            -- 1: Shows buffer index
            -- 2: Shows buffer name + buffer index
            -- 3: Shows buffer number
            -- 4: Shows buffer name + buffer number

            max_length = vim.o.columns * 4 / 5, -- Maximum width of buffers component,
            -- it can also be a function that returns
            -- the value of `max_length` dynamically.
            filetype_names = {
              TelescopePrompt = "Telescope",
              dashboard = "Dashboard",
              packer = "Packer",
              fzf = "FZF",
              alpha = "Alpha",
            }, -- Shows specific buffer name for that filetype ( { `filetype` = `buffer_name`, ... } )

            -- Automatically updates active buffer color to match color of other components (will be overidden if buffers_color is set)
            use_mode_colors = true,

            -- buffers_color = {
            -- 	-- Same values as the general color option can be used here.
            -- 	active = "lualine_{section}_normal", -- Color for active buffer.
            -- 	inactive = "lualine_{section}_inactive", -- Color for inactive buffer.
            -- },

            symbols = {
              modified = " ●", -- Text to show when the buffer is modified
              alternate_file = "#", -- Text to show to identify the alternate file
              directory = "", -- Text to show when the buffer is a directory
            },
          },
        },
        lualine_x = {},
        lualine_y = {
          "lsp_progress",
          "CurrentSessionName",
          "branch",
        },
        lualine_z = {
          "tabs",
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
          function()
            return " " .. os.date("%R")
          end,
        },
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
      extensions = { "quickfix" },
    })
    -- do not add trouble symbols if aerial is enabled
    -- And allow it to be overriden for some buffer types (see autocmds)
    if vim.g.trouble_lualine and LazyVim.has("trouble.nvim") then
      local trouble = require("trouble")
      local symbols = trouble.statusline({
        mode = "symbols",
        groups = {},
        title = false,
        filter = { range = true },
        format = "{kind_icon}{symbol.name:Normal}",
        hl_group = "lualine_c_normal",
      })
      table.insert(opts.sections.lualine_c, {
        symbols and symbols.get,
        cond = function()
          return vim.b.trouble_lualine ~= false and symbols.has()
        end,
      })
    end
  end,
}
