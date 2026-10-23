local bindings, actions, calls = {}, {}, {}
local view, view_error, focus_error, popup_error, theme_error
local session_views, session_list, list_error
local focused_session
rex = {
	block = {
		call = function(creator, method, args)
			assert(method == "set_theme", "opening a popup must not depend on cached terminal dimensions")
			calls[#calls + 1] = { creator = creator, method = method, args = args }
			return {}, theme_error
		end,
	},
	layout = {
		block = function(args)
			return { block = args }
		end,
	},
	client = {
		queue = function(action, args)
			calls[#calls + 1] = { action = action, args = args }
		end,
	},
	bind = function(key, action, args)
		assert(not bindings[key], "duplicate key: " .. key)
		bindings[key] = { action = action, args = args }
	end,
	action = function(action)
		assert(not actions[action.name], "duplicate action")
		actions[action.name] = action
	end,
	session = {
		list = function()
			return { sessions = session_list or { { session_id = "session" } } }, list_error
		end,
		view = function(args)
			assert(view or view_error, "session API called at config load time")
			if args.session_id and session_views then
				local target_view = assert(session_views[args.session_id], "unknown session")
				return target_view
			end
			return view, view_error
		end,
		focus_block = function(args)
			focused_session = args.session_id
			calls[#calls + 1] = { block_id = args.block_id }
			return focus_error and nil or {}, focus_error
		end,
		focus_window = function(args)
			calls[#calls + 1] = { window_id = args.window_id }
			return focus_error and nil or {}, focus_error
		end,
		resize_pane = function(args)
			calls[#calls + 1] = { resize = args }
			return focus_error and nil or {}, focus_error
		end,
		new_layer = function(args)
			calls[#calls + 1] = { layer = args }
			return { layer_id = "popup", block_ids = { "popup-block" } }, popup_error
		end,
		close_layer = function(args)
			calls[#calls + 1] = { closed_layer = args.layer_id }
			return {}
		end,
	},
}

-- Resolve the installed plugin path and resource tokens without deployment.
local real_dofile = dofile
local directory =
	assert(os.getenv("REX_WHICHKEY_LUA_DIR"), "Set REX_WHICHKEY_LUA_DIR to the pinned plugin input's lua/whichkey")
local menu_config = real_dofile(directory .. "/config.lua")
dofile = function(path)
	local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
	if path == config_home .. "/rex/whichkey/plugin.lua" then
		return real_dofile(directory .. "/plugin.lua")
	end
	if path == "@REX_WHICHKEY_DIRECTORY@/config.lua" then
		return menu_config
	end
	if path:find("@REX_WHICHKEY_DIRECTORY@/", 1, true) == 1 then
		return real_dofile((path:gsub("@REX_WHICHKEY_DIRECTORY@", directory)))
	end
	return real_dofile(path)
end
real_dofile("modules/home/terminals/rex/init.lua")
dofile = real_dofile

local function binding(keys, action, arg, value)
	for _, key in ipairs(keys) do
		local b = assert(bindings[key], "missing key: " .. key)
		assert(b.action == action, "wrong action: " .. key)
		if arg then
			assert(b.args[arg] == value, "wrong argument: " .. key)
		end
	end
end

binding({ "cmd+d" }, "pane.split", "direction", "right")
binding({ "cmd+shift+d" }, "pane.split", "direction", "down")
binding({ "cmd+j", "cmd+down" }, "pane.focus", "direction", "down")
binding({ "cmd+k", "cmd+up" }, "pane.focus", "direction", "up")
binding({ "cmd+h", "cmd+left" }, "herdr_focus", "direction", "left")
binding({ "cmd+l", "cmd+right" }, "herdr_focus", "direction", "right")
binding({ "cmd+t" }, "client.tab.new")
binding({ "cmd+w" }, "client.tab.close")
binding({ "cmd+space" }, "whichkey")
binding({ "cmd+e" }, "client.sidebar.toggle")
for i = 1, 9 do
	binding({ "cmd+" .. i }, "client.tab.goto", "index", i)
end
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	binding({ "alt+cmd+" .. key }, "pane.move", "direction", direction)
end
binding({ "alt+cmd+-" }, "pane_width", "delta", -0.1)
binding({ "alt+cmd+=" }, "pane_width", "delta", 0.1)
binding({ "alt+cmd+w" }, "pane_width", "cycle", true)
for key, b in pairs(bindings) do
	assert(not key:find("ctrl+b", 1, true), "no Ctrl+B prefix")
	assert(key:sub(1, 4) ~= "alt+" or key:sub(1, 8) == "alt+cmd+", "Option alone belongs to desktop")
	assert(b.action ~= "pane.zoom", "no zoom binding")
end
assert(not bindings["ctrl+b>d"], "Rex has no detach equivalent")
assert(not bindings["ctrl+b>o"], "Rex has no agent-output file picker")

-- Width adjustments use window-relative sizes, including the right-hand pane.
local function resize(focused, args, ratio)
	calls = {}
	view = {
		active_window_id = "width-test",
		windows = {
			{
				window_id = "width-test",
				focused_block_id = focused,
				layers = {
					{
						layout = {
							rect = { 0, 0, 1, 1 },
							split = {
								direction = "horizontal",
								ratio = ratio or 0.5,
								before = { block_id = "left", rect = { 0, 0, ratio or 0.5, 1 } },
								after = { block_id = "right", rect = { ratio or 0.5, 0, 1 - (ratio or 0.5), 1 } },
							},
						},
					},
				},
			},
		},
	}
	focus_error = nil
	actions.pane_width.run({ block_id = focused, session_id = "session" }, args)
end
resize("left", { delta = 0.1 })
assert(math.abs(calls[1].resize.ratio - 0.6) < 1e-6)
resize("right", { delta = 0.1 })
assert(math.abs(calls[1].resize.ratio - 0.4) < 1e-6)
resize("right", { delta = -0.1 })
assert(math.abs(calls[1].resize.ratio - 0.6) < 1e-6)
resize("left", { cycle = true }, 1 / 3)
assert(math.abs(calls[1].resize.ratio - 0.5) < 1e-6)
resize("left", { cycle = true }, 0.5)
assert(math.abs(calls[1].resize.ratio - 2 / 3) < 1e-6)
resize("left", { cycle = true }, 2 / 3)
assert(math.abs(calls[1].resize.ratio - 1 / 3) < 1e-6)
assert(calls[1].resize.session_id == "session")
resize("right", { cycle = true }, 0.5)
assert(math.abs(calls[1].resize.ratio - 1 / 3) < 1e-6)
resize("left", { delta = -10 })
assert(math.abs(calls[1].resize.ratio - 0.05) < 1e-6)
resize("left", { delta = 10 })
assert(math.abs(calls[1].resize.ratio - 0.95) < 1e-6)
focus_error = "resize failed"
local resize_ok, resize_err = pcall(
	actions.pane_width.run,
	{ block_id = "left", session_id = "session" },
	{ cycle = true }
)
assert(not resize_ok and tostring(resize_err):find("resize failed", 1, true))
focus_error = nil
-- A nested split is only half a window wide; skip the unreachable 1/2 and 2/3.
resize("left", { cycle = true })
local root = view.windows[1].layers[1].layout
root.split.before = {
	rect = { 0, 0, 0.5, 1 },
	split = {
		direction = "horizontal",
		ratio = 0.5,
		before = { block_id = "left", rect = { 0, 0, 0.25, 1 } },
		after = { block_id = "middle", rect = { 0.25, 0, 0.25, 1 } },
	},
}
calls = {}
actions.pane_width.run({ block_id = "left", session_id = "session" }, { cycle = true })
assert(#calls == 1 and calls[1].resize.after_block_id == "middle")
assert(math.abs(calls[1].resize.ratio - 2 / 3) < 1e-6)
-- A vertically stacked pane still resizes through its horizontal ancestor.
root.split.before.split.direction = "vertical"
root.split.before.split.before.rect = { 0, 0, 0.5, 0.5 }
calls = {}
actions.pane_width.run({ block_id = "left", session_id = "session" }, { cycle = true })
assert(calls[1].resize.after_block_id == "right")
assert(math.abs(calls[1].resize.ratio - 2 / 3) < 1e-6)
view.windows[1].layers[1].layout = { block_id = "left", rect = { 0, 0, 1, 1 } }
calls = {}
actions.pane_width.run({ block_id = "left", session_id = "session" }, { cycle = true })
assert(#calls == 0, "a single pane has no divider to resize")
assert(not pcall(actions.pane_width.run, { block_id = "missing" }, { cycle = true }))

local function block(id, x, y)
	return { block_id = id, rect = { x, y, 0.5, 0.5 } }
end
local function window(id, focused, blocks)
	local metadata = {}
	local layout
	for _, pane in ipairs(blocks) do
		metadata[#metadata + 1] = { block_id = pane.block_id }
		layout = layout and { rect = { 0, 0, 1, 1 }, split = { before = layout, after = pane } } or pane
	end
	return { window_id = id, focused_block_id = focused, layers = { { blocks = metadata, layout = layout } } }
end
local first = window("first", "b", { block("c", 0.5, 0.5), block("b", 0.5, 0), block("a", 0, 0) })
local second = window("second", "d", { block("e", 0.5, 0), block("d", 0, 0) })
local function focus(current_window, current_block, direction, windows)
	calls = {}
	view =
		{ session_id = "session", active_window_id = current_window.window_id, windows = windows or { first, second } }
	view_error, focus_error = nil, nil
	actions.herdr_focus.run({ block_id = current_block }, { direction = direction })
end

-- Reading order includes vertically stacked panes in the same column.
focus(first, "b", "right")
assert(#calls == 1 and calls[1].block_id == "c")
focus(first, "b", "left")
assert(#calls == 1 and calls[1].block_id == "a")
-- Tab crossings land on the first/last pane, rather than its previous focus.
focus(first, "c", "right")
assert(#calls == 2 and calls[1].block_id == "d")
assert(calls[2].action == "client.tab.goto" and calls[2].args.index == 2)
focus(second, "d", "left")
assert(#calls == 2 and calls[1].block_id == "c")
assert(calls[2].action == "client.tab.goto" and calls[2].args.index == 1)
-- Wrap around the tab list in either direction.
focus(second, "e", "right")
assert(#calls == 2 and calls[1].block_id == "a")
assert(calls[2].action == "client.tab.goto" and calls[2].args.index == 1)
focus(first, "a", "left")
assert(#calls == 2 and calls[1].block_id == "e")
assert(calls[2].action == "client.tab.goto" and calls[2].args.index == 2)
focus(first, "c", "right", { first })
assert(#calls == 2 and calls[1].block_id == "a", "a single tab must cycle its panes")
-- Cycle every pane/tab/session in server order, forward and backward.
local s1t1 = window("s1t1", "s1b", { block("s1a", 0, 0), block("s1b", 0.5, 0) })
local s1t2 = window("s1t2", "s1c", { block("s1c", 0, 0) })
local s2t1 = window("s2t1", "s2a", { block("s2a", 0, 0) })
local s2t2 = window("s2t2", "s2c", { block("s2b", 0, 0), block("s2c", 0.5, 0), block("s2d", 1, 0) })
session_views = {
	session = { session_id = "session", windows = { s1t1, s1t2 } },
	other = { session_id = "other", windows = { s2t1, s2t2 } },
	empty = { session_id = "empty", windows = {} },
}
session_list = { { session_id = "session" }, { session_id = "empty" }, { session_id = "other" } }
local sequence = {
	{ "session", s1t1, "s1a", 1 },
	{ "session", s1t1, "s1b", 1 },
	{ "session", s1t2, "s1c", 2 },
	{ "other", s2t1, "s2a", 1 },
	{ "other", s2t2, "s2b", 2 },
	{ "other", s2t2, "s2c", 2 },
	{ "other", s2t2, "s2d", 2 },
}
for _, step in ipairs({ 1, -1 }) do
	for i, source in ipairs(sequence) do
		local target = sequence[(i - 1 + step) % #sequence + 1]
		view = session_views[source[1]]
		view.active_window_id = source[2].window_id
		calls, focused_session = {}, nil
		actions.herdr_focus.run({ session_id = source[1], block_id = source[3] }, {
			direction = step == 1 and "right" or "left",
		})
		assert(calls[1].block_id == target[3], "wrong pane in full cycle")
		assert(focused_session == target[1], "focus must explicitly target the destination session")
		if source[1] ~= target[1] then
			assert(#calls == 2 and calls[2].action == "session.select")
			assert(calls[2].args.session_id == target[1] and calls[2].args.window_id == target[2].window_id)
		elseif source[2] ~= target[2] then
			assert(#calls == 2 and calls[2].action == "client.tab.goto" and calls[2].args.index == target[4])
		else
			assert(#calls == 1)
		end
	end
end
-- A failed session lookup must not wrap inside the current session instead.
view = session_views.session
view.active_window_id = s1t2.window_id
calls, list_error = {}, "list failed"
local list_ok, list_err = pcall(actions.herdr_focus.run, { block_id = "s1c" }, { direction = "right" })
assert(not list_ok and tostring(list_err):find("list failed", 1, true) and #calls == 0)
session_views, session_list, list_error = nil, nil, nil
-- Empty target windows still receive focus.
local empty = window("empty", nil, {})
focus(first, "c", "right", { first, empty })
assert(#calls == 2 and calls[1].window_id == "empty")
assert(calls[2].action == "client.tab.goto" and calls[2].args.index == 2)
-- Missing block context falls back to the active window's focused pane.
focus(second, nil, "right")
assert(#calls == 1 and calls[1].block_id == "e")
-- Missing context and API errors must not silently switch tabs.
focus(first, "b", "right")
calls = {}
view.active_window_id = "missing"
assert(not pcall(actions.herdr_focus.run, {}, { direction = "right" }))
assert(#calls == 0)
view.active_window_id = first.window_id
assert(not pcall(actions.herdr_focus.run, { block_id = "missing" }, { direction = "right" }))
assert(#calls == 0)
view, view_error = nil, "unavailable"
local ok, err = pcall(actions.herdr_focus.run, {}, { direction = "right" })
assert(not ok and tostring(err):find("unavailable", 1, true))
view, view_error, focus_error = { active_window_id = first.window_id, windows = { first, second } }, nil, "focus failed"
ok, err = pcall(actions.herdr_focus.run, { block_id = "b" }, { direction = "right" })
assert(not ok and tostring(err):find("focus failed", 1, true))
-- Removed menu operations must fail before changing focus or queuing commands.
for _, choice in ipairs({ "move_new_tab", "resize_left", "resize_up", "resize_down", "resize_right" }) do
	calls = {}
	assert(not pcall(actions.whichkey_dispatch.run, { block_id = "b" }, { lhs = choice }))
	assert(#calls == 0)
end
-- Opening the menu creates a focused floating terminal, keeping caller context.
view_error, focus_error, popup_error = nil, nil, nil
view = { active_window_id = first.window_id, windows = { first, second } }
calls = {}
actions.whichkey.run({ client_id = "app-client", session_id = "session", block_id = "b" }, {})
assert(#calls == 1, "inherit the theme; do not override it before terminal color queries")
local layer = calls[1].layer
assert(layer.window_id == "first" and layer.focus)
assert(
	layer.bounds.x == 0 and layer.bounds.y == 0 and layer.bounds.w == 1 and layer.bounds.h == 1,
	"bootstrap at the origin; shared areas own subsequent placement"
)
assert(
	math.abs(tonumber(layer.layout.block.options.command[16]) - (layer.bounds.w - layer.bounds.x) / layer.bounds.w)
		< 1e-9
)
assert(
	math.abs(tonumber(layer.layout.block.options.command[17]) - (layer.bounds.h - layer.bounds.y) / layer.bounds.h)
		< 1e-9
)
assert(layer.bounds.x >= 0 and layer.bounds.y >= 0)
assert(layer.bounds.x + layer.bounds.w <= 1 and layer.bounds.y + layer.bounds.h <= 1)
assert(layer.layout.block.flavor == "com.superlogical.terminal.shell")
local options = layer.layout.block.options
assert(
	options.shell == "none" and options.login == false and options.exit.on_completion,
	"a popup must not run login initialization or emit a Last login timestamp"
)
assert(options.exit.quick_exit_threshold_ms == 0, "even a fast Escape must close the temporary popup")
assert(options.command[1] == "/bin/sh" and options.command[2] == "-c")
assert(options.command[6] == "app-client" and options.command[7] == "session" and options.command[8] == "b")
assert(not options.theme, "inherit the active terminal theme")
assert(options.command[10] == "#d3c6aa", "retain internal colors only as query fallbacks")
assert(options.command[18] == "center")
calls = {}
actions.whichkey.run({ client_id = "app-client", session_id = "session", block_id = "b" }, { position = "left" })
assert(calls[1].layer.layout.block.options.command[18] == "left")
-- A tab switch must not create the popup apart from its originating pane.
calls = {}
actions.whichkey.run({ client_id = "app-client", session_id = "session", block_id = "d" }, {})
assert(calls[1].layer.window_id == "second" and #calls == 1)
calls = {}
assert(not pcall(actions.whichkey.run, { client_id = "app-client", session_id = "session", block_id = "gone" }, {}))
assert(#calls == 0, "do not create an orphan popup if the originating pane disappeared")
-- Dispatch restores focus before requesting the action on the app client.
calls = {}
actions.whichkey_dispatch.run({ block_id = "b" }, { lhs = "v" })
assert(#calls == 2 and calls[1].block_id == "b")
assert(calls[2].action == "pane.split" and calls[2].args.direction == "right")
calls = {}
actions.whichkey_dispatch.run({ block_id = "b" }, { lhs = "t9" })
assert(calls[2].action == "client.tab.goto" and calls[2].args.index == 9)
calls = {}
assert(not pcall(actions.whichkey_dispatch.run, { block_id = "b" }, { lhs = "unknown" }))
assert(#calls == 0)
-- Editing only the shared spec adds a nested action and a confirmed callback.
menu_config.spec[#menu_config.spec + 1] = { "g", group = "Tools", icon = "!" }
menu_config.spec[#menu_config.spec + 1] = { "gn", group = "Nested" }
menu_config.spec[#menu_config.spec + 1] = { "gnr", "pane.split", desc = "Split left", args = { direction = "left" } }
menu_config.spec[#menu_config.spec + 1] = {
	"gnx",
	function(ctx, args)
		calls[#calls + 1] = { callback = ctx.block_id, value = args.value }
	end,
	desc = "Callback",
	confirm = true,
	args = { value = 42 },
}
calls = {}
actions.whichkey_dispatch.run({ block_id = "b" }, { lhs = "gnr" })
assert(calls[2].action == "pane.split" and calls[2].args.direction == "left")
calls = {}
assert(not pcall(actions.whichkey_dispatch.run, { block_id = "b" }, { lhs = "gn" }))
assert(not pcall(actions.whichkey_dispatch.run, { block_id = "b" }, { lhs = "gnx" }))
assert(not pcall(actions.whichkey_dispatch.run, { block_id = "b" }, { lhs = "x", confirmed = false }))
assert(#calls == 0, "groups and unconfirmed actions must not change focus")
actions.whichkey_dispatch.run({ block_id = "b" }, { lhs = "gnx", confirmed = true })
assert(#calls == 2 and calls[2].callback == "b" and calls[2].value == 42)
calls = {}
focus_error = "origin disappeared"
assert(not pcall(actions.whichkey_dispatch.run, { block_id = "b" }, { lhs = "z" }))
assert(#calls == 1) -- no client action after failed focus
focus_error, popup_error = nil, "cannot create popup"
assert(not pcall(actions.whichkey.run, { client_id = "app-client", session_id = "session", block_id = "b" }, {}))
calls = {}
assert(not pcall(actions.whichkey.run, {}, {}))
assert(#calls == 0)
-- Theme writes are deliberately absent: even an unavailable theme setter cannot
-- stop startup or replace the colors the terminal will report.
popup_error, theme_error = nil, "theme writes forbidden"
calls = {}
actions.whichkey.run({ client_id = "app-client", session_id = "session", block_id = "b" }, {})
assert(#calls == 1)
print("Rex bindings, navigation, popup styling, cleanup and dispatch: passed")
