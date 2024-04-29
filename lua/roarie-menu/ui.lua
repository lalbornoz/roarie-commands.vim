--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Partially based on vim-quickui code.
--

local menus = {}

local config = require("roarie-menu.config")
local utils = require("roarie-utils")
local utils_help_screen = require("roarie-utils.help_screen")
local utils_menu = require("roarie-utils.menu")
local utils_popup_menu = require("roarie-utils.popup_menu")

local M = {}

-- {{{ function menu_loop(loop_status, menu_popup, menus, help_screen)
function menu_loop(loop_status, menu_popup, menus, help_screen)
	guicursor_old, hl_cursor_old = utils_menu.update(menus)
	vim.cmd [[redraw]]

	local menu_popup_idx = nil
	local code, ch = utils.getchar()

	-- {{{ if (code == utils.termcodes.ETX) or (code == utils.termcodes.ESC) then
	if (code == utils.termcodes.ETX) or (code == utils.termcodes.ESC) then
		loop_status = false
	-- }}}
	-- {{{ elseif (ch == "?") then
	elseif (ch == "?") then
		utils_help_screen.toggle(help_screen)
	-- }}}
	-- {{{ elseif ((ch == " ") or (ch == "\r")) ...
	elseif ((ch == " ") or (ch == "\r"))
	   and menu_popup.open
	then
		loop_status, menu_popup_idx = false, menu_popup.idx
	-- }}}
	-- {{{ elseif (ch >= "a") and (ch <= "z") then
	elseif (ch >= "a") and (ch <= "z") then
		if menu_popup.open then
			utils_popup_menu.select_item_key(ch, menu_popup, menus)
		end
	-- }}}
	-- {{{ elseif ((ch >= "A") and (ch <= "Z")) ...
	elseif ((ch >= "A") and (ch <= "Z"))
	   or  ((ch >= "0") and (ch <= "9")) then
		menu_popup = utils_popup_menu.open(menus, menu_popup, string.lower(ch))
	-- }}}
	-- {{{ elseif (code == utils.termcodes.Left) or (code == utils.termcodes.Right) then
	elseif (code == utils.termcodes.Left) or (code == utils.termcodes.Right) then
		if code == utils.termcodes.Left then
			if menus.idx > 1 then menus.idx = menus.idx - 1 else menus.idx = menus.size end
		else
			if menus.idx < menus.size then menus.idx = menus.idx + 1 else menus.idx = 1 end
		end

		if menu_popup.open then
			menu_popup = utils_popup_menu.close(menu_popup, false)
			menu_popup = utils_popup_menu.open(menus, menu_popup, nil)
		else
			menu_popup = utils_popup_menu.close(menu_popup, true)
		end
	-- }}}
	-- {{{ elseif (code == utils.termcodes.Down) or (code == utils.termcodes.Up) or (code == utils.termcodes.Space) then
	elseif (code == utils.termcodes.Down) or (code == utils.termcodes.Up) or (code == utils.termcodes.Space) then
		if menu_popup.open then
			if code == utils.termcodes.Down then
				utils_popup_menu.select_item_step(1, menu_popup, menus)
			else
				utils_popup_menu.select_item_step(-1, menu_popup, menus)
			end
		elseif (code == utils.termcodes.Down) or (code == utils.termcodes.Space) then
			menu_popup = utils_popup_menu.open(menus, menu_popup, nil)
		end
	-- }}}
	-- {{{ elseif menu_popup.open and (code == utils.termcodes.Page{Down,Up}) then
	elseif menu_popup.open and (code == utils.termcodes.PageDown) then
		utils_popup_menu.select_item_after("--", -1, menu_popup, menus)
	elseif menu_popup.open and (code == utils.termcodes.PageUp) then
		utils_popup_menu.select_item_after("--", 1, menu_popup, menus)
	-- }}}
	-- {{{ elseif menu_popup.open and (code == utils.termcodes.{Home,End}) then
	elseif menu_popup.open and (code == utils.termcodes.Home) then
		utils_popup_menu.select_item_idx(1, menu_popup, menus)
	elseif menu_popup.open and (code == utils.termcodes.End) then
		utils_popup_menu.select_item_idx(menu_popup.idx_max, menu_popup, menus)
	-- }}}
	end

	vim.o.guicursor = guicursor_old
	vim.api.nvim_set_hl(0, "Cursor", hl_cursor_old)
	return loop_status, menu_popup_idx
end
-- }}}

-- {{{ M.Install = function(menu, items, priority)
M.Install = function(menu, items, priority)
	menus[priority] = {
		priority=priority,
		items=items,
		name=menu,
	}
end
-- }}}
-- {{{ M.OpenMenu = function()
M.OpenMenu = function()
	local loop_status = true
	local menus, menu_popup = utils_menu.init(menus, config.help_text),
				  utils_popup_menu.init()

	while loop_status do
		loop_status, menu_popup_idx =
			menu_loop(
				loop_status, menu_popup,
				menus, config.help_screen)
	end

	utils_help_screen.close()
	utils_popup_menu.close(menu_popup, true)
	utils_menu.close(menus)
	vim.cmd [[redraw]]

	if menu_popup_idx ~= nil then
		vim.fn.feedkeys(
			vim.api.nvim_replace_termcodes(
				menus.items[menus.idx].items[menu_popup_idx].lhs,
				true, true, true))
	end
end
-- }}}
-- {{{ M.Reset = function()
M.Reset = function()
	menus = {}
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
