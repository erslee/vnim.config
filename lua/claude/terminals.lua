-- Claude terminals opened from this Neovim, each tagged so its session id can be found
local sessions = require("claude.sessions")

local M = {}

-- Must match the env passed to claudecode.nvim's own terminal (lua/plugins/claudecode.lua)
M.MAIN_TERM_ID = "main-" .. vim.fn.getpid()

-- term_id -> { buf, layout = "vertical" | "horizontal", session_id?, launch? (claude args to reuse on restore), cwd? }
local terms = {}
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

-- In `vc` all Claudes share one window, right of the info sidebar
local function shared_window()
	return vim.g.claude_mode == 1
end

local function usable(win)
	return vim.api.nvim_win_is_valid(win)
		and vim.api.nvim_win_get_config(win).relative == ""
		and not vim.w[win].claude_info_sidebar
		and not vim.w[win].claude_usage
end

--- The window to show a Claude in: the current one unless it is the info sidebar or the usage chart
function M.claude_window()
	local current = vim.api.nvim_get_current_win()
	if usable(current) then
		return current
	end
	local previous = vim.fn.win_getid(vim.fn.winnr("#"))
	if previous ~= 0 and usable(previous) then
		return previous
	end
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if usable(win) then
			return win
		end
	end
	-- Only the sidebar is left: split it, the Claude replaces its buffer in the new window
	vim.cmd("botright vsplit")
	vim.w.claude_info_sidebar = nil
	vim.wo.winfixwidth = false
	return vim.api.nvim_get_current_win()
end

--- Focus a Claude terminal, showing it in the Claude window if it is not visible
function M.show(buf)
	local win = vim.fn.bufwinid(buf)
	if win == -1 then
		win = M.claude_window()
		vim.api.nvim_win_set_buf(win, buf)
	end
	vim.api.nvim_set_current_win(win)
end

-- Exited Claude: drop its buffer (which closes its windows); `vc` shows another Claude in its window
-- and quits with its last Claude
local function close_exited(buf)
	if shared_window() then
		local others = vim.tbl_filter(function(term)
			return term.buf ~= buf
		end, M.live())
		for _, win in ipairs(others[1] and vim.fn.win_findbuf(buf) or {}) do
			vim.api.nvim_win_set_buf(win, others[1].buf)
		end
	end
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_delete(buf, { force = true })
	end
	if shared_window() and #M.live() == 0 then
		vim.cmd("qall")
	end
end

-- Focusing a Claude terminal goes straight to typing; <C-\>n/s/p/k work while typing
local function setup_buffer(buf)
	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
		buffer = buf,
		callback = function()
			vim.schedule(function()
				if vim.api.nvim_get_current_buf() == buf and vim.fn.mode() ~= "t" then
					vim.cmd.startinsert()
				end
			end)
		end,
	})
	vim.keymap.set("t", "<C-\\>n", function()
		M.open("vertical")
	end, { buffer = buf, desc = "New Claude" })
	vim.keymap.set("t", "<C-\\>N", function()
		M.open("vertical", { here = true })
	end, { buffer = buf, desc = "New Claude in this window" })
	vim.keymap.set("t", "<C-\\>p", function()
		require("claude.launch").prompt()
	end, { buffer = buf, desc = "New Claude from command" })
	vim.keymap.set("t", "<C-\\>k", function()
		require("claude.caffeinate").toggle()
	end, { buffer = buf, desc = "Toggle caffeinate" })
	vim.keymap.set("t", "<C-\\>s", function()
		require("claude.dashboard").open({ sidebar = true })
	end, { buffer = buf, desc = "Claude info" })
end

--- Open a new Claude connected to Neovim's IDE server
---@param layout "vertical"|"horizontal"
--- here (and always in `vc`): in the current window, or the Claude window when in the info sidebar; else a split
---@param opts? { args?: string, launch?: string, cwd?: string, focus?: boolean, session_id?: string, here?: boolean }
function M.open(layout, opts)
	opts = opts or {}
	counter = counter + 1
	local term_id = ("%d-%d"):format(vim.fn.getpid(), counter)
	local previous_win = vim.api.nvim_get_current_win()

	vim.api.nvim_set_current_win(M.claude_window())
	if shared_window() or opts.here then
		vim.cmd.enew()
	else
		vim.cmd(layout == "vertical" and "vertical rightbelow new" or "horizontal rightbelow new")
	end
	local buf = vim.api.nvim_get_current_buf()
	local args = opts.args or opts.launch
	local cmd = "claude" .. (args and (" " .. args) or "")
	vim.fn.jobstart(cmd, {
		term = true,
		cwd = opts.cwd,
		env = ide_env(term_id),
		on_exit = function()
			vim.schedule(function()
				close_exited(buf)
			end)
		end,
	})

	terms[term_id] = { buf = buf, layout = layout, session_id = opts.session_id, launch = opts.launch, cwd = opts.cwd }
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			terms[term_id] = nil
		end,
	})
	setup_buffer(buf)

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
	local function add(term_id, term)
		if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
			local session = sessions.by_term(all_sessions, term_id)
			table.insert(live, {
				term_id = term_id,
				buf = term.buf,
				layout = term.layout,
				session_id = session and session.session_id or term.session_id,
				launch = term.launch,
				cwd = term.cwd,
			})
		end
	end

	add(M.MAIN_TERM_ID, { buf = main_terminal_buf(), layout = "main", session_id = main_resumed_session_id })
	for term_id, term in pairs(terms) do
		add(term_id, term)
	end
	-- Opening order (buffer numbers grow), so a restore puts them back left to right
	table.sort(live, function(a, b)
		return a.buf < b.buf
	end)
	return live
end

--- What a restore needs, for every live terminal
function M.snapshot()
	return vim.tbl_map(function(term)
		return { layout = term.layout, session_id = term.session_id, launch = term.launch, cwd = term.cwd }
	end, M.live())
end

--- Reopen a saved terminal, resuming its conversation with the arguments it was launched with
---@param saved { layout?: string, session_id?: string, launch?: string, cwd?: string }
function M.restore(saved)
	local resume = saved.session_id and ("--resume " .. saved.session_id) or "--continue"
	local args = resume .. (saved.launch and (" " .. saved.launch) or "")
	if saved.layout == "main" then
		main_resumed_session_id = saved.session_id
		require("lazy").load({ plugins = { "claudecode.nvim" } })
		require("claudecode.terminal").toggle_open_no_focus({}, args)
	else
		M.open(saved.layout or "vertical", {
			args = args,
			launch = saved.launch,
			cwd = saved.cwd,
			session_id = saved.session_id,
			focus = false,
		})
	end
end

return M
