--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Partially based on vim-quickui code.
--

local utils = require("roarie-utils")
local utils_buffer = require("roarie-utils.buffer")
local utils_menu = require("roarie-utils.menu")

local M = {}

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
		if item["display"] ~= "--" then
			if string.match(item["display"], "\t") ~= nil then
				local display_ = {unpack(utils.split(item["display"], "[^\t]+"), 1, 2)}
				w = math.max(w, 2 + 2 + utils.ulen(display_[1]) + 3 + utils.ulen(display_[2]) + 2)
			else
				w = math.max(w, 2 + 2 + utils.ulen(item["display"]) + 2)
			end
		end
		h = h + 1
	end
	return w, h
end
-- }}}
-- {{{ local function items_to_textlist(keys, cmdlist, menus, textlist, w)
local function items_to_textlist(keys, cmdlist, menus, textlist, w)
	local y = 1
	for item_idx, item in ipairs(menus.items[menus.idx].items) do
		y = y + 1
		if item["display"] ~= "--" then
			if string.match(item["display"], "\t") ~= nil then
				local display = item["display"]
				display, key_char = utils_menu.highlight_accel(cmdlist, display, y, 2)
				add_key(keys, key_char, item_idx)

				display = {unpack(utils.split(display, "[^\t]+"), 1, 2)}
				local spacing = math.max(w - 2 - 2 - utils.ulen(display[1]) - utils.ulen(display[2]) - 2, 3)
				display = display[1]:gsub("&", "") .. string.rep(" ", spacing) .. display[2]

				menus.items[menus.idx].items[item_idx].menu_text = display
				table.insert(textlist, " " .. item["icon"] .. " " .. display .. " ")
			else
				local display = item["display"]
				display, key_char = utils_menu.highlight_accel(cmdlist, display, y, 2)
				add_key(keys, key_char, item_idx)

				menus.items[menus.idx].items[item_idx].menu_text = display
				table.insert(textlist, " " .. item["icon"] .. " " .. display .. " ")
			end
		else
			table.insert(textlist, "--")
		end
	end
end
-- }}}
-- {{{ local function select_item(idx_new, menu_popup, menus)
local function select_item(idx_new, menu_popup, menus)
	if idx_new ~= menu_popup.idx then
		menu_popup.idx = idx_new

		local cmdlist = {"syn clear"}
		for _, cmd in ipairs(menu_popup.cmdlist) do
			table.insert(cmdlist, cmd)
		end
		local map_x0, map_x1 = menus.items[menus.idx].items[idx_new].menu_text:find('<[^>]+>$')
		if map_x0 ~= nil then
			table.insert(cmdlist, utils.highlight_region(
				'QuickSel',
				menu_popup.idx + 1, 2,
				menu_popup.idx + 1, map_x0 + 4,
				true))
			table.insert(cmdlist, utils.highlight_region(
				'QuickSelMap',
				menu_popup.idx + 1, map_x0 + 4,
				menu_popup.idx + 1, map_x1 + 5,
				true))
			table.insert(cmdlist, utils.highlight_region(
				'QuickSel',
				menu_popup.idx + 1, map_x1 + 5,
				menu_popup.idx + 1, map_x1 + 6,
				true))
		else
			table.insert(cmdlist, utils.highlight_region(
				'QuickSel',
				menu_popup.idx + 1, 2,
				menu_popup.idx + 1, menu_popup.w,
				true))

		end
		utils.win_execute(menu_popup.winid, cmdlist, false)
		utils.highlight_border("QuickBorder", menus.items[menus.idx].items, menu_popup.w, menu_popup.h, menu_popup.winid)
	end
end
-- }}}

-- {{{ M.close = function(popup, redraw)
M.close = function(popup, redraw)
	if popup.winid ~= nil then
		vim.api.nvim_win_close(popup.winid, 0)
		popup.winid = nil
		if redraw then
			vim.cmd [[redraw]]
		end
	end
	popup.open = false

	return popup
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
		open=nil,
		winid=nil,
		w=nil, h=nil
	}
end
-- }}}
-- {{{ M.open = function(menus, menu_popup, key_char)
M.open = function(menus, menu_popup, key_char)
	local cmdlist, textlist = {"syn clear"}, {}
	local keys = {}
	local w, h = 4, 2

	if not utils_menu.find(key_char, menus) then
		return menu_popup
	else
		w, h = get_dimensions(menus, w, h)
		items_to_textlist(keys, cmdlist, menus, textlist, w)
		textlist = utils_buffer.frame(textlist, w, h, nil)
		menu_popup = M.close(menu_popup, true)
	end

	local opts = {
		col=menus.items[menus.idx].x, row=1,
		focusable=1,
		noautocmd=1,
		relative='editor',
		style='minimal',
		width=w, height=h,
	}

	menu_popup.cmdlist = cmdlist
	menu_popup.idx, menu_popup.idx_max = 0, h - 2
	menu_popup.keys = keys
	menu_popup.open = true
	menu_popup.w, menu_popup.h = w, h

	menu_popup.bid = utils_buffer.create_scratch("context", textlist)
	menu_popup.winid = vim.api.nvim_open_win(menu_popup.bid, 0, opts)

	vim.api.nvim_set_current_win(menu_popup.winid)
	utils.win_execute(menu_popup.winid, cmdlist, false)
	vim.api.nvim_win_set_option(menu_popup.winid, 'winhl', 'Normal:QuickBG,CursorColumn:QuickBG,CursorLine:QuickBorder')
	vim.api.nvim_win_set_option(menu_popup.winid, 'cursorline', false)
	M.select_item_idx(1, menu_popup, menus)
	utils.highlight_border("QuickBorder", menus.items[menus.idx].items, menu_popup.w, menu_popup.h, menu_popup.winid)

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
