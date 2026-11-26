-- Text rows for the Claude info buffer: rows of highlighted chunks, drawn as a tree and cut to the window width
local M = {}

-- Cut a row to the width, ending with … where it was cut
local function fit(row, width)
	local fitted, used = {}, 0
	for _, chunk in ipairs(row) do
		local chunk_width = vim.fn.strdisplaywidth(chunk[1])
		if used + chunk_width > width then
			table.insert(fitted, { vim.fn.strcharpart(chunk[1], 0, math.max(0, width - used - 1)) .. "…", chunk[2] })
			return fitted
		end
		used = used + chunk_width
		table.insert(fitted, chunk)
	end
	return fitted
end

--- Rows are lists of { text, highlight? } chunks, so highlights follow the text they belong to
---@return string[] lines, table[] marks { row, start_col, end_col, highlight }
function M.render_lines(rows, width)
	local lines, marks = {}, {}
	for index, row in ipairs(rows) do
		local text, col = "", 0
		for _, chunk in ipairs(fit(row, width)) do
			if chunk[2] then
				table.insert(marks, { index - 1, col, col + #chunk[1], chunk[2] })
			end
			text = text .. chunk[1]
			col = col + #chunk[1]
		end
		lines[index] = text
	end
	return lines, marks
end

--- Append nodes as tree rows; every row of a node (and of its children) gets the node's target in `targets`
---@param nodes { line: table, details?: table[], children?: table[], target?: any }[]
function M.add(rows, targets, nodes, prefix, target)
	for index, node in ipairs(nodes) do
		local last = index == #nodes
		local node_target = node.target or target
		table.insert(rows, vim.list_extend({ { prefix .. (last and "└─ " or "├─ "), "NonText" } }, node.line))
		targets[#rows] = node_target
		local inner = prefix .. (last and "   " or "│  ")
		local has_children = node.children and #node.children > 0
		for _, detail in ipairs(node.details or {}) do
			table.insert(rows, vim.list_extend({ { inner .. (has_children and "│ " or "  "), "NonText" } }, detail))
			targets[#rows] = node_target
		end
		M.add(rows, targets, node.children or {}, inner, node_target)
	end
end

return M
