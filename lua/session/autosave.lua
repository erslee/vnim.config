-- Debounced session autosave and its status for lualine
local M = {}

local DEBOUNCE_MS = 2000
local CHANGE_EVENTS = { "BufAdd", "BufDelete", "BufEnter", "TabClosed", "TabNew", "VimResized", "WinClosed", "WinNew" }

local enabled = false
local pending = false
local saved_at = nil
local timer = vim.uv.new_timer()

local function has_file_buffer()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
			return true
		end
	end
	return false
end

local function save()
	pending = false
	local persistence = require("persistence")
	if enabled and persistence.active() and has_file_buffer() then
		persistence.fire("SavePre")
		persistence.save()
		persistence.fire("SavePost")
	end
	vim.cmd.redrawstatus()
end

local function schedule_save()
	if not enabled or not require("persistence").active() then
		return
	end
	pending = true
	timer:stop()
	timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(save))
end

--- Autosave only sessions in use (restored or loaded), so a one-off `nvim file` never overwrites them early
function M.enable()
	enabled = true
end

--- A freshly loaded session matches its file
function M.mark_saved()
	pending = false
	saved_at = os.time()
end

function M.setup()
	local group = vim.api.nvim_create_augroup("session-autosave", { clear = true })
	vim.api.nvim_create_autocmd(CHANGE_EVENTS, { group = group, callback = schedule_save })
	vim.api.nvim_create_autocmd("FocusLost", {
		group = group,
		callback = function()
			if enabled then
				timer:stop()
				save()
			end
		end,
	})
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "PersistenceSavePost",
		callback = function()
			saved_at = os.time()
		end,
	})
end

function M.status()
	if not require("persistence").active() then
		return "\u{f0193} off"
	end
	if not enabled then
		return "\u{f0193} on exit"
	end
	if pending then
		return "\u{f0996} saving"
	end
	if saved_at then
		return "\u{f0193} " .. os.date("%H:%M", saved_at)
	end
	return "\u{f0193} unsaved"
end

function M.status_color()
	if not require("persistence").active() then
		return { fg = "#FF5555" }
	end
	if pending or (enabled and not saved_at) then
		return { fg = "#FFB86C" }
	end
	return nil
end

return M
