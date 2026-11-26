-- Claude mode (`vc`): a Neovim holding only Claude terminals, restored per directory.
-- Kept apart from persistence sessions so `vc` never overwrites the editor session of the same directory.
local terminals = require("claude.terminals")

local M = {}

local STATE_FILE = vim.fn.stdpath("state") .. "/claude-mode.json"
local SAVE_MS = 5000

local cwd = vim.fn.getcwd()
local leaving = false

local function read_all()
	local ok, all = pcall(vim.json.decode, table.concat(vim.fn.readfile(STATE_FILE), "\n"))
	return ok and type(all) == "table" and all or {}
end

-- Saved on a timer as well as on exit, so a killed terminal or a Mac restart still restores
local function save()
	if leaving then
		return
	end
	local entries = vim.tbl_filter(function(entry)
		return entry.session_id ~= nil
	end, terminals.snapshot())
	local all = vim.fn.filereadable(STATE_FILE) == 1 and read_all() or {}
	all[cwd] = #entries > 0 and entries or nil
	vim.fn.writefile({ vim.json.encode(all) }, STATE_FILE)
end

--- Restore this directory's Claude sessions (or start a new Claude) in one window,
--- with the info sidebar on the left and the token usage chart at the bottom.
--- `vc <claude args>` passes its arguments in CLAUDE_MODE_ARGS; they are used only when nothing is saved.
function M.start()
	local launch = vim.env.CLAUDE_MODE_ARGS
	vim.env.CLAUDE_MODE_ARGS = nil -- not for the Claude terminals' environment
	require("claude.caffeinate").start()
	local saved = vim.fn.filereadable(STATE_FILE) == 1 and read_all()[cwd] or {}
	if #saved > 0 then
		for _, entry in ipairs(saved) do
			terminals.restore(entry)
		end
	else
		terminals.open("vertical", { focus = false, launch = launch ~= "" and launch or nil })
	end
	-- Sidebar first so it spans the full height; the usage chart then spans the full width below
	require("claude.dashboard").open({ sidebar = true })
	require("claude.usage").open()
	vim.api.nvim_set_current_win(terminals.claude_window())
	vim.cmd.startinsert()

	local timer = vim.uv.new_timer()
	timer:start(SAVE_MS, SAVE_MS, vim.schedule_wrap(save))
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			save()
			leaving = true
			timer:stop()
		end,
	})
end

return M
