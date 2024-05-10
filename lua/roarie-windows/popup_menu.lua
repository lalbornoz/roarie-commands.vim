--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local config = require("roarie-menu.config")
local utils = require("roarie-utils")
local utils_buffer = require("roarie-utils.buffer")
local utils_windows = require("roarie-windows.utils")

local M = {}

-- {{{ local function activate_item(M, menu_popup, menus)
local function activate_item(M, menu_popup, menus)
	return function()
		return menus.items[menus.idx].items[menu_popup.idx].lhs
	end
end
-- }}}
-- {{{ local function select_item_key(key_char)
local function select_item_key(key_char)
	return function(M_, menu_popup, menus)
		return function()
			M.select_item_key(key_char, menu_popup, menus)
		end
	end
end
-- }}}
-- {{{ local function select_item_wrap(fn, ...)
local function select_item_wrap(fn, ...)
	local args = {...}
	return function(M_, menu_popup, menus)
		return function()
			local fn_args = utils.copy_table(args)
			table.insert(fn_args, menu_popup)
			table.insert(fn_args, menus)
			M[fn](unpack(fn_args))
		end
	end
end
-- }}}
-- {{{ local maps_default = {}
local maps_default = {
	["<Down>"] = select_item_wrap("select_item_step", 1),
	["<Up>"] = select_item_wrap("select_item_step", -1),
	["<PageDown>"] = select_item_wrap("select_item_after", "--", -1),
	["<PageUp>"] = select_item_wrap("select_item_after", "--", 1),
	["<Home>"] = select_item_wrap("select_item_idx", 1),
	["<End>"] = select_item_wrap("select_item_idx", -1),

	[" "] = activate_item,
	["<CR>"] = activate_item,

	-- {{{ ["<M-a>"]...["<M-z>"] = select_item_key(...)
	["<M-a>"] = select_item_key("a"),
	["<M-b>"] = select_item_key("b"),
	["<M-c>"] = select_item_key("c"),
	["<M-d>"] = select_item_key("d"),
	["<M-e>"] = select_item_key("e"),
	["<M-f>"] = select_item_key("f"),
	["<M-g>"] = select_item_key("g"),
	["<M-h>"] = select_item_key("h"),
	["<M-i>"] = select_item_key("i"),
	["<M-j>"] = select_item_key("j"),
	["<M-k>"] = select_item_key("k"),
	["<M-l>"] = select_item_key("l"),
	["<M-m>"] = select_item_key("m"),
	["<M-n>"] = select_item_key("n"),
	["<M-o>"] = select_item_key("o"),
	["<M-p>"] = select_item_key("p"),
	["<M-q>"] = select_item_key("q"),
	["<M-r>"] = select_item_key("r"),
	["<M-s>"] = select_item_key("s"),
	["<M-t>"] = select_item_key("t"),
	["<M-u>"] = select_item_key("u"),
	["<M-v>"] = select_item_key("v"),
	["<M-w>"] = select_item_key("w"),
	["<M-x>"] = select_item_key("x"),
	["<M-y>"] = select_item_key("y"),
	["<M-z>"] = select_item_key("z"),
	-- }}}
}
-- }}}


-- {{{ local function add_key(keys, key_char, item_idx)
local function add_key(keys, key_char, item_idx)
	if key_char ~= nil then
		if keys[key_char] ~= nil then
			if type(keys[key_char]) ~= "table" then
				keys[key_char] = {keys[key_char]}
			end
			table.insert(keys[key_char], item_idx)
		else
			keys[key_char] = item_idx
		end
	end
end
-- }}}
-- {{{ local function get_dimensions(menus, w, h)
local function get_dimensions(menus, w, h)
	for _, item in ipairs(menus.items[menus.idx].items) do
		if item.display ~= "--" then
			if string.match(item.display, "\t") ~= nil then
				local lhs, rhs = unpack(utils.split(item.display, "[^\t]+"), 1, 2)
				w = math.max(w, utils.ulen("│ 󰘳 " .. lhs .. "   " .. rhs .. " │"))
			else
				w = math.max(w, utils.ulen("│ 󰘳 " .. item.display .. " │"))
			end
		end
		h = h + 1
	end

	return w, h
end
-- }}}
-- {{{ local function map_items(keys, cmdlist, menus, textlist, w)
local function map_items(keys, cmdlist, menus, textlist, w)
	local y = 1
	for item_idx, item in ipairs(menus.items[menus.idx].items) do
		y = y + 1
		if item.display ~= "--" then
			if string.match(item.display, "\t") ~= nil then
				local display = item.display
				display, key_char = utils_windows.highlight_accel(cmdlist, display, y, 2)
				add_key(keys, key_char, item_idx)

				local lhs, rhs = unpack(utils.split(display, "[^\t]+"), 1, 2)
				local spacing = math.max(w - utils.ulen("│ 󰘳 " .. lhs .. rhs .. " │"), 3)
				display = lhs:gsub("&", "") .. string.rep(" ", spacing) .. rhs

				menus.items[menus.idx].items[item_idx].menu_text = display
				table.insert(textlist, " " .. item.icon .. " " .. display .. " ")
			else
				local display = item.display
				display, key_char = utils_windows.highlight_accel(cmdlist, display, y, 2)
				add_key(keys, key_char, item_idx)

				menus.items[menus.idx].items[item_idx].menu_text = display
				table.insert(textlist, " " .. item.icon .. " " .. display .. " ")
			end
		else
			table.insert(textlist, "--")
		end
	end
end
-- }}}
-- {{{ local function select_item(idx_new, menu_popup, menus)
local function select_item(idx_new, menu_popup, menus)
	if idx_new == menu_popup.idx then
		return
	end

	menu_popup.idx = idx_new

	local cmdlist = {"syn clear"}
	for _, cmd in ipairs(menu_popup.cmdlist) do
		table.insert(cmdlist, cmd)
	end
	local map_x0, map_x1 =
		menus.items[menus.idx].items[idx_new].menu_text:find(
			'<[^>]+>$')

	if map_x0 ~= nil then
		table.insert(cmdlist,
			utils_windows.highlight_region(
				"QuickSel", menu_popup.idx + 1, 2,
				menu_popup.idx + 1, map_x0 + 4, true))
		table.insert(cmdlist,
			utils_windows.highlight_region(
				"QuickSelMap", menu_popup.idx + 1, map_x0 + 4,
				menu_popup.idx + 1, map_x1 + 5, true))
		table.insert(cmdlist,
			utils_windows.highlight_region(
				"QuickSel", menu_popup.idx + 1, map_x1 + 5,
				menu_popup.idx + 1, map_x1 + 6, true))
	else
		table.insert(cmdlist,
			utils_windows.highlight_region(
				"QuickSel", menu_popup.idx + 1, 2,
				menu_popup.idx + 1, menu_popup.w, true))

	end

	utils.win_execute(menu_popup.winid, cmdlist, false)
	utils_windows.highlight_border(
		"QuickBorder", menus.items[menus.idx].items,
		menu_popup.w, menu_popup.h, menu_popup.winid)
end
-- }}}

-- {{{ local function setup_maps(M, menu_popup, menus)
local function setup_maps(M, menu_popup, menus)
	menu_popup.maps = {}
	for lhs, rhs in pairs(maps_default) do
		vim.keymap.set(
			{"n", "i"}, lhs, rhs(M, menu_popup, menus),
			{buffer=menu_popup.bid, noremap=true})
		menu_popup.maps[lhs] = rhs
	end
end
-- }}}
-- {{{ local function setup_window(cmdlist, menu_popup, menus, textlist, w, h)
local function setup_window(cmdlist, menu_popup, menus, textlist, w, h)
	local opts = {
		col=menus.items[menus.idx].x, row=1,
		focusable=1,
		noautocmd=1,
		relative="editor",
		style="minimal",
		width=w,
		height=h,
	}

	menu_popup.bid = utils_buffer.create_scratch("context", textlist)
	local winid_old = vim.api.nvim_get_current_win()
	menu_popup.winid = vim.api.nvim_open_win(menu_popup.bid, 0, opts)
	if (not is_current) and (winid_old ~= vim.api.nvim_get_current_win()) then
		vim.api.nvim_set_current_win(winid_old)
	end

	vim.api.nvim_win_set_option(
		menu_popup.winid, "winhl",
		"Normal:QuickBG,CursorColumn:QuickBG,CursorLine:QuickBorder")
	vim.api.nvim_win_set_option(
		menu_popup.winid, "cursorline",
		false)

	utils.win_execute(menu_popup.winid, cmdlist, false)

	utils_windows.highlight_border(
		"QuickBorder", menus.items[menus.idx].items,
		menu_popup.w, menu_popup.h, menu_popup.winid)
end
-- }}}


-- {{{ M.close = function(menu_popup, redraw)
M.close = function(menu_popup, redraw)
	if menu_popup.winid ~= nil then
		vim.api.nvim_win_close(menu_popup.winid, 0)
		menu_popup.winid = nil
	end

	if menu_popup.bid ~= nil then
		utils_buffer.free(menu_popup.bid, "context")
		menu_popup.bid = nil
	end

	if redraw then
		vim.cmd [[redraw]]
	end

	menu_popup.open = false
	return menu_popup
end
-- }}}
-- {{{ M.init = function()
M.init = function()
	return {
		bid=nil,
		cmdlist={},
		idx=nil,
		idx_max=nil,
		keys={},
		maps=nil,
		open=nil,
		winid=nil,
		w=nil,
		h=nil,
	}
end
-- }}}
-- {{{ M.open = function(menus, menu_popup, key_char, is_current)
M.open = function(menus, menu_popup, key_char, is_current)
	local cmdlist, textlist = {"syn clear"}, {}
	local w, h = 4, 2

	if not utils_windows.find_menu_by_key(key_char, menus) then
		return menu_popup
	end

	w, h = get_dimensions(menus, w, h)
	menu_popup.keys = {}
	map_items(menu_popup.keys, cmdlist, menus, textlist, w)
	textlist = utils_buffer.frame(textlist, w, -1, config.border_chars)
	if menu_popup.open then
		menu_popup = M.close(menu_popup, true)
	end

	menu_popup.cmdlist = cmdlist
	menu_popup.idx, menu_popup.idx_max = 0, h - 2
	menu_popup.open = true
	menu_popup.w = w
	menu_popup.h = h

	setup_window(cmdlist, menu_popup, menus, textlist, w, h)
	setup_maps(M, menu_popup, menus)
	M.select_item_idx(1, menu_popup, menus)

	return menu_popup
end
-- }}}

-- {{{ M.select_item_after = function(after, step, menu_popup, menus)
M.select_item_after = function(after, step, menu_popup, menus)
	local idx_new = menu_popup.idx
	if step < 0 then
		while idx_new < menu_popup.idx_max do
			if menus.items[menus.idx].items[idx_new].display == after then
				idx_new = idx_new + 1
				break
			else
				idx_new = idx_new + 1
			end
		end
		if idx_new == menu_popup.idx_max then
			idx_new = 1
		end
	elseif step > 0 then
		while idx_new > 1 do
			if menus.items[menus.idx].items[idx_new].display == after then
				idx_new = idx_new - 1
				break
			else
				idx_new = idx_new - 1
			end
		end
		if idx_new == 1 then
			idx_new = menu_popup.idx_max
		end
	end
	select_item(idx_new, menu_popup, menus)
end
-- }}}
-- {{{ M.select_item_idx = function(idx_new, menu_popup, menus)
M.select_item_idx = function(idx_new, menu_popup, menus)
	if idx_new == -1 then
		idx_new = menu_popup.idx_max
	end
	select_item(idx_new, menu_popup, menus)
end
-- }}}
-- {{{ M.select_item_key = function(ch, menu_popup, menus)
M.select_item_key = function(ch, menu_popup, menus)
	local idx_new, key = menu_popup.idx, menu_popup.keys[ch]
	if key ~= nil then
		if type(key) == "table" then
			idx_new = utils.array_next(key, menu_popup.idx)
		else
			idx_new = menu_popup.keys[ch]
		end
	end
	select_item(idx_new, menu_popup, menus)

end
-- }}}
-- {{{ M.select_item_step = function(step, menu_popup, menus)
M.select_item_step = function(step, menu_popup, menus)
	local idx_new = menu_popup.idx
	if step < 0 then
		if menu_popup.idx == 1 then
			idx_new = menu_popup.idx_max
		else
			while idx_new > 1 do
				idx_new = idx_new - 1
				if menus.items[menus.idx].items[idx_new].title ~= "--" then
					break
				end
			end
		end
	elseif step > 0 then
		if menu_popup.idx == menu_popup.idx_max then
			idx_new = 1
		else
			while idx_new < menu_popup.idx_max do
				idx_new = idx_new + 1
				if menus.items[menus.idx].items[idx_new].title ~= "--" then
					break
				end
			end
		end
	end
	select_item(idx_new, menu_popup, menus)
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
