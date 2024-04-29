--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local config_defaults = {
	help_screen = {
		"<{Esc,C-C}>                        Exit menu mode",
		"<{S-[a-z],[0-9]}>                  Select and open menu with accelerator",
		"<{Left,Right}>                     Select menu; will open menu automatically if menu is not open",
		"<{Down,Space}>                     Open menu",
		"<[a-z],{Page,}{Down,Up},Home,End>  Select menu items",
		"<{Space,Enter}>                    Activate menu item",
	},
	help_text = "Press ? for help",

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

local commands = {}
local fn_tmp_menu = "<Fn>"
local menus = {}

local config = require("roarie-menu.config")
local ui = require("roarie-menu.ui")
local utils = require("roarie-utils")

local M = {}

-- {{{ function AddMapping_(noaddfl, menu, id, title, mode, descr, silent, lhs, rhs, pseudofl)
function AddMapping_(noaddfl, menu, id, title, mode, descr, silent, lhs, rhs, pseudofl)
	local map_line = {GetMappingMode(mode, lhs)}

	if noaddfl == 0 then
		if descr:len() == 0 then
			descr = title
		end

		local display = nil
		local keys = lhs
		keys = vim.fn.substitute(keys, '<Leader>', vim.g.mapleader, '')
		keys = vim.fn.substitute(keys, '<', '\\\\<', '')
		local action = ':call feedkeys("' .. keys .. '")'

		if title ~= "--" then
			display = title .. "\t" .. lhs
		else
			display = "--"
		end

		local menu_item = {
			action=action,
			descr=descr,
			display=display,
			id=id,
			lhs=lhs,
			menu=menu,
			mode=mode,
			rhs=rhs,
			silent=silent,
			title=title,
		}

		if commands[id] == nil then
			commands[id] = {}
		end

		table.insert(commands[id], menu_item)
		table.insert(menus[menu]['items'], menu_item)
	end

	if pseudofl == "<fnalias>" then
		if menus[fn_tmp_menu] == nil then
			M.AddMenu(fn_tmp_menu, 0, 1)
		end

		AddMapping_(
			noaddfl, fn_tmp_menu, id, title,
			mode, descr, silent, lhs, rhs,
			"<pseudo>")
	end

	if pseudofl ~= "<pseudo>" then
		if silent:len() > 0 then
			table.insert(map_line, '<silent>')
		end

		table.insert(map_line, lhs)
		table.insert(map_line, rhs)
		vim.fn.execute(table.concat(map_line, ' '))
	end
end
-- }}}
-- {{{ function GetMappingMode(mode, lhs)
function GetMappingMode(mode, lhs)
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

-- {{{ function PopulateFnMenu(src_items, dst_title, key_to, sep_each)
function PopulateFnMenu(src_items, dst_title, key_to, sep_each)
	local key_last = 0

	for item_idx=1,table.getn(src_items) do
		local item = src_items[item_idx]
		local key_cur = vim.fn.str2nr(vim.fn.matchstr(item["lhs"], '^<\\([MCS]-\\)*F\\zs[0-9]\\+\\ze'))

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
			elseif (key_cur ~= key_last) and (((key_cur - 1) % sep_each) == 0) then
				key_last = key_cur
				M.AddSeparator(dst_title)
			end
			table.insert(menus[dst_title]["items"], item)
		end
	end
	return src_items
end
-- }}}
-- {{{ function SortFnMenu_(lhs, rhs)
function SortFnMenu_(lhs, rhs)
	local lhs_key = vim.fn.str2nr(vim.fn.matchstr(lhs["lhs"], '^<\\([MCS]-\\)*F\\zs[0-9]\\+\\ze'))
	local rhs_key = vim.fn.str2nr(vim.fn.matchstr(rhs["lhs"], '^<\\([MCS]-\\)*F\\zs[0-9]\\+\\ze'))
	if lhs_key < rhs_key then
		return -1
	elseif lhs_key > rhs_key then
		return 1
	else
		local lhs_mod = vim.fn.matchstr(lhs["lhs"], '^<\\zs\\([MCS-]\\)*\\ze')
		local lhs_priority = vim.fn.index(config.mod_order or {}, lhs_mod)
		local rhs_mod = vim.fn.matchstr(rhs["lhs"], '^<\\zs\\([MCS-]\\)*\\ze')
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
-- {{{ function SortFnMenu()
function SortFnMenu()
	return vim.fn.sort(menus[fn_tmp_menu]["items"], SortFnMenu_)
end
-- }}}
-- {{{ function SortMenus(lhs, rhs)
function SortMenus(lhs, rhs)
	local lhs_item = menus[lhs]
	local rhs_item = menus[rhs]
	if lhs_item['priority'] < rhs_item['priority'] then
		return -1
	elseif lhs_item['priority'] > rhs_item['priority'] then
		return 1
	else
		return 0
	end
end
-- }}}

-- {{{ M.AddMapping = function(menu, id, title, descr, silent, lhs, rhs, ...)
M.AddMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
	return AddMapping_(0, menu, id, title, 'nvo', descr, silent, lhs, rhs, pseudofl)
end
-- }}}
-- {{{ M.AddIMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
M.AddIMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
	return AddMapping_(0, menu, id, title, 'insert', descr, silent, lhs, rhs, pseudofl)
end
-- }}}
-- {{{ M.AddINVOMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
M.AddINVOMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
	AddMapping_(0, menu, id, title, 'nvo', descr, silent, lhs, rhs, pseudofl)
	return AddMapping_(1, menu, id, title, 'insert', descr, silent, lhs, rhs, pseudofl)
end
-- }}}
-- {{{ M.AddNMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
M.AddNMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
	return AddMapping_(0, menu, id, title, 'normal', descr, silent, lhs, rhs, pseudofl)
end
-- }}}
-- {{{ M.AddTMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
M.AddTMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
	return AddMapping_(0, menu, id, title, 'terminal', descr, silent, lhs, rhs, pseudofl)
end
-- }}}
-- {{{ M.AddVMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
M.AddVMapping = function(menu, id, title, descr, silent, lhs, rhs, pseudofl)
	return AddMapping_(0, menu, id, title, 'visual', descr, silent, lhs, rhs, pseudofl)
end
-- }}}

-- {{{ M.AddMenu = function(title, priority, ignore_in_palette)
M.AddMenu = function(title, priority, ignore_in_palette)
	menus[title] = {}
	menus[title]['items'] = {}
	menus[title]['priority'] = priority
	menus[title]['ignore_in_palette'] = ignore_in_palette
end
-- }}}
-- {{{ M.AddSeparator = function(menu)
M.AddSeparator = function(menu)
	table.insert(menus[menu]['items'], {
		action=nil,
		descr='',
		display='--',
		lhs='',
		rhs='',
		silent='',
		title='--',
	})
end
-- }}}

-- {{{ M.GetMapping = function(menu, id)
M.GetMapping = function(menu, id)
	if commands[id] ~= nil then
		for _, cmd in ipairs(commands[id]) do
			if cmd["menu"] == menu then
				return cmd
			end
		end
	end
	return nil
end
-- }}}
-- {{{ M.GetMenu = function(menu)
M.GetMenu = function(menu)
	return menus[menu]
end
-- }}}
-- {{{ M.GetMenuTitles = function()
M.GetMenuTitles = function()
	order_fn = function(t, a, b)
		return t[b]["priority"] > t[a]["priority"]
	end
	return utils.spairs(menus, order_fn)

end
-- }}}

-- {{{ M.Install = function()
M.Install = function()
	ui.Reset()
	local menu_keys = vim.fn.sort(utils.get_keys(menus), SortMenus)
	for _, menu in ipairs(menu_keys) do
		ui.Install(menu, menus[menu].items, menus[menu]['priority'])
	end
end
-- }}}
-- {{{ M.SetupFnMenus = function(ltitle, lpriority, lkey_to, lsep_each)
M.SetupFnMenus = function(ltitle, lpriority, lkey_to, lsep_each)
	local menu_items = SortFnMenu()
	menus[fn_tmp_menu] = nil
	for idx=1,table.getn(lpriority) do
		M.AddMenu(ltitle[idx], lpriority[idx], 1)
		menu_items = PopulateFnMenu(menu_items, ltitle[idx], lkey_to[idx], lsep_each[idx])
	end
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
