-- Claude info buffer: limits, sessions, agents and loops, refreshed while visible
local sessions = require("claude.sessions")
local status = require("claude.status")
local terminals = require("claude.terminals")
local tmux = require("claude.tmux")
local tree = require("claude.tree")

local M = {}

local BUF_NAME = "claude://status"
local REFRESH_MS = 2000
local SIDEBAR_WIDTH = 44
local NS = vim.api.nvim_create_namespace("claude-dashboard")
local STATE_HL = { working = "DiagnosticInfo", waiting = "DiagnosticWarn", idle = "Comment" }

local buf, timer
local targets = {} -- line number -> terminal buffer to show, or a Claude running in tmux to attach

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

-- A session: its name, then directory and model/context/cost/age, with its agents and loops as children.
-- ▶ marks a Claude shown in a window, ● one running hidden in this Neovim, ○ one running in tmux that <CR> attaches.
local function session_node(session, live_buf, running)
	local marker = live_buf and (vim.fn.bufwinid(live_buf) ~= -1 and "\u{25b6} " or "\u{25cf} ")
		or running and "\u{25cb} "
		or "  "
	local dir = vim.fn.fnamemodify(session.cwd or "?", ":~")
	local children = {}
	for _, agent in ipairs(session.agents) do
		table.insert(children, {
			line = {
				{ "\u{f06a9} ", "Special" },
				{ agent.type or "subagent" },
				{ agent.started and (" · " .. ago(agent.started)) or "", "Comment" },
			},
		})
	end
	for _, loop in ipairs(session.loops) do
		local next_run = loop.next and loop.next > os.time() and ("next " .. clock(loop.next)) or "due"
		table.insert(children, {
			line = { { "\u{f0456} ", "Special" }, { loop.schedule or "?" }, { " · " .. next_run, "Comment" } },
			details = { { { (loop.prompt or ""):gsub("\n", " "), "String" } } },
		})
	end
	local line = {
		{ marker, "DiagnosticOk" },
		{ (status.STATE_ICONS[session.state] or " ") .. " ", STATE_HL[session.state] },
		{ session.title or vim.fn.fnamemodify(dir, ":t"), "Bold" },
	}
	if session.profile then
		table.insert(line, { " " .. session.profile, status.profile_hl(session.profile) })
	end
	return {
		target = live_buf
			or running and { term_id = session.term, session_id = session.session_id, cwd = running.cwd, launch = running.launch },
		line = line,
		details = {
			{ { #dir > 34 and ("…" .. dir:sub(-33)) or dir, "Directory" } },
			{ { ("%s · ctx %s · %s · %s"):format(
				session.model or "-",
				status.percent(session.context),
				session.cost and ("$%.2f"):format(session.cost) or "-",
				ago(session.updated)
			), "Comment" } },
		},
		children = children,
	}
end

-- Sessions without loops first, then the looping ones on their own branch
local function group_nodes(members, live_bufs, running)
	local nodes, looping = {}, {}
	for _, session in ipairs(members) do
		local node = session_node(session, live_bufs[session.session_id], running[session.term])
		table.insert(#session.loops > 0 and looping or nodes, node)
	end
	if #looping > 0 then
		table.insert(nodes, { line = { { "\u{f0456} with loops", "Comment" } }, children = looping })
	end
	return nodes
end

local function add_limits(rows, all, profile, indent)
	local limits = status.rate_limit_text(sessions.rate_limits(all, profile), true)
	for limit in vim.gsplit(limits or "no limits data yet", " · ", { plain = true }) do
		table.insert(rows, { { indent .. limit } })
	end
end

-- Limits are per account, so one block per profile once sessions use more than one config dir
local function add_all_limits(rows, all)
	local keys, seen = {}, {}
	for _, session in ipairs(all) do
		local key = session.profile or ""
		if not seen[key] then
			seen[key] = true
			table.insert(keys, key)
		end
	end
	table.sort(keys) -- "" (~/.claude) first
	if #keys <= 1 then
		add_limits(rows, all, keys[1] ~= "" and keys[1] or nil, " ")
		return
	end
	for _, key in ipairs(keys) do
		local profile = key ~= "" and key or nil
		table.insert(rows, { { " " .. (profile or "claude"), profile and status.profile_hl(profile) or "Bold" } })
		add_limits(rows, all, profile, "   ")
	end
end

local function build(width)
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
	add_all_limits(rows, all)
	table.insert(rows, {
		{ (" %d sessions · "):format(#all) },
		{ ("%d working"):format(counts.working), STATE_HL.working },
		{ " · " },
		{ ("%d waiting"):format(counts.waiting), STATE_HL.waiting },
	})
	table.insert(rows, { { (" %d idle · %d agents · %d loops"):format(counts.idle, agents, loops) } })
	-- Background: Claudes still running in tmux that no Neovim shows (their `vc` was closed)
	local running = tmux.sessions()
	local function group_of(session)
		if live_bufs[session.session_id] then
			return "This Neovim"
		end
		local tmux_session = running[session.term or ""]
		return tmux_session and tmux_session.clients == 0 and "Background" or "Elsewhere"
	end
	for _, group in ipairs({ "This Neovim", "Background", "Elsewhere" }) do
		local members = vim.tbl_filter(function(session)
			return group_of(session) == group
		end, all)
		if #members > 0 then
			table.insert(rows, {})
			table.insert(rows, { { " " .. group, "Title" } })
			tree.add(rows, targets, group_nodes(members, live_bufs, running), " ")
		end
	end
	if #all == 0 then
		table.insert(rows, {})
		table.insert(rows, { { " No Claude sessions in the last 12h", "Comment" } })
	end
	return tree.render_lines(rows, width)
end

local function render()
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		return
	end
	local win = vim.fn.bufwinid(buf)
	local lines, marks = build(win ~= -1 and vim.api.nvim_win_get_width(win) or SIDEBAR_WIDTH)
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
	if type(target) == "table" then
		terminals.attach(target)
	else
		terminals.show(target)
	end
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
