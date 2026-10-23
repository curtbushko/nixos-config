-- Cmd controls application content; Option alone belongs to the desktop.
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
rex.bind("cmd+space", "whichkey")
rex.bind("cmd+e", "client.sidebar.toggle")
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("alt+cmd+" .. key, "pane.move", { direction = direction })
end
rex.bind("alt+cmd+-", "pane_width", { delta = -0.1 })
rex.bind("alt+cmd+=", "pane_width", { delta = 0.1 })
rex.bind("alt+cmd+w", "pane_width", { cycle = true })

local function panes(window)
	local result = {}
	local function visit(node)
		if not node then
			return
		end
		if node.block_id then
			result[#result + 1] = node
		elseif node.split then
			visit(node.split.before)
			visit(node.split.after)
		end
	end
	for _, layer in ipairs(window.layers or {}) do
		visit(layer.layout)
	end
	table.sort(result, function(a, b)
		if a.rect[1] ~= b.rect[1] then
			return a.rect[1] < b.rect[1]
		end
		if a.rect[2] ~= b.rect[2] then
			return a.rect[2] < b.rect[2]
		end
		return a.block_id < b.block_id
	end)
	return result
end

local function checked(result, err)
	if err then
		error(err, 0)
	end
	return result
end

rex.action({
	name = "herdr_focus",
	title = "Focus Pane, Tab, or Session",
	description = "Cycle through panes by column, then tabs and local or remote sessions.",
	args = { direction = "string" },
	run = function(ctx, args)
		if args.direction ~= "left" and args.direction ~= "right" then
			error("direction must be left or right", 0)
		end
		local step = args.direction == "right" and 1 or -1
		local view = checked(rex.session.view({}))
		local window
		for _, candidate in ipairs(view.windows or {}) do
			if candidate.window_id == view.active_window_id then
				window = candidate
				break
			end
		end
		assert(window, "No focused Rex tab")
		local blocks = panes(window)
		local focused = ctx.block_id or window.focused_block_id
		local index
		for i, block in ipairs(blocks) do
			if block.block_id == focused then
				index = i
				break
			end
		end
		if not index then
			error("Focused pane not found in Rex tab", 0)
		end

		local next_block = blocks[index + step]
		if next_block then
			return checked(rex.session.focus_block({
				session_id = view.session_id or ctx.session_id,
				block_id = next_block.block_id,
			}))
		end

		-- Exhaust this session's tabs before asking the app to cross hosts.
		local windows = view.windows or {}
		local window_index
		for i, candidate in ipairs(windows) do
			if candidate.window_id == window.window_id then
				window_index = i
				break
			end
		end
		if not window_index then
			error("Focused tab not found in Rex session", 0)
		end
		local session_id = view.session_id or ctx.session_id
		local target_index = window_index + step
		if target_index < 1 or target_index > #windows then
			-- Only the client knows its combined local/remote session order.
			-- Queue the tab selection after the session switch, on its new host.
			rex.client.queue(step == 1 and "session.next" or "session.previous")
			rex.client.queue("client.tab.goto", { index = step == 1 and 1 or -1 })
			return
		end
		local target = windows[target_index]
		local target_blocks = panes(target)
		local target_block = target_blocks[step == 1 and 1 or #target_blocks]
		local result
		if target_block then
			result = checked(rex.session.focus_block({
				session_id = session_id,
				block_id = target_block.block_id,
			}))
		else
			result = checked(rex.session.focus_window({
				session_id = session_id,
				window_id = target.window_id,
			}))
		end
		-- Server focus alone does not select the app's visible tab.
		rex.client.queue("client.tab.goto", { index = target_index })
		return result
	end,
})

bind({ "cmd+h", "cmd+left" }, "herdr_focus", { direction = "left" })
bind({ "cmd+l", "cmd+right" }, "herdr_focus", { direction = "right" })

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

-- Plugin defaults include the standard menus. Add spec = { ... } to replace them.
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local whichkey = dofile(config_home .. "/rex/whichkey/plugin.lua")
whichkey.setup({ position = "center" })
