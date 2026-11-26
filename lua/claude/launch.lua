-- Start a Claude from a pasted shell command: "[cd <dir> &&] claude [args...] [prompt]"
local terminals = require("claude.terminals")

local M = {}

--- Split a pasted command into the directory and the claude arguments
---@return { cwd?: string, launch?: string }|nil, string? error
function M.parse(text)
	local command = vim.trim((text:gsub("%s*\n%s*", " ")))
	local dir, rest = command:match("^cd%s+(.-)%s*&&%s*(.*)$")
	local args = (rest or command):match("^claude%f[%s%z]%s*(.*)$")
	if not args then
		return nil, "Expected: [cd <dir> &&] claude [args]"
	end
	-- The arguments run through the shell: one claude only, e.g. not "claude cd x && claude ..."
	if args:find("&&", 1, true) or args:find("[;|]") then
		return nil, "Only one claude command, without &&, ; or |: " .. args
	end
	local cwd = dir and vim.fn.expand(dir) or nil
	if cwd and vim.fn.isdirectory(cwd) == 0 then
		return nil, "No such directory: " .. cwd
	end
	return { cwd = cwd, launch = args ~= "" and args or nil }
end

-- The input box is a one-line prompt buffer where a pasted newline submits early:
-- join multi-line pastes (wrapped commands) into one line while the box is open
local function join_pastes()
	local paste = vim.paste
	vim.paste = function(lines, phase)
		local joined = table.concat(lines, "\n"):gsub("%s*\n%s*", " ")
		return paste({ joined }, phase)
	end
	return function()
		vim.paste = paste
	end
end

--- Ask for a command and open it in a new Claude split; its directory and arguments are reused on restore
function M.prompt()
	local restore_paste = join_pastes()
	local answered = false
	vim.ui.input({ prompt = "Claude command ([cd dir &&] claude args): " }, function(text)
		-- snacks.input can confirm twice (its <CR> action and the prompt buffer callback): start one Claude
		if answered then
			return
		end
		answered = true
		restore_paste()
		if not text or vim.trim(text) == "" then
			return
		end
		local parsed, err = M.parse(text)
		if not parsed then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
		terminals.open("vertical", { cwd = parsed.cwd, launch = parsed.launch })
	end)
end

return M
