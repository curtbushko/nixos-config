-- Cmd controls application content; Option alone belongs to the desktop.
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local function bind(keys, action, args)
	for _, key in ipairs(keys) do
		rex.bind(key, action, args)
	end
end

rex.bind("cmd+d", "pane.split", { direction = "right" })
rex.bind("cmd+shift+d", "pane.split", { direction = "down" })
bind({ "cmd+j", "cmd+down" }, "pane.focus", { direction = "down" })
bind({ "cmd+k", "cmd+up" }, "pane.focus", { direction = "up" })
rex.bind("cmd+t", "client.tab.new")
rex.bind("cmd+w", "client.tab.close")
for i = 1, 9 do
	rex.bind("cmd+" .. i, "client.tab.goto", { index = i })
end
rex.bind("cmd+e", "client.sidebar.toggle")
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("alt+cmd+" .. key, "pane.move", { direction = direction })
end
rex.bind("alt+cmd+-", "pane_width", { delta = -0.1 })
rex.bind("alt+cmd+=", "pane_width", { delta = 0.1 })
rex.bind("alt+cmd+w", "pane_width", { cycle = true })

local function checked(result, err)
	if err then
		error(err, 0)
	end
	return result
end

-- Never wait inside the app for a helper that may need that same app to act.
-- One in-flight step prevents held keys from queuing stale session switches.
local navigation
rex.action({
	name = "cycle_focus",
	title = "Focus Pane, Tab, or Session",
	description = "Cycle panes, tabs and connected sessions; ignore disconnected sources.",
	args = { direction = "string" },
	run = function(ctx, args)
		assert(args.direction == "left" or args.direction == "right", "direction must be left or right")
		if not ctx.session_id or not ctx.client_id or (navigation and navigation:running()) then
			return
		end
		local cli = os.getenv("HOME") .. "/.local/bin/rex"
		local file = io.open(cli, "r")
		if file then
			file:close()
		else
			cli = "rex"
		end
		navigation = checked(rex.exec.start({
			cli,
			"--autostart=false",
			"--timeout=1s",
			"-C",
			ctx.client_id,
			"do",
			config_home .. "/rex/cycle.lua",
			"--args",
			checked(rex.json.encode({
				session_id = ctx.session_id,
				block_id = ctx.block_id,
				server = ctx.server,
				client_id = ctx.client_id,
				direction = args.direction,
			})),
		}, {
			detach = true,
			timeout = 5,
			stdout = false,
			stderr = false,
			env = { REX_SERVER = false, REX_SESSION = false, REX_BLOCK = false, REX_CLIENT = false },
		}))
	end,
})
bind({ "cmd+h", "cmd+left" }, "cycle_focus", { direction = "left" })
bind({ "cmd+l", "cmd+right" }, "cycle_focus", { direction = "right" })

-- Resize the nearest horizontal split containing the focused pane. Widths are
-- fractions of the window, not of a nested split; unreachable presets are skipped.
rex.action({
	name = "pane_width",
	title = "Adjust Pane Width",
	args = { delta = "number?", cycle = "boolean?" },
	run = function(ctx, args)
		local view = checked(rex.session.view({}))
		local focused = ctx.block_id
		local selected, leaf, before_side
		local function find(node)
			if not node then
				return false
			end
			if node.block_id then
				if node.block_id == focused then
					leaf = node
					return true
				end
				return false
			end
			if not node.split then
				return false
			end
			local before = find(node.split.before)
			local after = not before and find(node.split.after)
			if not before and not after then
				return false
			end
			if not selected and node.split.direction == "horizontal" then
				selected, before_side = node.split, before
			end
			return true
		end
		for _, window in ipairs(view.windows or {}) do
			if not focused and window.window_id == view.active_window_id then
				focused = window.focused_block_id
			end
		end
		for _, window in ipairs(view.windows or {}) do
			for _, layer in ipairs(window.layers or {}) do
				if find(layer.layout) then
					break
				end
			end
			if leaf then
				break
			end
		end
		assert(leaf, "Focused pane not found in Rex session")
		if not selected then
			return
		end
		local width = leaf.rect[3]
		local share = before_side and selected.ratio or (1 - selected.ratio)
		local maximum = width / share
		local target
		if args.cycle then
			local first
			for _, preset in ipairs({ 1 / 3, 1 / 2, 2 / 3 }) do
				if preset < maximum - 0.000001 then
					first = first or preset
					if preset > width + 0.000001 then
						target = preset
						break
					end
				end
			end
			target = target or first
		else
			assert(type(args.delta) == "number", "delta is required")
			target = math.max(maximum * 0.05, math.min(maximum * 0.95, width + args.delta))
		end
		if not target then
			return
		end
		local ratio = target / maximum
		local function first_block(node)
			return node.block_id or first_block(node.split.before)
		end
		return checked(rex.session.resize_pane({
			session_id = assert(ctx.session_id, "No Rex session"),
			direction = "horizontal",
			before_block_id = first_block(selected.before),
			after_block_id = first_block(selected.after),
			ratio = before_side and ratio or (1 - ratio),
		}))
	end,
})
