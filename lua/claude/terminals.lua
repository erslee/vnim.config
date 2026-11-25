-- Claude terminals opened from this Neovim, each tagged so its session id can be found
local sessions = require("claude.sessions")

local M = {}

-- Must match the env passed to claudecode.nvim's own terminal (lua/plugins/claudecode.lua)
M.MAIN_TERM_ID = "main-" .. vim.fn.getpid()

local terms = {} -- term_id -> { buf = number, layout = "vertical" | "horizontal", session_id?: string }
local counter = 0
-- Session id a terminal was resumed with: covers the gap before its hooks report again
local main_resumed_session_id

local function ide_env(term_id)
	require("lazy").load({ plugins = { "claudecode.nvim" } })
	local port = require("claudecode").state.port
	return {
		CLAUDE_CODE_SSE_PORT = port and tostring(port) or nil,
		ENABLE_IDE_INTEGRATION = "true",
		FORCE_CODE_TERMINAL = "true",
		NVIM_CLAUDE_TERM = term_id,
	}
end

--- Open a new Claude in a split, connected to Neovim's IDE server
---@param layout "vertical"|"horizontal"
---@param opts? { args?: string, focus?: boolean, session_id?: string }
function M.open(layout, opts)
	opts = opts or {}
	counter = counter + 1
	local term_id = ("%d-%d"):format(vim.fn.getpid(), counter)
	local previous_win = vim.api.nvim_get_current_win()

	vim.cmd(layout == "vertical" and "vertical rightbelow new" or "horizontal rightbelow new")
	local cmd = "claude" .. (opts.args and (" " .. opts.args) or "")
	vim.fn.jobstart(cmd, { term = true, env = ide_env(term_id) })

	local buf = vim.api.nvim_get_current_buf()
	terms[term_id] = { buf = buf, layout = layout, session_id = opts.session_id }
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			terms[term_id] = nil
		end,
	})

	if opts.focus == false then
		vim.api.nvim_set_current_win(previous_win)
	else
		vim.cmd.startinsert()
	end
end

local function main_terminal_buf()
	if not package.loaded["claudecode"] then
		return nil
	end
	local ok, buf = pcall(require("claudecode.terminal").get_active_terminal_bufnr)
	return ok and buf or nil
end

--- Live Claude terminals of this Neovim, with their session ids when known
function M.live()
	local all_sessions = sessions.all()
	local live = {}
	local function add(term_id, buf, layout, resumed_session_id)
		if buf and vim.api.nvim_buf_is_valid(buf) then
			local session = sessions.by_term(all_sessions, term_id)
			table.insert(live, {
				term_id = term_id,
				buf = buf,
				layout = layout,
				session_id = session and session.session_id or resumed_session_id,
			})
		end
	end

	add(M.MAIN_TERM_ID, main_terminal_buf(), "main", main_resumed_session_id)
	for term_id, term in pairs(terms) do
		add(term_id, term.buf, term.layout, term.session_id)
	end
	return live
end

--- Reopen a saved terminal, resuming its conversation
---@param saved { layout: string, session_id?: string }
function M.restore(saved)
	local args = saved.session_id and ("--resume " .. saved.session_id) or "--continue"
	if saved.layout == "main" then
		main_resumed_session_id = saved.session_id
		require("lazy").load({ plugins = { "claudecode.nvim" } })
		require("claudecode.terminal").toggle_open_no_focus({}, args)
	else
		M.open(saved.layout, { args = args, focus = false, session_id = saved.session_id })
	end
end

return M
