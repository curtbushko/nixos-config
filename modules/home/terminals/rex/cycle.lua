-- Run on the app's home machine; server-side queued actions have different routing.
local function checked(result, err)
	if err then
		error(err, 0)
	end
	return result
end
local function panes(window)
	local blocks = {}
	local function visit(node)
		if not node then
			return
		end
		if node.block_id then
			blocks[#blocks + 1] = node
		elseif node.split then
			visit(node.split.before)
			visit(node.split.after)
		end
	end
	for _, layer in ipairs(window.layers or {}) do
		visit(layer.layout)
	end
	table.sort(blocks, function(a, b)
		if a.rect[1] ~= b.rect[1] then
			return a.rect[1] < b.rect[1]
		end
		if a.rect[2] ~= b.rect[2] then
			return a.rect[2] < b.rect[2]
		end
		return a.block_id < b.block_id
	end)
	return blocks
end
local args = rex.args
assert(args.direction == "left" or args.direction == "right", "direction must be left or right")
local step = args.direction == "right" and 1 or -1
local hosts = { { name = "", api = rex } }
local preferred = 1
for _, name in ipairs(rex.servers()) do
	hosts[#hosts + 1] = { name = name, api = rex.server(name) }
	if name == args.server then
		preferred = #hosts
	end
end
-- Attach already includes a view. Try the invoking host first; older callers
-- without a host hint can still discover the session without listing sessions.
local target, view, attach_error
local function try_host(host)
	local result, err = host.api.session.attach({ session_id = args.session_id })
	if result then
		target, view = { api = host.api, id = args.session_id }, assert(result.view, "Attach returned no view")
	else
		attach_error = err
	end
end
try_host(hosts[preferred])
if not target then
	for i, host in ipairs(hosts) do
		if i ~= preferred then
			try_host(host)
			if target then
				break
			end
		end
	end
end
assert(target, attach_error or "Current session not found among configured hosts")
local window, window_index, blocks, index
for wi, candidate in ipairs(view.windows or {}) do
	local candidate_blocks = panes(candidate)
	local focused = args.block_id or (candidate.window_id == view.active_window_id and candidate.focused_block_id)
	for bi, block in ipairs(candidate_blocks) do
		if block.block_id == focused then
			window, window_index, blocks, index = candidate, wi, candidate_blocks, bi
			break
		end
	end
	if index then
		break
	end
end
assert(index, "Focused pane not found in Rex session")
local block = blocks[index + step]
if not block then
	window = view.windows[window_index + step]
	if not window then
		-- Only session crossings need the global order or another host's state.
		local sessions, current = {}, nil
		for _, host in ipairs(hosts) do
			for _, session in ipairs(checked(host.api.call("session.list", {})).sessions or {}) do
				sessions[#sessions + 1] = { api = host.api, id = session.session_id }
				if session.session_id == args.session_id then
					current = #sessions
				end
			end
		end
		assert(current, "Current session disappeared from the session list")
		for offset = 1, #sessions do
			target = sessions[(current - 1 + step * offset) % #sessions + 1]
			local candidate = target.id == args.session_id and view
				or assert(
					checked(target.api.session.attach({ session_id = target.id })).view,
					"Attach returned no view"
				)
			local windows = candidate.windows or {}
			if #windows > 0 then
				window = windows[step == 1 and 1 or #windows]
				break
			end
		end
	end
	assert(window, "No session has a tab to focus")
	blocks = panes(window)
	block = blocks[step == 1 and 1 or #blocks]
end
if block then
	checked(target.api.session.focus_block({ session_id = target.id, block_id = block.block_id }))
else
	checked(target.api.session.focus_window({ session_id = target.id, window_id = window.window_id }))
end
rex.client.queue("session.select", { session_id = target.id, window_id = window.window_id })
return { session_id = target.id, window_id = window.window_id, block_id = block and block.block_id }
