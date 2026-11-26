-- Keeps the Mac from idle-sleeping while Claude works (`vc` starts it); the screen may still sleep
local M = {}

local job
local used = false

-- -i: no idle system sleep; -w: released when this Neovim exits, even on a crash
local function command()
	return { "caffeinate", "-i", "-w", tostring(vim.fn.getpid()) }
end

function M.running()
	return job ~= nil
end

function M.start()
	if job then
		return
	end
	used = true
	job = vim.fn.jobstart(command(), {
		on_exit = function()
			job = nil
			vim.schedule(vim.cmd.redrawtabline)
		end,
	})
	if job <= 0 then
		job = nil
		vim.notify("caffeinate failed to start", vim.log.levels.ERROR)
	end
	vim.cmd.redrawtabline()
end

function M.stop()
	if job then
		vim.fn.jobstop(job)
	end
end

function M.toggle()
	if job then
		M.stop()
		vim.notify("Caffeinate off: the Mac may sleep")
	else
		M.start()
		vim.notify("Caffeinate on: the Mac stays awake")
	end
end

--- Shown once caffeinate has been used in this Neovim (always in `vc`)
function M.visible()
	return used
end

function M.status()
	return "\u{f0176} " .. (job and "awake" or "off")
end

function M.status_color()
	return not job and { fg = "#6272A4" } or nil
end

return M
