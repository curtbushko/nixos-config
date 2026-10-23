local calls, lists, views, list_error, focus_error, attached, stats
local offline, disconnect_on_attach, disconnect_on_focus, throw_offline
local remote_client_state, selection_error, lose_after_attach, disappear_source
local remote_clients
local function app_client(name)
	return {
		client_id = name .. "-app",
		info = { kind = "app", label = "m4-pro", name = "Rex Beta", platform = "macos" },
		session_ids = (function()
			local ids = {}
			for _, session in ipairs(lists[name]) do
				ids[#ids + 1] = session.session_id
			end
			return ids
		end)(),
		connection_state = name == "local" and "connected" or (remote_client_state or "connected"),
	}
end
local function unavailable(name)
	if name == "Gamingrig" and offline then
		local message = 'host "Gamingrig" could not be reached: timed out'
		if throw_offline then
			error(message)
		end
		return message
	end
end
local function api(name)
	return {
		call = function(method, args)
			local err = unavailable(name)
			if err then
				return nil, err
			end
			if method == "client.inspect" then
				assert(name == "local" and args.client_id == "local-app")
				return { client = app_client(name) }
			elseif method == "client.list" then
				assert(args.kinds[1] == "app")
				return { clients = name == "Gamingrig" and remote_clients or { app_client(name) } }
			elseif method == "client.perform" then
				assert(args.client_id == name .. "-app", "activation must use the destination host's client ID")
				assert(args.session_id == args.args.session_id, "activation needs explicit session context")
				assert(name == "local" or remote_client_state ~= "lost", "do not activate a disconnected app")
				calls[#calls + 1] = { host = name, action = args.action, args = args.args }
				return not selection_error and {} or nil, selection_error
			end
			assert(method == "session.list")
			if name == "Gamingrig" and disappear_source then
				local remaining = {}
				for _, session in ipairs(lists["local"]) do
					if session.session_id ~= disappear_source then
						remaining[#remaining + 1] = session
					end
				end
				lists["local"] = remaining
			end
			stats.lists = stats.lists + 1
			if not list_error then
				for _, session in ipairs(lists[name]) do
					stats.validated[name .. session.session_id] = true
				end
			end
			return not list_error and { sessions = lists[name] } or nil, list_error
		end,
		session = {
			attach = function(args)
				assert(stats.validated[name .. args.session_id], "validate the live session list before attaching")
				stats.attaches[name] = (stats.attaches[name] or 0) + 1
				if name == "Gamingrig" and disconnect_on_attach then
					offline = true
				end
				local err = unavailable(name)
				if err then
					return nil, err
				end
				for _, session in ipairs(lists[name]) do
					if session.session_id == args.session_id then
						attached[name .. args.session_id] = true
						if name == "Gamingrig" and lose_after_attach then
							remote_client_state = "lost"
						end
						return { view = assert(views[args.session_id]) }
					end
				end
				return nil, "session not found on " .. name
			end,
			view = function()
				error("attach already returns the view; do not add a network round trip")
			end,
			focus_block = function(args)
				stats.focuses = stats.focuses + 1
				if name == "Gamingrig" and disconnect_on_focus then
					offline = true
				end
				local err = unavailable(name)
				if err then
					return nil, err
				end
				assert(attached[name .. args.session_id], "focus requires destination attachment")
				calls[#calls + 1] = { host = name, block_id = args.block_id, session_id = args.session_id }
				return {}, focus_error
			end,
			focus_window = function(args)
				stats.focuses = stats.focuses + 1
				assert(attached[name .. args.session_id], "focus requires destination attachment")
				calls[#calls + 1] = { host = name, window_id = args.window_id, session_id = args.session_id }
				return {}, focus_error
			end,
		},
	}
end
rex = api("local")
rex.servers = function()
	return { "Gamingrig" }
end
rex.server = function(name)
	assert(name == "Gamingrig")
	return api(name)
end
rex.client = {
	queue = function()
		error("unscoped activation can route a local tab to the disconnected remote host")
	end,
}
local function window(id, a, b)
	return {
		window_id = id,
		focused_block_id = a,
		layers = {
			{
				layout = {
					split = {
						before = { block_id = b, rect = { 0.5, 0, 0.5, 1 } },
						after = { block_id = a, rect = { 0, 0, 0.5, 1 } },
					},
				},
			},
		},
	}
end
lists = {
	["local"] = { { session_id = "local1" }, { session_id = "local2" } },
	Gamingrig = { { session_id = "empty" }, { session_id = "remote1" }, { session_id = "remote2" } },
}
views = { empty = { windows = {} } }
local order = {}
for _, id in ipairs({ "local1", "local2", "remote1", "remote2" }) do
	views[id] = {
		-- Deliberately stale: the invoking pane must identify its actual tab.
		active_window_id = id .. "last",
		windows = { window(id .. "first", id .. "a", id .. "b"), window(id .. "last", id .. "c", id .. "d") },
	}
	for _, pane in ipairs({ "a", "b", "c", "d" }) do
		order[#order + 1] = { session = id, pane = id .. pane, window = id .. (pane < "c" and "first" or "last") }
	end
end
local function cycle(id, direction, block_id, server)
	calls, attached, stats = {}, {}, { lists = 0, focuses = 0, attaches = {}, validated = {} }
	rex.args = { session_id = id, direction = direction, block_id = block_id, server = server, client_id = "local-app" }
	return dofile("modules/home/terminals/rex/cycle.lua")
end
-- Every pane, tab and session, including both remote tabs, in both directions.
for _, step in ipairs({ 1, -1 }) do
	for i, source in ipairs(order) do
		local target = order[(i - 1 + step) % #order + 1]
		cycle(source.session, step == 1 and "right" or "left", source.pane)
		local same_tab = source.session == target.session and source.window == target.window
		assert(#calls == (same_tab and 1 or 2), "pane focus must not reactivate its tab")
		assert(calls[1].host == (target.session:find("remote", 1, true) and "Gamingrig" or "local"))
		assert(calls[1].session_id == target.session and calls[1].block_id == target.pane)
		if not same_tab then
			assert(calls[2].host == calls[1].host, "tab activation must be routed through its own host")
			assert(calls[2].action == "session.select")
			assert(calls[2].args.session_id == target.session and calls[2].args.window_id == target.window)
		end
	end
end
-- Missing/disconnected sources must exit before attach, focus or activation.
local saved_local = lists["local"]
lists["local"] = {}
assert(pcall(cycle, "local1", "right", "local1a"))
assert(#calls == 0 and stats.focuses == 0 and not stats.attaches["local"])
lists["local"] = saved_local
remote_client_state = "lost"
cycle("remote1", "right", "remote1a", "Gamingrig")
assert(#calls == 0 and stats.focuses == 0 and not stats.attaches.Gamingrig)
remote_client_state = nil
lose_after_attach = true
cycle("remote1", "right", "remote1a", "Gamingrig")
assert(#calls == 0 and stats.focuses == 0, "recheck source connection after reading its view")
lose_after_attach, remote_client_state = false, nil
-- The source can disappear while other hosts are being enumerated.
disappear_source = "local2"
cycle("local2", "right", "local2d")
assert(#calls == 0 and stats.focuses == 0, "do not navigate from a source that vanished during discovery")
lists["local"], disappear_source = saved_local, nil
-- Pane/tab movement validates the source without contacting unrelated hosts.
cycle("local1", "right", "local1a")
assert(stats.lists >= 1 and stats.attaches["local"] == 1 and not stats.attaches.Gamingrig)
cycle("remote1", "right", "remote1b", "Gamingrig")
assert(stats.lists >= 1 and stats.attaches.Gamingrig == 1 and not stats.attaches["local"])
-- A known but stale source host must not redirect navigation to another host.
cycle("local1", "right", "local1a", "Gamingrig")
assert(#calls == 0)
-- An unknown host hint falls back to discovering the session safely.
cycle("remote1", "left", "remote1c", "old-host-label")
assert(calls[1].block_id == "remote1b")
-- Missing pane context falls back to the active tab's focused pane.
cycle("local1", "right")
assert(calls[1].block_id == "local1d")
-- Offline hosts must not prevent local navigation or wraparound.
for _, throws in ipairs({ false, true }) do
	throw_offline, offline = throws, true
	cycle("local1", "right", "local1a")
	assert(calls[1].block_id == "local1b" and stats.lists >= 1)
	cycle("local2", "right", "local2d")
	assert(calls[1].host == "local" and calls[1].block_id == "local1a")
	cycle("local1", "left", "local1a")
	assert(calls[1].host == "local" and calls[1].block_id == "local2d")
	cycle("local1", "right", "local1a", "Gamingrig")
	assert(#calls == 0)
	-- A disconnected invoking tab has nothing safe to focus: quietly do nothing.
	cycle("remote1", "right", "remote1a", "Gamingrig")
	assert(#calls == 0)
	offline = false
	-- The remote may disappear after listing but before attaching/focusing.
	disconnect_on_attach = true
	cycle("local2", "right", "local2d")
	assert(calls[1].host == "local" and calls[1].block_id == "local1a")
	assert(stats.attaches.Gamingrig == 1, "do not retry every session on the same disconnected host")
	disconnect_on_attach, offline = false, false
	disconnect_on_focus = true
	cycle("remote1", "right", "remote1a", "Gamingrig")
	assert(#calls == 0)
	disconnect_on_focus, offline = false, false
end
throw_offline = false
-- A reachable server is not proof that the app's remote connection is ready.
remote_client_state = "lost"
cycle("local2", "right", "local2d")
assert(calls[1].host == "local" and calls[1].block_id == "local1a")
cycle("remote1", "right", "remote1b", "Gamingrig")
assert(#calls == 0, "do not activate a tab on a lost app connection")
remote_client_state = nil
-- Reconnection may create a new client while the old lost record remains.
-- A stale record in either position must not hide the connected replacement.
for _, lost_first in ipairs({ true, false }) do
	local lost = app_client("Gamingrig")
	lost.client_id, lost.connection_state = "old-app", "lost"
	local connected = app_client("Gamingrig")
	remote_clients = lost_first and { lost, connected } or { connected, lost }
	cycle("local2", "right", "local2d")
	assert(calls[1].host == "Gamingrig", "include a reconnected server on the next session crossing")
	assert(calls[2].action == "session.select")
	cycle("remote1", "right", "remote1a", "Gamingrig")
	assert(calls[1].block_id == "remote1b", "accept the new source client without waiting for stale expiry")
end
-- Two live matching apps remain ambiguous and must not be controlled.
remote_clients = { app_client("Gamingrig"), app_client("Gamingrig") }
remote_clients[2].client_id = "other-live-app"
cycle("local2", "right", "local2d")
assert(calls[1].host == "local" and calls[1].block_id == "local1a")
cycle("remote1", "right", "remote1a", "Gamingrig")
assert(#calls == 0 and stats.focuses == 0)
remote_clients = nil
-- A disconnect between readiness and activation must not raise a Lua error.
selection_error = "The server is not ready for this operation."
assert(pcall(cycle, "local2", "right", "local2d"))
selection_error = nil
-- Empty destination tabs still receive focus.
views.remote1.windows = { { window_id = "empty-tab", layers = {} } }
cycle("local2", "right", "local2d")
assert(calls[1].host == "Gamingrig" and calls[1].window_id == "empty-tab")
-- Failures must not select a different session after a failed lookup/focus.
list_error = "list failed"
assert(pcall(cycle, "local1", "right", "local1a") and #calls == 0)
assert(pcall(cycle, "local1", "right", "local1d") and #calls == 0)
list_error, focus_error = nil, "focus failed"
assert(pcall(cycle, "local1", "right", "local1a") and #calls == 1)
focus_error = nil
assert(pcall(cycle, "missing", "right") and #calls == 0)
assert(pcall(cycle, "local1", "right", "missing") and #calls == 0)
assert(not pcall(cycle, "local1", "up") and #calls == 0)
-- Vertical panes in the same column follow their y positions.
local stacked = views.local1.windows[1].layers[1].layout.split
stacked.before = {
	split = {
		before = { block_id = "local1e", rect = { 0.5, 0.5, 0.5, 0.5 } },
		after = { block_id = "local1b", rect = { 0.5, 0, 0.5, 0.5 } },
	},
}
cycle("local1", "right", "local1b")
assert(calls[1].block_id == "local1e")
cycle("local1", "left", "local1e")
assert(calls[1].block_id == "local1b")
-- A single session/tab wraps through its own panes.
rex.servers = function()
	return {}
end
lists["local"] = { { session_id = "local1" } }
views.local1.windows = { views.local1.windows[1] }
cycle("local1", "right", "local1e")
assert(calls[1].block_id == "local1a")
cycle("local1", "left", "local1a")
assert(calls[1].block_id == "local1e")
print("Rex complete cross-host pane/tab/session cycle and failures: passed")
