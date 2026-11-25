-- Terminal buffers are excluded: Claude is restored via `--continue` instead of a fresh shell
vim.opt.sessionoptions = { "buffers", "curdir", "folds", "globals", "help", "tabpages", "winsize" }

local function claude_terminal_open()
	if not package.loaded["claudecode"] then
		return false
	end
	local ok, bufnr = pcall(require("claudecode.terminal").get_active_terminal_bufnr)
	return ok and bufnr ~= nil
end

local function restore_claude()
	require("lazy").load({ plugins = { "claudecode.nvim" } })
	require("claudecode.terminal").toggle_open_no_focus({}, "--continue")
end

return {
	"folke/persistence.nvim",
	lazy = false,
	opts = {},
	config = function(_, opts)
		local persistence = require("persistence")
		persistence.setup(opts)

		local group = vim.api.nvim_create_augroup("session-restore", { clear = true })

		-- Session globals must start with an uppercase letter to be saved
		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "PersistenceSavePre",
			callback = function()
				vim.g.ClaudeCodeOpen = claude_terminal_open() and 1 or nil
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "PersistenceLoadPost",
			callback = function()
				if vim.g.ClaudeCodeOpen == 1 then
					vim.schedule(restore_claude)
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
