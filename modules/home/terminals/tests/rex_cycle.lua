local calls, lists, views, list_error, focus_error, attached, stats
local function api(name)
	return {
		call = function(method)
			assert(method == "session.list")
			stats.lists = stats.lists + 1
			return { sessions = lists[name] }, list_error
		end,
		session = {
			attach = function(args)
				stats.attaches[name] = (stats.attaches[name] or 0) + 1
				for _, session in ipairs(lists[name]) do
					if session.session_id == args.session_id then
						attached[name .. args.session_id] = true
						return { view = assert(views[args.session_id]) }
					end
				end
				return nil, "session not found on " .. name
			end,
			view = function()
				error("attach already returns the view; do not add a network round trip")
			end,
			focus_block = function(args)
				assert(attached[name .. args.session_id], "focus requires destination attachment")
				calls[#calls + 1] = { host = name, block_id = args.block_id, session_id = args.session_id }
				return {}, focus_error
			end,
			focus_window = function(args)
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
	queue = function(action, args)
		calls[#calls + 1] = { action = action, args = args }
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
	calls, attached, stats = {}, {}, { lists = 0, attaches = {} }
	rex.args = { session_id = id, direction = direction, block_id = block_id, server = server }
	return dofile("modules/home/terminals/rex/cycle.lua")
end
-- Every pane, tab and session, including both remote tabs, in both directions.
for _, step in ipairs({ 1, -1 }) do
	for i, source in ipairs(order) do
		local target = order[(i - 1 + step) % #order + 1]
		cycle(source.session, step == 1 and "right" or "left", source.pane)
		assert(#calls == 2)
		assert(calls[1].host == (target.session:find("remote", 1, true) and "Gamingrig" or "local"))
		assert(calls[1].session_id == target.session and calls[1].block_id == target.pane)
		assert(calls[2].action == "session.select")
		assert(calls[2].args.session_id == target.session and calls[2].args.window_id == target.window)
	end
end
-- Pane/tab movement must not enumerate sessions or contact unrelated hosts.
cycle("local1", "right", "local1a")
assert(stats.lists == 0 and stats.attaches["local"] == 1 and not stats.attaches.Gamingrig)
cycle("remote1", "right", "remote1b", "Gamingrig")
assert(stats.lists == 0 and stats.attaches.Gamingrig == 1 and not stats.attaches["local"])
-- A stale hint pointing at a different known host must still find the session.
cycle("local1", "right", "local1a", "Gamingrig")
assert(calls[1].block_id == "local1b")
-- An unknown host hint falls back to discovering the session safely.
cycle("remote1", "left", "remote1c", "old-host-label")
assert(calls[1].block_id == "remote1b")
-- Missing pane context falls back to the active tab's focused pane.
cycle("local1", "right")
assert(calls[1].block_id == "local1d")
-- Empty destination tabs still receive focus.
views.remote1.windows = { { window_id = "empty-tab", layers = {} } }
cycle("local2", "right", "local2d")
assert(calls[1].host == "Gamingrig" and calls[1].window_id == "empty-tab")
-- Failures must not select a different session after a failed lookup/focus.
list_error = "list failed"
cycle("local1", "right", "local1a")
assert(calls[1].block_id == "local1b" and stats.lists == 0)
assert(not pcall(cycle, "local1", "right", "local1d") and #calls == 0)
list_error, focus_error = nil, "focus failed"
assert(not pcall(cycle, "local1", "right", "local1a") and #calls == 1)
focus_error = nil
assert(not pcall(cycle, "missing", "right") and #calls == 0)
assert(not pcall(cycle, "local1", "right", "missing") and #calls == 0)
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
