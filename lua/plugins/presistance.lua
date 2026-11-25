-- Terminal buffers are excluded: Claude terminals are reopened with `--resume <id>` instead
vim.opt.sessionoptions = { "buffers", "curdir", "folds", "globals", "help", "tabpages", "winsize" }

local function save_claude_terminals()
	local saved = vim.tbl_map(function(term)
		return { layout = term.layout, session_id = term.session_id }
	end, require("claude.terminals").live())
	vim.g.ClaudeTerms = #saved > 0 and vim.json.encode(saved) or nil
end

local function restore_claude_terminals()
	local ok, saved = pcall(vim.json.decode, vim.g.ClaudeTerms or "[]")
	if not ok then
		return
	end
	local terminals = require("claude.terminals")
	for _, term in ipairs(saved) do
		terminals.restore(term)
	end
end

return {
	"folke/persistence.nvim",
	lazy = false,
	opts = {},
	config = function(_, opts)
		local persistence = require("persistence")
		persistence.setup(opts)
		local autosave = require("session.autosave")
		autosave.setup()

		local group = vim.api.nvim_create_augroup("session-restore", { clear = true })

		-- Session globals must start with an uppercase letter to be saved
		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "PersistenceSavePre",
			callback = save_claude_terminals,
		})

		-- A session without Claude terminals must not inherit the previous session's list
		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "PersistenceLoadPre",
			callback = function()
				vim.g.ClaudeTerms = nil
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "PersistenceLoadPost",
			callback = function()
				autosave.enable()
				autosave.mark_saved()
				if vim.g.ClaudeTerms then
					vim.schedule(restore_claude_terminals)
				end
			end,
		})

		-- Auto-restore only for a plain `nvim` in a real UI (not `nvim file`, stdin or headless)
		vim.api.nvim_create_autocmd("StdinReadPre", {
			group = group,
			callback = function()
				vim.g.started_with_stdin = true
			end,
		})
		vim.api.nvim_create_autocmd("VimEnter", {
			group = group,
			nested = true,
			callback = function()
				if vim.fn.argc() == 0 and not vim.g.started_with_stdin and #vim.api.nvim_list_uis() > 0 then
					autosave.enable()
					persistence.load()
				end
			end,
		})

		vim.keymap.set("n", "<leader>qs", persistence.load, { desc = "Restore session for cwd" })
		vim.keymap.set("n", "<leader>qS", persistence.select, { desc = "Select session" })
		vim.keymap.set("n", "<leader>ql", function()
			persistence.load({ last = true })
		end, { desc = "Restore last session" })
		vim.keymap.set("n", "<leader>qd", persistence.stop, { desc = "Don't save session on exit" })
	end,
}
