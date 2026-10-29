local bindings, actions, calls = {}, {}, {}
local view, resize_error
local helper_running, spawn_error
rex = {
	json = {
		encode = function(args)
			return args
		end,
	},
	exec = setmetatable({
		start = function(argv, options)
			calls[#calls + 1] = { exec = argv, options = options }
			if spawn_error then
				return nil, spawn_error
			end
			helper_running = true
			return {
				running = function()
					return helper_running
				end,
			}
		end,
	}, {
		__call = function()
			error("navigation must not synchronously wait for the CLI")
		end,
	}),
	bind = function(key, action, args)
		assert(not bindings[key], "duplicate key: " .. key)
		bindings[key] = { action = action, args = args }
	end,
	action = function(action)
		assert(not actions[action.name], "duplicate action")
		actions[action.name] = action
	end,
	call = function()
		error("navigation must not enumerate server-local sessions")
	end,
	session = {
		view = function(args)
			assert(view, "session API called at config load time")
			assert(not args.session_id, "navigation must only inspect its current session")
			return view
		end,
		resize_pane = function(args)
			calls[#calls + 1] = { resize = args }
			return resize_error and nil or {}, resize_error
		end,
	},
}

dofile("modules/home/terminals/rex/init.lua")

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
binding({ "cmd+h", "cmd+left" }, "cycle_focus", "direction", "left")
binding({ "cmd+l", "cmd+right" }, "cycle_focus", "direction", "right")
assert(actions.cycle_focus, "retain combined pane/tab/session cycling")
binding({ "cmd+t" }, "client.tab.new")
binding({ "cmd+w" }, "client.tab.close")
assert(not bindings["cmd+space"], "reserve Cmd+Space for the replacement menu")
local action_count = 0
for _ in pairs(actions) do
	action_count = action_count + 1
end
assert(
	action_count == 2 and actions.cycle_focus and actions.pane_width,
	"load only the built-in navigation and resize actions"
)
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
	resize_error = nil
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
resize_error = "resize failed"
local resize_ok, resize_err = pcall(
	actions.pane_width.run,
	{ block_id = "left", session_id = "session" },
	{ cycle = true }
)
assert(not resize_ok and tostring(resize_err):find("resize failed", 1, true))
resize_error = nil
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

-- Navigation hands off without waiting for the helper or nested app requests.
local context = { client_id = "app-client", session_id = "session", block_id = "pane", server = "Gamingrig" }
for _, direction in ipairs({ "left", "right" }) do
	calls, helper_running = {}, false
	actions.cycle_focus.run(context, { direction = direction })
	assert(#calls == 1)
	local argv, options = calls[1].exec, calls[1].options
	assert(argv[2] == "--autostart=false" and argv[3] == "--timeout=1s")
	assert(argv[4] == "-C" and argv[5] == context.client_id)
	assert(argv[6] == "do" and argv[7]:match("/rex/cycle.lua$"))
	assert(argv[8] == "--args")
	assert(argv[9].session_id == context.session_id and argv[9].server == context.server)
	assert(argv[9].client_id == context.client_id and argv[9].direction == direction)
	assert(options.detach and options.timeout == 5, "parent must return before the helper asks the app to act")
	assert(options.stdout == false and options.stderr == false)
	for _, key in ipairs({ "REX_SERVER", "REX_SESSION", "REX_BLOCK", "REX_CLIENT" }) do
		assert(options.env[key] == false)
	end
	-- Key repeats may not enqueue a backlog of stale session switches.
	actions.cycle_focus.run(context, { direction = direction })
	assert(#calls == 1)
end
calls, helper_running = {}, false
actions.cycle_focus.run({}, { direction = "right" })
assert(#calls == 0, "a disconnected context may have no source session")
spawn_error = "spawn failed"
assert(not pcall(actions.cycle_focus.run, context, { direction = "right" }))
spawn_error = nil
assert(not pcall(actions.cycle_focus.run, context, { direction = "up" }))
print("Rex built-in bindings, pane sizing and asynchronous navigation: passed")
