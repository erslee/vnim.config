-- Reads Claude session state written by scripts/claude-status
local M = {}

local MAX_AGE_SEC = 12 * 3600

M.dir = (vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state")) .. "/claude-status"

local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

local function read_json(path)
	local content = read_file(path)
	if not content or content == "" then
		return nil
	end
	local ok, value = pcall(vim.json.decode, content, { luanil = { object = true, array = true } })
	return ok and value or nil
end

local function mtime(path)
	local stat = vim.uv.fs_stat(path)
	return stat and stat.mtime.sec or 0
end

-- One JSON file per entry (agents, loops); older agent files are empty, so default to {}
local function read_entries(path)
	local entries = {}
	if vim.uv.fs_stat(path) then
		for name in vim.fs.dir(path) do
			local entry = read_json(path .. "/" .. name) or {}
			entry.id = name
			table.insert(entries, entry)
		end
	end
	return entries
end

-- A one-shot cron is gone once it has fired, and no hook reports that
local function active_loops(loops)
	local now = os.time()
	return vim.tbl_filter(function(loop)
		return loop.recurring ~= false or (loop.next or 0) > now
	end, loops)
end

local function load(session_id)
	local base = M.dir .. "/" .. session_id
	local meta = read_json(base .. ".meta.json") or {}
	local status = read_json(base .. ".status.json") or {}
	local state = vim.trim(read_file(base .. ".state") or "idle")
	local title = vim.trim(read_file(base .. ".title") or "")
	return {
		session_id = session_id,
		title = title ~= "" and title or nil,
		-- Sessions recorded before "started" existed: when their meta was written (their last start or resume)
		started = meta.started or mtime(base .. ".meta.json"),
		cwd = meta.cwd,
		nvim = meta.nvim,
		term = meta.term,
		state = state,
		model = status.model,
		context = status.context,
		cost = status.cost,
		rate_limits = status.rate_limits,
		reported = mtime(base .. ".status.json"),
		agents = read_entries(base .. ".agents"),
		loops = active_loops(read_entries(base .. ".loops")),
		updated = math.max(mtime(base .. ".meta.json"), mtime(base .. ".state"), mtime(base .. ".status.json")),
	}
end

--- All sessions updated recently, in a fixed order: by start, so a new session goes last
function M.all()
	local sessions = {}
	if not vim.uv.fs_stat(M.dir) then
		return sessions
	end
	local now = os.time()
	for name in vim.fs.dir(M.dir) do
		local session_id = name:match("^(.+)%.meta%.json$")
		if session_id then
			local session = load(session_id)
			if now - session.updated < MAX_AGE_SEC then
				table.insert(sessions, session)
			end
		end
	end
	table.sort(sessions, function(a, b)
		if a.started ~= b.started then
			return a.started < b.started
		end
		return a.session_id < b.session_id
	end)
	return sessions
end

--- Rate limits are account-wide: take the ones its status line reported last
function M.rate_limits(sessions)
	local latest
	for _, session in ipairs(sessions) do
		if session.rate_limits and (not latest or session.reported > latest.reported) then
			latest = session
		end
	end
	return latest and latest.rate_limits
end

--- Session whose terminal tag matches, if its hooks have reported
function M.by_term(sessions, term_id)
	for _, session in ipairs(sessions) do
		if session.term == term_id then
			return session
		end
	end
	return nil
end

return M
