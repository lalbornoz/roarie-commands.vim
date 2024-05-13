--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local config_defaults = {
	border_chars = {
		'╭', '─', '╮',
		'│', '─', '│',
		'╰', '─', '╯',
		'├', '┤',
	},

	help_screen = {
		"<{Esc,C-C}>                             Exit menu mode",
		"<{S-[a-z],[0-9]}>                       Select and open menu with accelerator",
		"<{Left,Right}>                          Select menu; will open menu automatically if menu is not open",
		"<{Down,Space}>                          Open menu",
		"<M-[a-z]>, <{Page,}{Down,Up},Home,End>  In menu: select item, scroll through items",
		"<{Space,Enter}>                         In menu: activate menu item",
		"<M-[a-z]>, <{Page,}{Down,Up}>           In submenu: select item with accelerator",
		"<Enter>                                 In submenu: execute prompt",
		"<Tab>                                   In submenu: complete ex command",
	},
	help_text = "Press   for help",

	highlights = {
		QuickBG = {ctermfg=251, ctermbg=236, fg="#c6c6c6", bg="#303030"},
		QuickBorder = {ctermfg=251, ctermbg=236, fg="#0679a5", bg="#303030"},
		QuickSel = {ctermfg=236, ctermbg=251, fg="#303030", bg="#f5a9b8"},
		QuickSelMap = {ctermfg=236, ctermbg=251, underline=true, fg="#0679a5", bg="#f5a9b8"},
		QuickKey = {ctermfg=179, underline=true, fg="#87d7d7"},
	},

	mod_order = {
		'',
		'S-',
		'C-',
		'C-S-',
		'M-',
		'M-S-',
		'M-C-',
		'M-C-S-',
	},
}

local config = require("roarie-menu.config")
local utils = require("roarie-utils")
local utils_help_screen = require("roarie-windows.help_screen")
local utils_menu = require("roarie-windows.menu_bar")
local utils_popup_menu = require("roarie-windows.popup_menu")
local utils_submenu = require("roarie-windows.submenu")

local M = {}

local commands = {}
local commands_by_name = {}
local commands_by_id = {}
local fn_tmp_menu = "<Fn>"
local submenus = {}

-- {{{ local function GetMappingMode(mode, lhs)
local function GetMappingMode(mode, lhs)
	if mode == "insert" then
		return "inoremap"
	elseif mode == "normal" then
		return "nnoremap"
	elseif mode == "nvo" then
		return "noremap"
	elseif mode == "terminal" then
		return "tnoremap"
	elseif mode == "visual" then
		return "vnoremap"
	else
		vim.api.nvim_err_writeln("Invalid mode " .. mode .. " for mapping: " .. lhs)
	end
end
-- }}}
-- {{{ local function AddMapping_(noaddfl, menu, id, title, mode, descr, silent, lhs, rhs, pseudofl, icon)
local function AddMapping_(noaddfl, menu, id, title, mode, descr, silent, lhs, rhs, pseudofl, icon)
	local map_line = {GetMappingMode(mode, lhs)}

	if not noaddfl then
		if utils.ulen(descr) == 0 then
			descr = title
		end

		local display = nil
		local keys = lhs
		keys = vim.fn.substitute(keys, '<Leader>', vim.g.mapleader, '')
		keys = vim.fn.substitute(keys, '<', '\\\\<', '')

		if title ~= "--" then
			display = title .. "\t" .. lhs
		else
			display = "--"
		end

		local menu_item = {
			descr=descr,
			display=display,
			icon=icon,
			id=id,
			lhs=lhs,
			menu=menu,
			mode=mode,
			rhs=rhs,
			title=title,
		}

		table.insert(commands[commands_by_name[menu]].items, menu_item)
		if commands_by_id[id] == nil then
			commands_by_id[id] = {}
		end
		table.insert(commands_by_id[id], menu_item)
	end

	if pseudofl == "<fnalias>" then
		if commands[commands_by_name[fn_tmp_menu]] == nil then
			M.AddMenu(fn_tmp_menu, 0, true)
		end

		AddMapping_(
			noaddfl, fn_tmp_menu, id, title,
			mode, descr, silent, lhs, rhs,
			"<pseudo>", icon)
	end

	if pseudofl ~= "<pseudo>" then
		if silent == "<silent>" then
			table.insert(map_line, "<silent>")
		end

		table.insert(map_line, lhs)
		table.insert(map_line, rhs)
		vim.fn.execute(table.concat(map_line, " "))
	end
end
-- }}}

-- {{{ local function PopulateFnMenu(src_items, dst_title, key_to, sep_each)
local function PopulateFnMenu(src_items, dst_title, key_to, sep_each)
	local key_last = 0

	for item_idx=1,table.getn(src_items) do
		local item = src_items[item_idx]
		local key_cur = vim.fn.str2nr(
			vim.fn.matchstr(
				item.lhs,
				'^<\\([MCS]-\\)*F\\zs[0-9]\\+\\ze'))

		if key_cur > key_to then
			if item_idx > 1 then
				for idx=1,(item_idx-1) do
					table.remove(src_items, 1)
				end
			end
			break
		else
			if key_last == 0 then
				key_last = key_cur
			elseif (key_cur ~= key_last)
			   and (((key_cur - 1) % sep_each) == 0)
			then
				key_last = key_cur
				M.AddSeparator(dst_title)
			end
			table.insert(commands[commands_by_name[dst_title]].items, item)
		end
	end

	return src_items
end
-- }}}
-- {{{ local function SortFnMenuFn(lhs, rhs)
local function SortFnMenuFn(lhs, rhs)
	local lhs_key = vim.fn.str2nr(vim.fn.matchstr(lhs.lhs, '^<\\([MCS]-\\)*F\\zs[0-9]\\+\\ze'))
	local rhs_key = vim.fn.str2nr(vim.fn.matchstr(rhs.lhs, '^<\\([MCS]-\\)*F\\zs[0-9]\\+\\ze'))
	if lhs_key < rhs_key then
		return -1
	elseif lhs_key > rhs_key then
		return 1
	else
		local lhs_mod = vim.fn.matchstr(lhs.lhs, '^<\\zs\\([MCS-]\\)*\\ze')
		local lhs_priority = vim.fn.index(config.mod_order or {}, lhs_mod)
		local rhs_mod = vim.fn.matchstr(rhs.lhs, '^<\\zs\\([MCS-]\\)*\\ze')
		local rhs_priority = vim.fn.index(config.mod_order or {}, rhs_mod)
		if lhs_priority < rhs_priority then
			return -1
		elseif lhs_priority > rhs_priority then
			return 1
		else
			return 0
		end
	end
end
-- }}}
-- {{{ local function SortFnMenu()
local function SortFnMenu()
	return vim.fn.sort(
		commands[commands_by_name[fn_tmp_menu]].items,
		SortFnMenuFn)
end
-- }}}
-- {{{ local function SortMenus(lhs, rhs)
local function SortMenus(lhs, rhs)
	local lhs_item, rhs_item = commands[lhs], commands[rhs]

	if lhs_item.priority < rhs_item.priority then
		return -1
	elseif lhs_item.priority > rhs_item.priority then
		return 1
	else
		return 0
	end
end
-- }}}

-- {{{ M.AddMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
M.AddMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
	return AddMapping_(false, menu, id, title, 'nvo', descr, silent, lhs, rhs, pseudofl, icon)
end
-- }}}
-- {{{ M.AddIMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
M.AddIMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
	return AddMapping_(false, menu, id, title, 'insert', descr, silent, lhs, rhs, pseudofl, icon)
end
-- }}}
-- {{{ M.AddINVOMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
M.AddINVOMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
	AddMapping_(false, menu, id, title, 'nvo', descr, silent, lhs, rhs, pseudofl, icon)
	return AddMapping_(true, menu, id, title, 'insert', descr, silent, lhs, rhs, pseudofl, icon)
end
-- }}}
-- {{{ M.AddNMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
M.AddNMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
	return AddMapping_(false, menu, id, title, 'normal', descr, silent, lhs, rhs, pseudofl, icon)
end
-- }}}
-- {{{ M.AddTMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
M.AddTMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
	return AddMapping_(false, menu, id, title, 'terminal', descr, silent, lhs, rhs, pseudofl, icon)
end
-- }}}
-- {{{ M.AddVMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
M.AddVMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl, icon)
	return AddMapping_(false, menu, id, title, 'visual', descr, silent, lhs, rhs, pseudofl, icon)
end
-- }}}

-- {{{ M.AddMenu = function(title, priority, ignore_in_palette)
M.AddMenu = function(title, priority, ignore_in_palette)
	commands_by_name[title] = priority
	commands[priority] = {
		ignore_in_palette=ignore_in_palette,
		items={},
		name=title,
		priority=priority,
	}
end
-- }}}
-- {{{ M.AddSeparator = function(menu)
M.AddSeparator = function(menu)
	table.insert(commands[commands_by_name[menu]].items, {
		descr='',
		display='--',
		lhs='',
		rhs='',
		title='--',
	})
end
-- }}}
-- {{{ M.AddSubMenu = function(id, title, ignore_in_palette)
M.AddSubMenu = function(id, title, ignore_in_palette)
	submenus[id] = {
		idx=0,
		ignore_in_palette=ignore_in_palette,
		idx_max=0,
		items={},
		keys=nil,
		open=false,
		title=title,
		w=0,
		h=0,
	}
end
-- }}}
-- {{{ M.AddSubMenuItem = function(id, icon, title, rhs, fn_display, fn_rhs)
M.AddSubMenuItem = function(id, icon, title, rhs, fn_display, fn_rhs)
	local display = title:gsub("&", "")
	local key_pos = vim.fn.match(title, "&")
	local key_char = nil

	if key_pos >= 0 then
		key_pos = key_pos + 1
		key_char = string.lower(string.sub(display, key_pos + 1, key_pos + 1))
	end

	submenus[id].idx_max = submenus[id].idx_max + 1
	submenus[id].w = math.max(submenus[id].w, utils.ulen(icon .. " " .. display) + 2 + 2)

	if (fn_display ~= nil) and (fn_display ~= "") then
		fn_display = loadstring(fn_display)
	else
		fn_display = nil
	end
	if (fn_rhs ~= nil) and (fn_rhs ~= "") then
		fn_rhs = loadstring(fn_rhs)
	else
		fn_rhs = nil
	end

	table.insert(submenus[id].items, {
		display=title,
		fn_display=fn_display,
		fn_rhs=fn_rhs,
		icon=icon,
		key_char=key_char, key_pos=key_pos,
		term=term,
		rhs=rhs,
		w=utils.ulen(display),
	})
end
-- }}}
-- {{{ M.Reset = function()
M.Reset = function()
	commands = {}
	commands_by_name = {}
	commands_by_id = {}
	submenus = {}
end
-- }}}
-- {{{ M.SetupFnMenus = function(ltitle, lpriority, lkey_to, lsep_each)
M.SetupFnMenus = function(ltitle, lpriority, lkey_to, lsep_each)
	local menu_items = SortFnMenu()
	commands[commands_by_name[fn_tmp_menu]] = nil
	for idx=1,table.getn(lpriority) do
		M.AddMenu(ltitle[idx], lpriority[idx], true)
		menu_items = PopulateFnMenu(menu_items, ltitle[idx], lkey_to[idx], lsep_each[idx])
	end
end
-- }}}

-- {{{ M.GetMapping = function(menu, id)
M.GetMapping = function(menu, id)
	if commands_by_id[id] ~= nil then
		for _, cmd in ipairs(commands_by_id[id]) do
			if cmd.menu == menu then
				return cmd
			end
		end
	end
	return nil
end
-- }}}
-- {{{ M.GetMenus = function()
M.GetMenus = function()
	order_fn = function(t, a, b)
		return t[b].priority > t[a].priority
	end
	return utils.spairs(commands, order_fn)

end
-- }}}
-- {{{ M.GetSubMenus = function()
M.GetSubMenus = function()
	return submenus
end
-- }}}

-- {{{ M.OpenMenu = function()
M.OpenMenu = function()
	local menu_popup = utils_popup_menu.init()
	utils_menu.init(commands, config.help_text, menu_popup)
end
-- }}}
-- {{{ M.OpenSubMenu = function(id)
M.OpenSubMenu = function(id)
	local submenu_win = utils_submenu.init()
	if #submenus[id].items > 0 then
		if submenus[id].items[#submenus[id].items].display ~= "--" then
			M.AddSubMenuItem(id, " ", "--", "")
		end
	end
	utils_submenu.open(-1, -1, submenus[id], submenu_win)
end
-- }}}

-- {{{ M.setup = function(opts)
M.setup = function(opts)
	config.setup(opts, config_defaults)
	for hl_name, hl_val in pairs(config.highlights) do
		vim.api.nvim_set_hl(0, hl_name, hl_val)
	end
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
