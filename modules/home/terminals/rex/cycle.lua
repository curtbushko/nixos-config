-- Run in a detached CLI, never while the app waits for a synchronous rex.exec.
local function request(host, fn, ...)
	if host.failed then
		return
	end
	local ok, result, err = pcall(fn, ...)
	if ok and result and not err then
		return result
	end
	-- Do not retry every session on a host that disconnected during this step.
	host.failed = true
end
local function contains(ids, id)
	for _, candidate in ipairs(ids or {}) do
		if candidate == id then
			return true
		end
	end
	return false
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
if not args.session_id or not args.client_id then
	return
end
local step = args.direction == "right" and 1 or -1
local home = { name = "", api = rex }
local inspected = request(home, rex.call, "client.inspect", { client_id = args.client_id })
local local_client = inspected and inspected.client
if not local_client or local_client.connection_state == "lost" then
	return
end
local identity = local_client.info or {}
local hosts, preferred = { home }, nil
for _, name in ipairs(rex.servers()) do
	hosts[#hosts + 1] = { name = name, api = rex.server(name) }
	if name == args.server then
		preferred = hosts[#hosts]
	end
end
-- Client IDs are per-server. Match the same app, not just any reachable server.
local function connected_client(host)
	if host == home then
		local result = request(home, rex.call, "client.inspect", { client_id = args.client_id })
		local client = result and result.client
		return client and client.connection_state ~= "lost" and client or nil
	end
	if not identity.label or identity.label == "" then
		return
	end
	local result = request(host, host.api.call, "client.list", { kinds = { "app" } })
	local match
	for _, client in ipairs(result and result.clients or {}) do
		local info = client.info or {}
		-- Reconnects can leave an old lost record beside the new live client.
		-- Only live matches count toward ambiguity; stale records must not mask it.
		if
			client.connection_state ~= "lost"
			and info.label == identity.label
			and info.name == identity.name
			and info.platform == identity.platform
		then
			if match then
				return
			end
			match = client
		end
	end
	return match
end
-- A snapshot lasts for this keypress only. Lost app connections never contribute
-- sessions, even if the server is reachable from the CLI by another connection.
local function sessions_for(host, refresh)
	if host.sessions and not refresh then
		return host.sessions
	end
	host.sessions, host.client = {}, connected_client(host)
	if host.client then
		local result = request(host, host.api.call, "session.list", {})
		host.sessions = result and result.sessions or {}
	end
	return host.sessions
end
local function active(host, id, refresh, source)
	for _, session in ipairs(sessions_for(host, refresh)) do
		if session.session_id == id then
			return not source or contains(host.client and host.client.session_ids, id)
		end
	end
	return false
end
local origin, view
local function find_source(host)
	-- Validate both live membership and this app's attachment BEFORE attaching,
	-- focusing a pane, or asking the app to activate anything.
	if not active(host, args.session_id, false, true) then
		return
	end
	local result = request(host, host.api.session.attach, { session_id = args.session_id })
	if result and result.view then
		origin, view = { host = host, id = args.session_id }, result.view
	end
end
if preferred then
	-- A disconnected source is not permission to navigate on another host.
	find_source(preferred)
else
	for _, host in ipairs(hosts) do
		find_source(host)
		if origin then
			break
		end
	end
end
if not origin then
	return
end
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
if not index then
	return
end
local target, origin_window = origin, window.window_id
local block = blocks[index + step]
if not block then
	window = view.windows[window_index + step]
	if not window then
		local sessions, current = {}, nil
		for _, host in ipairs(hosts) do
			for _, session in ipairs(sessions_for(host)) do
				sessions[#sessions + 1] = { host = host, id = session.session_id }
				if host == origin.host and session.session_id == origin.id then
					current = #sessions
				end
			end
		end
		if not current then
			return
		end
		for offset = 1, #sessions do
			target = sessions[(current - 1 + step * offset) % #sessions + 1]
			local candidate
			if target.host == origin.host and target.id == origin.id then
				candidate = view
			else
				local attached = request(target.host, target.host.api.session.attach, { session_id = target.id })
				candidate = attached and attached.view
			end
			local windows = candidate and candidate.windows or {}
			if #windows > 0 then
				window = windows[step == 1 and 1 or #windows]
				break
			end
		end
	end
	if not window then
		return
	end
	blocks = panes(window)
	block = blocks[step == 1 and 1 or #blocks]
end
-- Enumeration can outlive the source connection. Revalidate it and the target
-- immediately before the first mutating operation; never navigate from stale UI.
if not active(origin.host, origin.id, true, true) then
	return
end
if not active(target.host, target.id, target.host ~= origin.host, false) then
	return
end
local focused
if block then
	focused =
		request(target.host, target.host.api.session.focus_block, { session_id = target.id, block_id = block.block_id })
else
	focused = request(
		target.host,
		target.host.api.session.focus_window,
		{ session_id = target.id, window_id = window.window_id }
	)
end
if not focused then
	return
end
local needs_activation = target.host ~= origin.host or target.id ~= origin.id or window.window_id ~= origin_window
if needs_activation then
	-- The parent action does not wait for this helper, so the app can finish that
	-- action before servicing this activation request.
	local selected = request(target.host, target.host.api.call, "client.perform", {
		client_id = target.host.client.client_id,
		action = "session.select",
		session_id = target.id,
		args = { session_id = target.id, window_id = window.window_id },
		timeout_ms = 1000,
	})
	if not selected then
		return
	end
end
return { session_id = target.id, window_id = window.window_id, block_id = block and block.block_id }
