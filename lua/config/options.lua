-- vim.g["airline#extensions#tabline#enabled"] = 1
-- vim.g["airline#extensions#tabline#formatter"] = "unique_tail"
-- vim.g["airline_powerline_fonts"] = 1
-- vim.g["airline#extensions#tabline#left_sep"] = '/'
-- vim.g["airline#extensions#tabline#left_alt_sep"] = '/'

vim.g["typescript_compiler_path"] = "tsc"
vim.g["typescript_compiler_options"] = "-p tsconfig.json"
vim.g["ale_completion_enabled"] = 1
vim.g["ale_fix_on_save"] = 1

vim.cmd.colorscheme("retrobox")
-- vim.cmd.colorscheme("onedark")
-- vim.cmd.colorscheme("doom-one")
-- vim.cmd.colorscheme("catppuccin-latte")
-- vim.cmd.colorscheme("tokyonight")

--
-- vim.g.coq_settings = {
--     keymap = {
--         recommended = false,
--     },
-- }

vim.wo.number = true
vim.wo.relativenumber = true
vim.opt.swapfile = false

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- vim.api.nvim_command("highlight cursorline guibg=#444444 ctermbg=8")
vim.api.nvim_command("set cursorline")
vim.api.nvim_command("set title")
-- vim.opt.termguicolors = true
-- require("bufferline").setup{
--   options = {
--     diagnostics = "nvim_lsp",
--     diagnostics_indicator = function(count, level, diagnostics_dict, context)
--   local s = " "
--   for e, n in pairs(diagnostics_dict) do
--     local sym = e == "error" and " "
--       or (e == "warning" and " " or " ")
--     s = s .. n .. sym
--   end
--   return s
-- end
--   }
-- }
--

-- local augroup = vim.api.nvim_create_augroup
-- local autocmd = vim.api.nvim_create_autocmd
-- augroup("__formatter__", { clear = true })
-- autocmd("BufWritePost", {
-- 	group = "__formatter__",
-- 	command = ":FormatWrite",
-- })

-- vim.api.nvim_create_autocmd("VimEnter", {
-- 	callback = function()
-- 		local session_file = vim.fn.getcwd() .. "/._Session.vim"
-- 		if vim.fn.filereadable(session_file) == 1 then
-- 			local choice = vim.fn.confirm("Session file found. Load it?", "&Yes\n&No", 1)
-- 			if choice == 1 then
-- 				vim.cmd("source " .. session_file)
-- 			end
-- 		end
-- 	end,
-- })

-- vim.api.nvim_create_user_command("LoadSession", function()
-- 	local session_files = vim.fn.glob("._Session*.vim", false, true) -- Get all matching session files
--
-- 	if #session_files == 0 then
-- 		print("No session files found!")
-- 		return
-- 	end
--
-- 	-- Convert filenames to a numbered list for selection
-- 	local options = {}
-- 	for i, file in ipairs(session_files) do
-- 		table.insert(options, i .. ". " .. file)
-- 	end
--
-- 	-- Show a selection prompt
-- 	local choice = vim.fn.inputlist(options)
--
-- 	-- Validate the choice
-- 	if choice > 0 and choice <= #session_files then
-- 		local session_file = session_files[choice]
-- 		vim.cmd("source " .. session_file)
-- 		print("Loaded session: " .. session_file)
-- 	else
-- 		print("Invalid choice or cancelled")
-- 	end
-- end, {})
--
-- -- Optional: Keybinding to trigger the session selection
-- vim.keymap.set("n", "<leader>ls", ":LoadSession<CR>", { desc = "Load a session" })
--
-- vim.api.nvim_create_user_command("SaveSession", function()
-- 	-- Prompt user for a session name
-- 	local session_name = vim.fn.input("Enter session name (._SessionX.vim): ", "._Session")
--
-- 	-- Validate input (ensure it starts with '._Session' and ends with '.vim')
-- 	if session_name == "" or not session_name:match("^%._Session%d*%.vim$") then
-- 		print("Invalid session name! Use format: ._SessionX.vim")
-- 		return
-- 	end
--
-- 	-- Save session
-- 	vim.cmd("mksession! " .. session_name)
-- 	print("Session saved as: " .. session_name)
-- end, {})
--
-- -- Keybinding to save a session with a custom name
-- vim.keymap.set("n", "<leader>mm", ":SaveSession<CR>", { desc = "Save session with a name" })
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
})
