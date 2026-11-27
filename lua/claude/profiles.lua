-- Claude profiles: config dirs (~/.claude, ~/.claude_<name>, ~/.claude-<name>) and a chooser between them
local M = {}

local HOME = vim.fn.expand("~")
local DEFAULT_DIR = HOME .. "/.claude"

local function normalize(dir)
	return (vim.fn.expand(dir):gsub("/+$", ""))
end

--- Short name of a config dir: "~/.claude_mts" -> "mts"; nil for the default ~/.claude (and for nil)
function M.name(config_dir)
	if not config_dir then
		return nil
	end
	local name = vim.fn.fnamemodify(normalize(config_dir), ":t"):gsub("^%.?claude[-_.]?", "")
	return name ~= "" and name or nil
end

--- CLAUDE_CONFIG_DIR for a config dir: nil for ~/.claude, which Claude must find unset,
--- or it looks for ~/.claude/.claude.json instead of ~/.claude.json and loses the login
function M.env_value(config_dir)
	local dir = normalize(config_dir)
	return dir ~= DEFAULT_DIR and dir or nil
end

--- Config dir this Neovim was started with
function M.current()
	return normalize(vim.env.CLAUDE_CONFIG_DIR or DEFAULT_DIR)
end

--- Config dirs on this machine, the current one first
function M.list()
	local current = M.current()
	local dirs = { current }
	local candidates = vim.list_extend({ DEFAULT_DIR }, vim.fn.glob(HOME .. "/.claude[_-]*", false, true))
	table.sort(candidates)
	for _, dir in ipairs(candidates) do
		dir = normalize(dir)
		if dir ~= current and vim.fn.isdirectory(dir) == 1 then
			table.insert(dirs, dir)
		end
	end
	return dirs
end

--- Ask which config dir a new Claude uses. With only one there is nothing to ask: callback(nil),
--- and the Claude keeps this Neovim's. Not called when the picker is dismissed.
---@param callback fun(config_dir?: string)
function M.choose(callback)
	local dirs = M.list()
	if #dirs <= 1 then
		callback(nil)
		return
	end
	local answered = false
	vim.ui.select(dirs, {
		prompt = "Claude profile",
		format_item = function(dir)
			return ("%-8s %s"):format(M.name(dir) or "claude", vim.fn.fnamemodify(dir, ":~"))
		end,
	}, function(dir)
		-- Some pickers confirm twice: start one Claude
		if dir and not answered then
			answered = true
			callback(dir)
		end
	end)
end

return M
