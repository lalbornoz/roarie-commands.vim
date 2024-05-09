--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local utils = require("roarie-utils")

local M = {}

-- {{{ M.find_menu_by_key = function(key_char, menus)
M.find_menu_by_key = function(key_char, menus)
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
				M.highlight_region(
					'QuickKey', y, x + x_offset,
					y, x + x_offset + 1, true))
		end
	end
	return display:gsub("&", ""), key_char, key_pos
end
-- }}}
-- {{{ M.highlight_border = function(hl_group, items, w, h, winid)
M.highlight_border = function(hl_group, items, w, h, winid)
	local cmdlist = {}
	table.insert(cmdlist, M.highlight_region(hl_group, 1, 1, 1, w + 1, true))
	for y=2,(h-1) do
		table.insert(cmdlist, M.highlight_region(hl_group, y, 1, y, 2, true))
		table.insert(cmdlist, M.highlight_region(hl_group, y, w, y, w + 1, true))
	end
	table.insert(cmdlist, M.highlight_region(hl_group, h, 1, h, w + 1, true))
	for item_idx, item in ipairs(items) do
		if item.display == "--" then
			table.insert(cmdlist, M.highlight_region(hl_group, item_idx + 1, 1, item_idx + 1, w + 1, true))
		end
	end
	utils.win_execute(winid, cmdlist, false)
	vim.api.nvim_win_set_option(winid, "cursorline", false)
end
-- }}}
-- {{{ M.highlight_region = function(name, srow, scol, erow, ecol, virtual)
M.highlight_region = function(name, srow, scol, erow, ecol, virtual)
	local sep = ''
	if not virtual then sep = 'c' else sep = 'v' end
	local cmd = 'syn region ' .. name .. ' '
	cmd = cmd .. ' start=/\\%' .. srow .. 'l\\%' .. scol .. sep .. '/'
	cmd = cmd .. ' end=/\\%' .. erow .. 'l\\%' .. ecol .. sep .. '/'
	return cmd
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
