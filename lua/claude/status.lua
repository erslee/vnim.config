-- Claude status for lualine and a floating dashboard
local sessions = require("claude.sessions")
local terminals = require("claude.terminals")

local M = {}

local REFRESH_MS = 2000
M.STATE_ICONS = { working = "\u{f110}", waiting = "\u{f071}", idle = "\u{f186}" }
-- Profiles (config dirs other than ~/.claude) get a color picked from their name, the same everywhere.
-- Orange stays free for "waiting".
local PROFILE_COLORS = { "#8BE9FD", "#BD93F9", "#FF79C6", "#50FA7B", "#F1FA8C" }

function M.profile_color(profile)
	local sum = 0
	for i = 1, #profile do
		sum = sum + profile:byte(i)
	end
	return PROFILE_COLORS[sum % #PROFILE_COLORS + 1]
end

--- Highlight group for a profile's badge; set on every call so a colorscheme change can't clear it
function M.profile_hl(profile)
	local name = "ClaudeProfile_" .. profile:gsub("[^%w]", "_")
	vim.api.nvim_set_hl(0, name, { fg = M.profile_color(profile), bold = true })
	return name
end

function M.percent(value)
	return value and ("%d%%"):format(math.floor(value)) or "-"
end

function M.rate_limit_text(rate_limits, with_reset)
	if not rate_limits then
		return nil
	end
	local parts = {}
	for _, window in ipairs({ { "five_hour", "5h", "%H:%M" }, { "seven_day", "7d", "%a %H:%M" } }) do
		local limit = rate_limits[window[1]]
		if limit then
			local text = window[2] .. " " .. M.percent(limit.used_percentage)
			if with_reset and limit.resets_at then
				text = text .. " (resets " .. os.date(window[3], limit.resets_at) .. ")"
			end
			table.insert(parts, text)
		end
	end
	return #parts > 0 and table.concat(parts, " · ") or nil
end

-- Statusline: cached per Claude terminal buffer, refreshed on a timer so lualine never touches the disk
local cache = {} -- buf -> { text = string, waiting = boolean, profile? = string }
local timer

local function terminal_text(session, limits)
	local parts = {}
	if session then
		table.insert(parts, M.STATE_ICONS[session.state] or M.STATE_ICONS.idle)
		if #session.agents > 0 then
			table.insert(parts, "\u{f06a9} " .. #session.agents)
		end
	end
	local info = {}
	if session and session.model then
		table.insert(info, session.model)
	end
	if session and session.context then
		table.insert(info, "ctx " .. M.percent(session.context))
	end
	table.insert(info, limits)
	if #info > 0 then
		table.insert(parts, table.concat(info, " · "))
	end
	return "\u{f09d1} " .. table.concat(parts, "  ")
end

local function refresh()
	local all = sessions.all()
	local fresh = {}
	for _, term in ipairs(terminals.live()) do
		local session = sessions.by_term(all, term.term_id)
		local profile = session and session.profile
		local limits = M.rate_limit_text(sessions.rate_limits(all, profile), false)
		fresh[term.buf] = {
			text = terminal_text(session, limits),
			waiting = session and session.state == "waiting",
			profile = profile,
		}
	end
	cache = fresh
end

-- Started lazily by whichever lualine callback runs first (cond runs before the component)
local function ensure_refreshing()
	if not timer then
		timer = vim.uv.new_timer()
		timer:start(0, REFRESH_MS, vim.schedule_wrap(refresh))
	end
end

-- lualine evaluates each window's statusline with that window current
local function window_entry()
	ensure_refreshing()
	return cache[vim.api.nvim_get_current_buf()]
end

function M.statusline()
	local entry = window_entry()
	-- "%" starts a statusline item: "ctx 10%" must be "ctx 10%%"
	return entry and (entry.text:gsub("%%", "%%%%")) or ""
end

function M.has_status()
	return window_entry() ~= nil
end

function M.statusline_color()
	local entry = window_entry()
	return entry and entry.waiting and { fg = "#FFB86C" } or nil
end

--- Profile badge of the Claude in this window, or nil for ~/.claude
function M.profile()
	local entry = window_entry()
	return entry and entry.profile
end

function M.profile_badge_color()
	local profile = M.profile()
	return profile and { fg = M.profile_color(profile), gui = "bold" } or nil
end

return M
