-- Match the explicit bindings in modules/home/llm/herdr/default.nix.
local function bind(keys, action, args)
	for _, key in ipairs(keys) do
		rex.bind(key, action, args)
	end
end

bind({ "ctrl+b>v", "alt+n" }, "pane.split", { direction = "right" })
bind({ "ctrl+b>-", "alt+m" }, "pane.split", { direction = "down" })
bind({ "ctrl+b>h", "alt+left" }, "pane.focus", { direction = "left" })
bind({ "ctrl+b>j", "alt+j", "alt+down" }, "pane.focus", { direction = "down" })
bind({ "ctrl+b>k", "alt+k", "alt+up" }, "pane.focus", { direction = "up" })
bind({ "ctrl+b>l", "alt+right" }, "pane.focus", { direction = "right" })
rex.bind("alt+[", "client.tab.previous")
rex.bind("alt+]", "client.tab.next")
rex.bind("alt+=", "pane.resize", { direction = "up" })
rex.bind("alt+-", "pane.resize", { direction = "down" })
bind({ "ctrl+b>z", "alt+p" }, "pane.zoom")

for i = 1, 9 do
	bind({ "ctrl+b>" .. i, "alt+" .. i }, "client.tab.goto", { index = i })
end

-- The native sidebar replaces HerdR's Neovim plugin.
bind({ "ctrl+b>space", "alt+space" }, "whichkey")
rex.bind("ctrl+b>e", "client.sidebar.toggle")
-- A prefix consumes Ctrl+B; pressing it twice sends it to the terminal.
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })

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
	title = "Focus Pane or Adjacent Tab",
	description = "Move through panes by column, then wrap through tabs like HerdR.",
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
			return checked(rex.session.focus_block({ block_id = next_block.block_id }))
		end

		-- At a tab boundary, enter the adjacent tab at its first/last pane.
		local windows = view.windows or {}
		if #windows < 2 then
			return
		end
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
		local target_index = (window_index - 1 + step) % #windows + 1
		local target = windows[target_index]
		local target_blocks = panes(target)
		local target_block = target_blocks[step == 1 and 1 or #target_blocks]
		local result
		if target_block then
			result = checked(rex.session.focus_block({ block_id = target_block.block_id }))
		else
			result = checked(rex.session.focus_window({ window_id = target.window_id }))
		end
		-- Server focus alone does not select the app's visible tab. Use an absolute
		-- index so an already-observed focus update cannot cause a second tab jump.
		rex.client.queue("client.tab.goto", { index = target_index })
		return result
	end,
})

rex.bind("alt+h", "herdr_focus", { direction = "left" })
rex.bind("alt+l", "herdr_focus", { direction = "right" })

-- Plugin defaults include the standard menus. Add spec = { ... } to replace them.
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local whichkey = dofile(config_home .. "/rex/whichkey/plugin.lua")
whichkey.setup({ position = "center" })
