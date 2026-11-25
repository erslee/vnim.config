-- Claude status for lualine and a floating dashboard
local sessions = require("claude.sessions")
local terminals = require("claude.terminals")

local M = {}

local REFRESH_MS = 2000
local STATE_ICONS = { working = "\u{f110}", waiting = "\u{f071}", idle = "\u{f186}" }

local function percent(value)
	return value and ("%d%%"):format(math.floor(value)) or "-"
end

local function rate_limit_text(rate_limits, with_reset)
	if not rate_limits then
		return nil
	end
	local parts = {}
	for _, window in ipairs({ { "five_hour", "5h", "%H:%M" }, { "seven_day", "7d", "%a %H:%M" } }) do
		local limit = rate_limits[window[1]]
		if limit then
			local text = window[2] .. " " .. percent(limit.used_percentage)
			if with_reset and limit.resets_at then
				text = text .. " (resets " .. os.date(window[3], limit.resets_at) .. ")"
			end
			table.insert(parts, text)
		end
	end
	return #parts > 0 and table.concat(parts, "  ") or nil
end

-- Statusline: cached, refreshed on a timer so lualine never touches the disk
local cache = { text = "", waiting = false }
local timer

local function refresh()
	local all = sessions.all()
	local counts, agents = { working = 0, waiting = 0, idle = 0 }, 0
	for _, term in ipairs(terminals.live()) do
		local session = term.session_id and sessions.by_term(all, term.term_id)
		local state = session and session.state or "idle"
		counts[state] = (counts[state] or 0) + 1
		agents = agents + (session and session.agents or 0)
	end

	local parts = {}
	for _, state in ipairs({ "working", "waiting", "idle" }) do
		if counts[state] > 0 then
			table.insert(parts, STATE_ICONS[state] .. " " .. counts[state])
		end
	end
	if agents > 0 then
		table.insert(parts, "\u{f06a9} " .. agents)
	end
	table.insert(parts, rate_limit_text(sessions.rate_limits(all), false))

	cache = { text = #parts > 0 and ("\u{f09d1} " .. table.concat(parts, "  ")) or "", waiting = counts.waiting > 0 }
end

function M.statusline()
	if not timer then
		timer = vim.uv.new_timer()
		timer:start(0, REFRESH_MS, vim.schedule_wrap(refresh))
	end
	return cache.text
end

function M.has_status()
	return cache.text ~= ""
end

function M.statusline_color()
	return cache.waiting and { fg = "#FFB86C" } or nil
end

-- Dashboard
local function dashboard_lines()
	local all = sessions.all()
	local live_bufs = {}
	for _, term in ipairs(terminals.live()) do
		if term.session_id then
			live_bufs[term.session_id] = term.buf
		end
	end

	local lines = { " Rate limits: " .. (rate_limit_text(sessions.rate_limits(all), true) or "no data yet"), "" }
	local targets = {}
	table.insert(lines, (" %-2s %-8s %-24s %-12s %5s %7s %6s %s"):format("", "state", "project", "model", "ctx", "cost", "agents", "updated"))
	for _, session in ipairs(all) do
		local here = live_bufs[session.session_id] and "●" or " "
		table.insert(lines, (" %-2s %-8s %-24s %-12s %5s %7s %6d %s"):format(
			here,
			session.state,
			vim.fn.fnamemodify(session.cwd or "?", ":t"):sub(1, 24),
			(session.model or "-"):sub(1, 12),
			percent(session.context),
			session.cost and ("$%.2f"):format(session.cost) or "-",
			session.agents,
			os.date("%H:%M:%S", session.updated)
		))
		targets[#lines] = live_bufs[session.session_id]
	end
	if #all == 0 then
		table.insert(lines, " No Claude sessions reported yet")
	end
	table.insert(lines, "")
	table.insert(lines, " ● = running in this Neovim · <CR> jump · q close")
	return lines, targets
end

function M.dashboard()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.min(100, vim.o.columns - 4)
	local height = math.min(20, vim.o.lines - 6)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		title = " Claude sessions ",
		title_pos = "center",
	})
	vim.bo[buf].bufhidden = "wipe"

	local targets = {}
	local function render()
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end
		local lines
		lines, targets = dashboard_lines()
		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false
	end

	local dashboard_timer = vim.uv.new_timer()
	dashboard_timer:start(0, REFRESH_MS, vim.schedule_wrap(render))
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			dashboard_timer:stop()
			dashboard_timer:close()
		end,
	})

	local function close()
		pcall(vim.api.nvim_win_close, win, true)
	end
	vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<CR>", function()
		local target = targets[vim.api.nvim_win_get_cursor(win)[1]]
		if target then
			close()
			local target_win = vim.fn.bufwinid(target)
			if target_win ~= -1 then
				vim.api.nvim_set_current_win(target_win)
			else
				vim.cmd("vertical rightbelow sbuffer " .. target)
			end
		end
	end, { buffer = buf })
end

return M
