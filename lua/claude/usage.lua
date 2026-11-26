-- Claude token usage over the last 24h as a bar chart, in a full-width window at the bottom
local M = {}

local BUF_NAME = "claude://usage"
local SCRIPT = vim.fn.stdpath("config") .. "/scripts/claude-usage"
local MINUTES = 24 * 60
local REFRESH_MS = 60 * 1000
local CHART_ROWS = 6
local HEIGHT = CHART_ROWS + 2 -- title and time axis
local LABEL_WIDTH = 7
local BLOCKS = { " ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
local NS = vim.api.nvim_create_namespace("claude-usage")

local buf, timer, loading
local per_minute -- token counts, oldest minute first
local updated

local function human(count)
	if count >= 1e6 then
		return ("%.1fM"):format(count / 1e6)
	elseif count >= 1e3 then
		return ("%dk"):format(math.floor(count / 1e3 + 0.5))
	end
	return tostring(math.floor(count))
end

local function sum(from, to)
	local total = 0
	for minute = from, to do
		total = total + per_minute[minute]
	end
	return total
end

-- One column per screen cell: each sums an equal slice of the minutes
local function columns(count)
	local result = {}
	for column = 1, count do
		local from = math.floor((column - 1) * MINUTES / count) + 1
		result[column] = sum(from, math.floor(column * MINUTES / count))
	end
	return result
end

-- Bars grow in eighths of a row; any usage shows at least the lowest block
local function chart_lines(values, peak)
	local lines = {}
	for row = CHART_ROWS, 1, -1 do
		local cells = {}
		for column, value in ipairs(values) do
			local eighths = value > 0 and math.max(1, math.floor(value / peak * CHART_ROWS * 8 + 0.5)) or 0
			cells[column] = BLOCKS[math.min(8, math.max(0, eighths - (row - 1) * 8)) + 1]
		end
		local label = row == CHART_ROWS and human(peak) or row == 1 and "0" or ""
		table.insert(lines, ("%" .. (LABEL_WIDTH - 2) .. "s ┤"):format(label) .. table.concat(cells))
	end
	return lines
end

-- Clock labels under the columns where a whole hour step starts, spaced so they never touch
local function axis_line(count)
	local minutes_per_column = MINUTES / count
	local step = 1
	for _, hours in ipairs({ 1, 2, 3, 4, 6, 12 }) do
		step = hours
		if hours * 60 / minutes_per_column >= 7 then
			break
		end
	end
	local start = os.time() - MINUTES * 60
	local cells = vim.split((" "):rep(count), "")
	local column = 1
	while column <= count do
		local time = start + (column - 1) * minutes_per_column * 60
		local next_time = time + minutes_per_column * 60
		local hour_mark = math.ceil(time / 3600) * 3600
		if hour_mark < next_time and tonumber(os.date("%H", hour_mark)) % step == 0 and column + 4 <= count then
			for offset, char in ipairs(vim.split(os.date("%H:%M", hour_mark), "")) do
				cells[column + offset - 1] = char
			end
			column = column + 6
		else
			column = column + 1
		end
	end
	return (" "):rep(LABEL_WIDTH) .. table.concat(cells)
end

local function render()
	local win = buf and vim.fn.bufwinid(buf) or -1
	if win == -1 then
		return
	end
	local lines
	if not per_minute then
		lines = { " Token usage · loading…" }
	else
		local count = math.max(10, vim.api.nvim_win_get_width(win) - LABEL_WIDTH)
		local values = columns(count)
		local peak = math.max(1, unpack(values))
		lines = {
			(" Token usage · last 24h %s · last hour %s · peak %s per %dm · in+out+cache writes · updated %s"):format(
				human(sum(1, MINUTES)),
				human(sum(MINUTES - 59, MINUTES)),
				human(peak),
				math.floor(MINUTES / count + 0.5),
				os.date("%H:%M", updated)
			),
		}
		vim.list_extend(lines, chart_lines(values, peak))
		table.insert(lines, axis_line(count))
	end
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
	vim.api.nvim_buf_set_extmark(buf, NS, 0, 0, { end_row = 1, hl_group = "Title", hl_eol = false })
	for row = 1, #lines - 2 do
		vim.api.nvim_buf_set_extmark(buf, NS, row, 0, { end_col = LABEL_WIDTH, hl_group = "Comment" })
		vim.api.nvim_buf_set_extmark(buf, NS, row, LABEL_WIDTH, { end_row = row + 1, hl_group = "DiagnosticInfo" })
	end
	if #lines > 2 then
		vim.api.nvim_buf_set_extmark(buf, NS, #lines - 1, 0, { end_row = #lines, hl_group = "Comment" })
	end
end

-- Scanning every transcript takes about a second: run it in the background
local function load()
	if loading then
		return
	end
	loading = true
	vim.system({ SCRIPT, tostring(MINUTES) }, { text = true }, function(result)
		vim.schedule(function()
			loading = false
			local ok, data = pcall(vim.json.decode, result.stdout or "")
			if result.code == 0 and ok and type(data) == "table" and #data == MINUTES then
				per_minute, updated = data, os.time()
				render()
			end
		end)
	end)
end

local function stop_timer()
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
end

local function create()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, BUF_NAME)
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].filetype = "claude-usage"
	-- Load only while shown; redraw on resize from the cached minutes
	vim.api.nvim_create_autocmd("BufWinEnter", {
		buffer = buf,
		callback = function()
			if not timer then
				timer = vim.uv.new_timer()
				timer:start(0, REFRESH_MS, vim.schedule_wrap(load))
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWinLeave", { buffer = buf, callback = stop_timer })
	vim.api.nvim_create_autocmd("BufWipeout", { buffer = buf, callback = stop_timer })
	vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
		callback = function()
			if buf and vim.api.nvim_buf_is_valid(buf) then
				render()
			end
		end,
	})
	vim.keymap.set("n", "q", function()
		pcall(vim.api.nvim_win_close, 0, false)
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "R", load, { buffer = buf, nowait = true })
end

--- Show the token usage chart across the bottom of the screen (focus stays where it was)
function M.open()
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		create()
	end
	if vim.fn.bufwinid(buf) ~= -1 then
		return
	end
	local previous = vim.api.nvim_get_current_win()
	vim.cmd("botright " .. HEIGHT .. "split")
	vim.w.claude_usage = true
	vim.api.nvim_win_set_buf(0, buf)
	local wo = vim.wo[0][0]
	wo.winfixheight = true
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.wrap = false
	wo.cursorline = false
	vim.api.nvim_set_current_win(previous)
	render()
end

return M
