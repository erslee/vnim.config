-- Claude info buffer: limits, sessions, agents and loops, refreshed while visible
local sessions = require("claude.sessions")
local status = require("claude.status")
local terminals = require("claude.terminals")

local M = {}

local BUF_NAME = "claude://status"
local REFRESH_MS = 2000
local SIDEBAR_WIDTH = 44
local NS = vim.api.nvim_create_namespace("claude-dashboard")
local STATE_HL = { working = "DiagnosticInfo", waiting = "DiagnosticWarn", idle = "Comment" }

local buf, timer
local targets = {} -- line number -> terminal buffer to show

local function ago(timestamp)
	local seconds = math.max(0, os.time() - (timestamp or os.time()))
	if seconds < 60 then
		return seconds .. "s"
	elseif seconds < 3600 then
		return math.floor(seconds / 60) .. "m"
	end
	return math.floor(seconds / 3600) .. "h"
end

local function clock(timestamp)
	local same_day = os.date("%x", timestamp) == os.date("%x")
	return os.date(same_day and "%H:%M" or "%a %H:%M", timestamp)
end

-- Lines are lists of { text, highlight? } chunks, so highlights follow the text they belong to
local function render_lines(rows)
	local lines, marks = {}, {}
	for index, row in ipairs(rows) do
		local text, col = "", 0
		for _, chunk in ipairs(row) do
			if chunk[2] then
				table.insert(marks, { index - 1, col, col + #chunk[1], chunk[2] })
			end
			text = text .. chunk[1]
			col = col + #chunk[1]
		end
		lines[index] = text
	end
	return lines, marks
end

-- Two lines per session to fit the sidebar: state and directory, then model, context, cost and age.
-- ▶ marks a Claude shown in a window, ● one running hidden in this Neovim.
local function session_rows(rows, session, live_buf)
	local state = session.state
	local marker = not live_buf and "   " or vim.fn.bufwinid(live_buf) ~= -1 and " \u{25b6} " or " \u{25cf} "
	local first = #rows + 1
	table.insert(rows, {
		{ marker, "DiagnosticOk" },
		{ (status.STATE_ICONS[state] or " ") .. " " .. ("%-8s"):format(state), STATE_HL[state] },
		{ " " .. vim.fn.fnamemodify(session.cwd or "?", ":~"):sub(-28), "Directory" },
	})
	table.insert(rows, {
		{ ("     %s · ctx %s · %s"):format(
			(session.model or "-"):sub(1, 12),
			status.percent(session.context),
			session.cost and ("$%.2f"):format(session.cost) or "-"
		) },
		{ (" · %s · %s"):format(ago(session.updated), session.session_id:sub(1, 8)), "Comment" },
	})
	for _, agent in ipairs(session.agents) do
		table.insert(rows, {
			{ "     \u{f06a9} ", "Special" },
			{ ("%-22s "):format((agent.type or "subagent"):sub(1, 22)) },
			{ agent.started and ago(agent.started) or "", "Comment" },
		})
	end
	for _, loop in ipairs(session.loops) do
		local next_run = loop.next and loop.next > os.time() and ("next " .. clock(loop.next)) or "due"
		table.insert(rows, {
			{ "     \u{f0456} ", "Special" },
			{ ("%-22s "):format((loop.schedule or "?"):sub(1, 22)) },
			{ next_run, "Comment" },
		})
		table.insert(rows, { { "       " .. (loop.prompt or ""):gsub("\n", " "):sub(1, 34), "String" } })
	end
	for line = first, #rows do
		targets[line] = live_buf
	end
end

local function build()
	local all = sessions.all()
	local live_bufs = {}
	for _, term in ipairs(terminals.live()) do
		if term.session_id then
			live_bufs[term.session_id] = term.buf
		end
	end

	local counts, agents, loops = { working = 0, waiting = 0, idle = 0 }, 0, 0
	for _, session in ipairs(all) do
		counts[session.state] = (counts[session.state] or 0) + 1
		agents = agents + #session.agents
		loops = loops + #session.loops
	end

	targets = {}
	local rows = {
		{ { " \u{f09d1} Claude", "Title" }, { "  updated " .. os.date("%H:%M:%S"), "Comment" } },
		{ { " <CR> show · n new · p command · q close", "Comment" } },
		{},
	}
	local limits = status.rate_limit_text(sessions.rate_limits(all), true)
	for limit in vim.gsplit(limits or "no limits data yet", " · ", { plain = true }) do
		table.insert(rows, { { " " .. limit } })
	end
	table.insert(rows, {
		{ (" %d sessions · "):format(#all) },
		{ ("%d working"):format(counts.working), STATE_HL.working },
		{ " · " },
		{ ("%d waiting"):format(counts.waiting), STATE_HL.waiting },
	})
	table.insert(rows, { { (" %d idle · %d agents · %d loops"):format(counts.idle, agents, loops) } })
	for _, group in ipairs({ { "This Neovim", true }, { "Elsewhere", false } }) do
		local members = vim.tbl_filter(function(session)
			return (live_bufs[session.session_id] ~= nil) == group[2]
		end, all)
		if #members > 0 then
			table.insert(rows, {})
			table.insert(rows, { { " " .. group[1], "Title" } })
			for _, session in ipairs(members) do
				session_rows(rows, session, live_bufs[session.session_id])
			end
		end
	end
	if #all == 0 then
		table.insert(rows, {})
		table.insert(rows, { { " No Claude sessions in the last 12h", "Comment" } })
	end
	return render_lines(rows)
end

local function render()
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		return
	end
	local lines, marks = build()
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
	for _, mark in ipairs(marks) do
		vim.api.nvim_buf_set_extmark(buf, NS, mark[1], mark[2], { end_col = mark[3], hl_group = mark[4] })
	end
end

local function stop_timer()
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
end

local function start_timer()
	if not timer then
		timer = vim.uv.new_timer()
		timer:start(0, REFRESH_MS, vim.schedule_wrap(render))
	end
end

-- Show the Claude under the cursor in the Claude window (right of the sidebar) and focus it
local function show()
	local target = targets[vim.api.nvim_win_get_cursor(0)[1]]
	if not target then
		vim.notify("This session is not running in this Neovim", vim.log.levels.INFO)
		return
	end
	terminals.show(target)
	render()
end

local function create()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, BUF_NAME)
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].filetype = "claude-status"

	-- Refresh only while the buffer is shown in some window
	vim.api.nvim_create_autocmd("BufWinEnter", { buffer = buf, callback = start_timer })
	vim.api.nvim_create_autocmd("BufWinLeave", {
		buffer = buf,
		callback = function()
			if #vim.fn.win_findbuf(buf) <= 1 then
				stop_timer()
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", { buffer = buf, callback = stop_timer })

	local opts = { buffer = buf, nowait = true }
	vim.keymap.set("n", "<CR>", show, opts)
	vim.keymap.set("n", "R", render, opts)
	vim.keymap.set("n", "n", function()
		terminals.open("vertical")
	end, opts)
	vim.keymap.set("n", "p", function()
		require("claude.launch").prompt()
	end, opts)
	vim.keymap.set("n", "q", function()
		if vim.w.claude_info_sidebar then
			pcall(vim.api.nvim_win_close, 0, false)
			return
		end
		local ok = pcall(vim.cmd.buffer, "#")
		if not ok then
			vim.cmd.bprevious()
		end
	end, opts)
end

local function open_sidebar()
	vim.cmd("topleft " .. SIDEBAR_WIDTH .. "vsplit")
	vim.w.claude_info_sidebar = true
	vim.api.nvim_win_set_buf(0, buf)
	local wo = vim.wo[0][0]
	wo.winfixwidth = true
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.wrap = false
	wo.cursorline = true
end

--- Show the Claude info buffer (focus it if already visible)
---@param opts? { sidebar?: boolean } sidebar: a fixed-width window on the left instead of the current window
function M.open(opts)
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		create()
	end
	local win = vim.fn.bufwinid(buf)
	if win ~= -1 then
		vim.api.nvim_set_current_win(win)
	elseif opts and opts.sidebar then
		open_sidebar()
	else
		vim.api.nvim_win_set_buf(0, buf)
	end
	start_timer()
end

return M
