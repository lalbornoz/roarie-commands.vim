--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Partially based on vim-quickui code.
--

local utils = require("roarie-utils")
local utils_buffer = require("roarie-utils.buffer")

local M = {}

-- {{{ M.close = function(menu)
M.close = function(menu)
	vim.api.nvim_win_close(menu.winid, 0)
end
-- }}}
-- {{{ M.find = function(key_char, menus)
M.find = function(key_char, menus)
	if key_char ~= nil then
		local found = false
		key_char = string.lower(key_char)
		for idx, item in ipairs(menus.items) do
			if  (item.key_char ~= nil)
			and (string.lower(item.key_char) == key_char)
			then
				found, menus.idx = true, idx
				break
			end
		end
		return found
	else
		return true
	end
end
-- }}}
-- {{{ M.highlight_accel = function(cmdlist, display, y, x_offset)
M.highlight_accel = function(cmdlist, display, y, x_offset)
	local key_pos = vim.fn.match(display, "&")
	local key_char = nil
	if key_pos >= 0 then
		key_pos = key_pos + 1
		key_char = string.lower(string.sub(display, key_pos + 1, key_pos + 1))
		if cmdlist ~= nil then
			local x = key_pos + 2
			table.insert(
				cmdlist,
				utils.highlight_region(
					'QuickKey', y, x + x_offset,
					y, x + x_offset + 1, true))
		end
	end
	return display:gsub("&", ""), key_char, key_pos
end
-- }}}
-- {{{ M.init = function(menus, help_text)
M.init = function(menus, help_text)
	local menu = {
		bid=nil, winid=nil,
		idx=1,
		items={},
		size=-1,
		state=1,
		text="",
	}

	order_fn = function(t, a, b)
		return b > a
	end
	local x = 0
	for priority, menu_ in utils.spairs(menus, order_fn) do
		local _, key_char, key_pos = M.highlight_accel(nil, menu_.name, -1, 1)
		local name = menu_.name:gsub("&", "")
		local w = name:len() + 2

		menu.text = menu.text .. " " .. name .. " " .. "  "
		table.insert(menu.items, {
			items=menu_.items,
			key_char=key_char,
			key_pos=key_pos,
			name=name,
			text=" " .. name .. " ",
			x=x, w=w,
		})

		x = x + w + 2
	end
	menu.size = table.getn(menu.items)

	if help_text ~= nil then
		menu.text =
			   menu.text
			.. string.rep(" ", (vim.o.columns - menu.text:len() - help_text:len() - 1))
			.. help_text
	end

	local opts = {
		col=0, row=0,
		focusable=1,
		noautocmd=1,
		relative='editor',
		style='minimal',
		width=vim.o.columns, height=1,
	}

	menu.bid = utils_buffer.create_scratch("menu", menu.text)
	menu.winid = vim.api.nvim_open_win(menu.bid, 0, opts)
	vim.api.nvim_win_set_option(menu.winid, 'winhl', 'Normal:QuickBG,CursorColumn:QuickBG,CursorLine:QuickBG')

	return menu
end
-- }}}
-- {{{ M.update = function(menus)
M.update = function(menus)
	if menus.state == 0 then
		return -1
	end

	local guicursor_old = vim.o.guicursor
	local hl_cursor_old = vim.api.nvim_get_hl(0, {name="Cursor"})
	local cmdlist = {
		"hi Cursor blend=100",
		"set guicursor+=a:Cursor/lCursor",
		"set nocursorline",
		"syn clear"}

	for _, item in ipairs(menus.items) do
		if item.key_pos >= 0 then
			local x = item.key_pos + item.x + 1
			table.insert(cmdlist, utils.highlight_region('QuickKey', 1, x, 1, x + 1, true))
		end
	end

	if (menus.idx >= 1) and (menus.idx <= menus.size) then
		local x0 = menus.items[menus.idx].x + 1
		local x1 = x0 + menus.items[menus.idx].w
		table.insert(cmdlist, utils.highlight_region('QuickSel', 1, x0, 1, x1, true))
	end

	utils.win_execute(menus.winid, cmdlist, false)
	return guicursor_old, hl_cursor_old
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
