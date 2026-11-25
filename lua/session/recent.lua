-- Snacks dashboard section: recent Neovim sessions (persistence.nvim), with their Claude terminals
local M = {}

local function claude_count(session_file)
	for _, line in ipairs(vim.fn.readfile(session_file, "", 20)) do
		local json = line:match('^let ClaudeTerms = "(.*)"%s*$')
		if json then
			local ok, saved = pcall(vim.json.decode, (json:gsub('\\"', '"'):gsub("\\\\", "\\")))
			return ok and #saved or 0
		end
	end
	return 0
end

-- persistence names files "<dir with / as %>[%%<branch>].vim"
local function parse(session_file, sessions_dir)
	local name = session_file:sub(#sessions_dir + 1, -5)
	local dir, branch = unpack(vim.split(name, "%%", { plain = true }))
	return dir:gsub("%%", "/"), branch
end

local function load(session_file, dir)
	vim.fn.chdir(dir)
	local persistence = require("persistence")
	persistence.fire("LoadPre")
	vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
	persistence.fire("LoadPost")
end

---@param opts? { limit?: number }
function M.section(opts)
	local limit = (opts and opts.limit) or 8
	local sessions_dir = require("persistence.config").options.dir
	local items = {}
	for _, session_file in ipairs(require("persistence").list()) do
		local dir, branch = parse(session_file, sessions_dir)
		if vim.uv.fs_stat(dir) then
			local claudes = claude_count(session_file)
			local desc = vim.fn.fnamemodify(dir, ":~")
				.. (branch and ("  " .. branch) or "")
				.. (claudes > 0 and ("  \u{f09d1} " .. claudes) or "")
			table.insert(items, {
				icon = "\u{f07b} ",
				desc = desc,
				action = function()
					load(session_file, dir)
				end,
			})
			if #items >= limit then
				break
			end
		end
	end
	return items
end

return M
