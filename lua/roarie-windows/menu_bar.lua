--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local config = require("roarie-menu.config")
local utils = require("roarie-utils")
local utils_buffer = require("roarie-utils.buffer")
local utils_help_screen = require("roarie-windows.help_screen")
local utils_popup_menu = require("roarie-windows.popup_menu")
local utils_windows = require("roarie-windows.utils")

local M = {}

-- {{{ local function forward_to_popup_menu(lhs)
local function forward_to_popup_menu(lhs)
	return function(M, menu_popup, menu_win)
		return function ()
			local rc = nil
			if menu_popup.open then
				vim.api.nvim_set_current_win(menu_popup.winid)
				vim.api.nvim_set_current_buf(menu_popup.bid)
				rc = menu_popup.maps[lhs](M, menu_popup, menu_win)()
				if menu_win.winid ~= nil then
					vim.api.nvim_set_current_win(menu_win.winid)
					vim.api.nvim_set_current_buf(menu_win.bid)
					M.update(menu_win)
				end
			end
			return rc
		end
	end
end
-- }}}
-- {{{ local function activate_item(key)
local function activate_item(key)
	return function(M, menu_popup, menu_win)
		return function()
			local lhs = forward_to_popup_menu(key)(M, menu_popup, menu_win)()
			utils_popup_menu.close(menu_popup, true)
			M.close(menu_win)
			vim.cmd [[redraw]]
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, true, true), "m", false)
		end
	end
end
-- }}}
-- {{{ local function close_menu(M, menu_popup, menu_win)
local function close_menu(M, menu_popup, menu_win)
	return function()
		utils_popup_menu.close(menu_popup, true)
		M.close(menu_win)
		vim.cmd [[redraw]]
	end
end
-- }}}
-- {{{ local function either(expr, if_true, if_false)
local function either(expr, if_true, if_false)
	return function(M, menu_popup, menu_win)
		return function()
			if expr(menu_popup) then
				return if_true(M, menu_popup, menu_win)()
			else
				return if_false(M, menu_popup, menu_win)()
			end
		end
	end
end
-- }}}
-- {{{ local function open_menu(key)
local function open_menu(key)
	return function(M, menu_popup, menu_win)
		return function()
			if not menu_popup.open then
				utils_popup_menu.open(menu_win, menu_popup, nil)
				M.update(menu_win, false)
			else
				forward_to_popup_menu(key)(M, menu_popup, menu_win)()
			end
		end
	end
end
-- }}}
-- {{{ local function select_menu_dir(dir)
local function select_menu_dir(dir)
	return function(M, menu_popup, menu_win)
		return function()
			if dir < 0 then
				if menu_win.idx > 1 then
					menu_win.idx = menu_win.idx - 1
				else
					menu_win.idx = menu_win.size
				end
			elseif dir > 0 then
				if menu_win.idx < menu_win.size then
					menu_win.idx = menu_win.idx + 1
				else
					menu_win.idx = 1
				end
			end
			if menu_popup.open then
				utils_popup_menu.close(menu_popup, false)
				utils_popup_menu.open(menu_win, menu_popup, nil)
			end
			M.update(menu_win)
		end
	end
end
-- }}}
-- {{{ local function select_menu_key(key_char)
local function select_menu_key(key_char)
	return function(M, menu_popup, menu_win)
		return function()
			utils_popup_menu.open(menu_win, menu_popup, string.lower(key_char), false)
			M.update(menu_win)
		end
	end
end
-- }}}
-- {{{ local function toggle_help(M, menu_popup, menu_win)
local function toggle_help(M, menu_popup, menu_win)
	return function()
		utils_help_screen.toggle(config.help_screen, menu_popup, false)
		M.update(menu_win)
	end
end
-- }}}
-- {{{ local maps_default = {}
local maps_default = {
	["<Esc>"] = close_menu,
	["<C-c>"] = close_menu,
	["<Down>"] = open_menu("<Down>"),
	["<Up>"] = forward_to_popup_menu("<Up>"),
	["<Left>"] = select_menu_dir(-1),
	["<Right>"] = select_menu_dir(1),
	["?"] = toggle_help,

	["<PageDown>"] = forward_to_popup_menu("<PageDown>"),
	["<PageUp>"] = forward_to_popup_menu("<PageUp>"),
	["<Home>"] = forward_to_popup_menu("<Home>"),
	["<End>"] = forward_to_popup_menu("<End>"),

	[" "] = either(function(menu_popup) return menu_popup.open end, activate_item(" "), open_menu(" ")),
	["<CR>"] = activate_item("<CR>"),

	-- {{{ ["A"]...["Z"], ["0"]...["9"] = select_menu_key(...)
	["A"] = select_menu_key("A"),
	["B"] = select_menu_key("B"),
	["C"] = select_menu_key("C"),
	["D"] = select_menu_key("D"),
	["E"] = select_menu_key("E"),
	["F"] = select_menu_key("F"),
	["G"] = select_menu_key("G"),
	["H"] = select_menu_key("H"),
	["I"] = select_menu_key("I"),
	["J"] = select_menu_key("J"),
	["K"] = select_menu_key("K"),
	["L"] = select_menu_key("L"),
	["M"] = select_menu_key("M"),
	["N"] = select_menu_key("N"),
	["O"] = select_menu_key("O"),
	["P"] = select_menu_key("P"),
	["Q"] = select_menu_key("Q"),
	["R"] = select_menu_key("R"),
	["S"] = select_menu_key("S"),
	["T"] = select_menu_key("T"),
	["U"] = select_menu_key("U"),
	["V"] = select_menu_key("V"),
	["W"] = select_menu_key("W"),
	["X"] = select_menu_key("X"),
	["Y"] = select_menu_key("Y"),
	["Z"] = select_menu_key("Z"),
	["0"] = select_menu_key("0"),
	["1"] = select_menu_key("1"),
	["2"] = select_menu_key("2"),
	["3"] = select_menu_key("3"),
	["4"] = select_menu_key("4"),
	["5"] = select_menu_key("5"),
	["6"] = select_menu_key("6"),
	["7"] = select_menu_key("7"),
	["8"] = select_menu_key("8"),
	["9"] = select_menu_key("9"),
	-- }}}
	-- {{{ ["<M-a>"]...["M-z"] = forward_to_popup_menu(...)
	["<M-a>"] = forward_to_popup_menu("<M-a>"),
	["<M-b>"] = forward_to_popup_menu("<M-b>"),
	["<M-c>"] = forward_to_popup_menu("<M-c>"),
	["<M-d>"] = forward_to_popup_menu("<M-d>"),
	["<M-e>"] = forward_to_popup_menu("<M-e>"),
	["<M-f>"] = forward_to_popup_menu("<M-f>"),
	["<M-g>"] = forward_to_popup_menu("<M-g>"),
	["<M-h>"] = forward_to_popup_menu("<M-h>"),
	["<M-i>"] = forward_to_popup_menu("<M-i>"),
	["<M-j>"] = forward_to_popup_menu("<M-j>"),
	["<M-k>"] = forward_to_popup_menu("<M-k>"),
	["<M-l>"] = forward_to_popup_menu("<M-l>"),
	["<M-m>"] = forward_to_popup_menu("<M-m>"),
	["<M-n>"] = forward_to_popup_menu("<M-n>"),
	["<M-o>"] = forward_to_popup_menu("<M-o>"),
	["<M-p>"] = forward_to_popup_menu("<M-p>"),
	["<M-q>"] = forward_to_popup_menu("<M-q>"),
	["<M-r>"] = forward_to_popup_menu("<M-r>"),
	["<M-s>"] = forward_to_popup_menu("<M-s>"),
	["<M-t>"] = forward_to_popup_menu("<M-t>"),
	["<M-u>"] = forward_to_popup_menu("<M-u>"),
	["<M-v>"] = forward_to_popup_menu("<M-v>"),
	["<M-w>"] = forward_to_popup_menu("<M-w>"),
	["<M-x>"] = forward_to_popup_menu("<M-x>"),
	["<M-y>"] = forward_to_popup_menu("<M-y>"),
	["<M-z>"] = forward_to_popup_menu("<M-z>"),
	-- }}}
}
-- }}}


-- {{{ local function setup_help(help_text, menu_win)
local function setup_help(help_text, menu_win)
	if help_text ~= nil then
		menu_win.text = menu_win.text
			     .. string.rep(" ", (vim.o.columns - utils.ulen(menu_win.text .. help_text .. " ")))
			     .. help_text
	end
end
-- }}}
-- {{{ local function setup_maps(M, menu_popup, menu_win)
local function setup_maps(M, menu_popup, menu_win)
	menu_win.maps = {}
	for lhs, rhs in pairs(maps_default) do
		vim.keymap.set(
			{"n", "i"}, lhs, rhs(M, menu_popup, menu_win),
			{buffer=menu_win.bid, noremap=true})
		menu_win.maps[lhs] = rhs
	end
end
-- }}}
-- {{{ local function setup_menus(commands, menu_win)
local function setup_menus(commands, menu_win)
	order_fn = function(t, a, b)
		return b > a
	end

	local x = 0
	for priority, menu_win_ in utils.spairs(commands, order_fn) do
		local _, key_char, key_pos =
			utils_windows.highlight_accel(
				nil, menu_win_.name, -1, 1)
		local name = menu_win_.name:gsub("&", "")
		local w = utils.ulen(name) + 2

		menu_win.text = menu_win.text .. " " .. name .. " " .. "  "
		table.insert(menu_win.items, {
			items=menu_win_.items,
			key_char=key_char,
			key_pos=key_pos,
			name=name,
			text=" " .. name .. " ",
			x=x,
			w=w,
		})

		x = x + w + 2
	end
	menu_win.size = #menu_win.items
end
-- }}}
-- {{{ local function setup_window(menu_popup, menu_win)
local function setup_window(menu_popup, menu_win)
	local opts = {
		col=0, row=0,
		focusable=1,
		noautocmd=1,
		relative="editor",
		style="minimal",
		width=vim.o.columns,
		height=1,
	}

	menu_win.bid = utils_buffer.create_scratch("menu_win", menu_win.text)
	menu_win.winid = vim.api.nvim_open_win(menu_win.bid, 0, opts)
	vim.api.nvim_set_current_win(menu_win.winid)
	vim.api.nvim_set_current_buf(menu_win.bid)
	vim.api.nvim_win_set_option(
		menu_win.winid, "winhl",
		"Normal:QuickBG,CursorColumn:QuickBG,CursorLine:QuickBG")

	menu_win.autocmd_id = vim.api.nvim_create_autocmd({"WinEnter"}, {
		callback=function(ev)
			local winid_new = vim.api.nvim_get_current_win()
			local bid_new = vim.api.nvim_get_current_buf()
			if bid_new == menu_win.bid then
				M.update(menu_win)
			elseif bid_new ~= menu_popup.bid then
				vim.cmd [[hi Cursor blend=0]]
				vim.cmd [[set guicursor-=a:Cursor/lCursor]]
				utils_popup_menu.close(menu_popup, true)
				M.close(menu_win)
				vim.cmd [[redraw]]
			end
		end,
	})
end
-- }}}


-- {{{ M.close = function(menu_win)
M.close = function(menu_win)
	utils_help_screen.close()

	if menu_win.winid ~= nil then
		local winid = menu_win.winid
		menu_win.winid = nil
		vim.api.nvim_win_close(winid, 0)
	end

	if menu_win.bid ~= nil then
		local bid = menu_win.bid
		menu_win.bid = nil
		utils_buffer.free(bid, "menu_win")
	end

	if vim.o.guicursor ~= menu_win.guicursor_old then
		vim.o.guicursor = menu_win.guicursor_old
		vim.api.nvim_set_hl(0, "Cursor", menu_win.hl_cursor_old)
	end

	if menu_win.autocmd_id ~= nil then
		local autocmd_id = menu_win.autocmd_id
		menu_win.autocmd_id = nil
		vim.api.nvim_del_autocmd(autocmd_id)
	end
end
-- }}}
-- {{{ M.open = function(commands, help_text)
M.open = function(commands, help_text)
	local menu_win = {
		autocmd_id=nil,
		bid=nil,
		guicursor_old=vim.o.guicursor,
		hl_cursor_old=vim.api.nvim_get_hl(0, {name="Cursor"}),
		idx=1,
		items={},
		size=-1,
		state=1,
		text="",
		winid=nil,
	}

	local menu_popup = utils_popup_menu.init()

	setup_menus(commands, menu_win)
	setup_help(help_text, menu_win)
	setup_window(menu_popup, menu_win)
	setup_maps(M, menu_popup, menu_win)
	M.update(menu_win)

	return menu_win
end
-- }}}
-- {{{ M.update = function(menu_win)
M.update = function(menu_win)
	local cmdlist = {
		"hi Cursor blend=100",
		"set guicursor+=a:Cursor/lCursor",
		"set nocursorline",
		"syn clear"}

	for _, item in ipairs(menu_win.items) do
		if item.key_pos >= 0 then
			local x = item.key_pos + item.x + 1
			table.insert(
				cmdlist, utils_windows.highlight_region(
				"QuickKey", 1, x, 1, x + 1, true))
		end
	end

	if (menu_win.idx >= 1) and (menu_win.idx <= menu_win.size) then
		local x0 = menu_win.items[menu_win.idx].x + 1
		local x1 = x0 + menu_win.items[menu_win.idx].w
		table.insert(
			cmdlist, utils_windows.highlight_region(
			"QuickSel", 1, x0, 1, x1, true))
	end

	utils.win_execute(menu_win.winid, cmdlist, false)
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
