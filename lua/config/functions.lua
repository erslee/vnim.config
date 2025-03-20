function _G.ReloadConfig()
	for name, _ in pairs(package.loaded) do
		if name:match("^user") and not name:match("nvim-tree") then
			package.loaded[name] = nil
		end
	end
	dofile(vim.env.MYVIMRC)
	vim.notify("Nvim configuration reloaded!", vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>cr", "lua ReloadConfig()")

-- local pickers = require("telescope.pickers")
-- local finders = require("telescope.finders")
-- local sorters = require("telescope.sorters")
-- local actions = require("telescope.actions")
-- local action_state = require("telescope.actions.state")
--
-- local function load_session()
-- 	local session_files = vim.fn.glob("._Session*.vim", false, true)
--
-- 	if #session_files == 0 then
-- 		print("No session files found!")
-- 		return
-- 	end
--
-- 	pickers
-- 		.new({}, {
-- 			prompt_title = "Load Session",
-- 			finder = finders.new_table(session_files),
-- 			sorter = sorters.get_generic_fuzzy_sorter(),
-- 			attach_mappings = function(prompt_bufnr, map)
-- 				local function load_selected_session()
-- 					local selection = action_state.get_selected_entry()
-- 					if selection then
-- 						actions.close(prompt_bufnr) -- ✅ Close Telescope first
-- 						vim.schedule(function() -- ✅ Delay execution to avoid floating window issues
-- 							vim.cmd("silent! source " .. selection[1])
-- 							print("Loaded session: " .. selection[1])
-- 						end)
-- 					end
-- 				end
--
-- 				map("i", "<CR>", load_selected_session)
-- 				map("n", "<CR>", load_selected_session)
--
-- 				return true
-- 			end,
-- 		})
-- 		:find()
-- end
-- -- 📌 Save a session with a chosen name using Telescope
-- local function save_session()
-- 	vim.ui.input({ prompt = "Enter session name (without .vim): ", default = "._Session" }, function(session_name)
-- 		if session_name and session_name ~= "" then
-- 			-- Ensure session name starts with "._Session" and append ".vim"
-- 			if not session_name:match("^%._Session") then
-- 				session_name = "._Session" .. session_name
-- 			end
-- 			session_name = session_name .. ".vim"
--
-- 			vim.cmd("mksession! " .. session_name)
-- 			print("Session saved as: " .. session_name)
-- 		else
-- 			print("Session save cancelled or invalid input.")
-- 		end
-- 	end)
-- end
--
-- -- 🔥 Neovim commands & keybindings
-- vim.api.nvim_create_user_command("LoadSession", load_session, {})
-- vim.api.nvim_create_user_command("SaveSession", save_session, {})
--
-- vim.keymap.set("n", "<leader>ls", load_session, { desc = "Load session" })
-- vim.keymap.set("n", "<leader>mm", save_session, { desc = "Save session with a name" })
