-- `vc` Claudes run in hidden tmux sessions, so they keep running after their Neovim closes and any `vc` can attach.
-- Without tmux, Claudes run as plain terminals (see lua/claude/terminals.lua).
local M = {}

local SOCKET = "claude-nvim"
local CONFIG = vim.fn.stdpath("config") .. "/scripts/claude-tmux.conf"

function M.available()
	return vim.fn.executable("tmux") == 1
end

local function tmux(args)
	return vim.list_extend({ "tmux", "-L", SOCKET, "-f", CONFIG }, args)
end

-- The session is named after the terminal id the Claude reports in its hooks (NVIM_CLAUDE_TERM)
local function session_name(term_id)
	return "claude-" .. term_id
end

--- Start a Claude command in a detached session; true when it is running.
--- Its launch arguments are kept on the session, so another `vc` attaching to it can restore it the same way.
---@param env table<string, string>
function M.start(term_id, command, cwd, env, launch)
	local name = session_name(term_id)
	local args = { "new-session", "-d", "-s", name, "-c", cwd }
	for key, value in pairs(env) do
		vim.list_extend(args, { "-e", key .. "=" .. value })
	end
	vim.list_extend(args, { command, ";", "set-option", "-t", name, "@launch", launch or "" })
	return vim.system(tmux(args)):wait().code == 0
end

--- Command for a terminal showing the session (a tmux client: closing it only detaches)
function M.attach_command(term_id)
	return tmux({ "attach-session", "-t", "=" .. session_name(term_id) })
end

--- Command for a shell kept per directory: attaches to it, starting it the first time
function M.shell_command(cwd)
	-- tmux session names cannot hold "." or ":", so the directory is hashed
	local name = "shell-" .. vim.fn.sha256(cwd):sub(1, 12)
	return tmux({ "new-session", "-A", "-s", name, "-c", cwd })
end

--- Running Claude sessions: term_id -> { clients = attached Neovims, cwd, launch? }
function M.sessions()
	if not M.available() then
		return {}
	end
	local format = "#{session_name}\t#{session_attached}\t#{session_path}\t#{@launch}"
	local result = vim.system(tmux({ "list-sessions", "-F", format }), { text = true }):wait()
	local sessions = {}
	for line in (result.stdout or ""):gmatch("[^\n]+") do
		local name, clients, cwd, launch = unpack(vim.split(line, "\t", { plain = true }))
		local term_id = name:match("^claude%-(.+)$")
		if term_id then
			sessions[term_id] = { clients = tonumber(clients) or 0, cwd = cwd, launch = launch ~= "" and launch or nil }
		end
	end
	return sessions
end

return M
