--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local config = require("roarie-menu.config")
local utils = require("roarie-utils")
local utils_buffer = require("roarie-utils.buffer")
local utils_windows = require("roarie-windows.utils")

local M = {}

-- {{{ local function activate_item(M, submenu, submenu_win)
local function activate_item(M, submenu, submenu_win)
	return function()
		local str = vim.api.nvim_buf_get_lines(submenu_win.prompt_bid, 0, 1, false)[1]
		M.close(submenu_win, true)
		vim.fn.feedkeys(str .. "\n")
	end
end
-- }}}
-- {{{ local function close_submenu(M, submenu, submenu_win)
local function close_submenu(M, submenu, submenu_win)
	return function()
		M.close(submenu_win, true)
	end
end
-- }}}
-- {{{ local function complete(M, submenu, submenu_win)
local function complete(M, submenu, submenu_win)
	return function()
		vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-X><C-V>", true, true, true))
	end
end
-- }}}
-- {{{ local function select_item_key(key_char)
local function select_item_key(key_char)
	return function(M, submenu, submenu_win)
		return function()
			M.select_item_key(key_char, submenu, submenu_win)
		end
	end
end
-- }}}
-- {{{ local function select_item_wrap(fn, ...)
local function select_item_wrap(fn, ...)
	local args = {...}
	return function(M_, submenu, submenu_win)
		return function()
			local fn_args = utils.copy_table(args)
			table.insert(fn_args, submenu)
			table.insert(fn_args, submenu_win)
			M[fn](unpack(fn_args))
		end
	end
end
-- }}}
-- {{{ local maps_default = {}
local maps_default = {
	["<Down>"] = select_item_wrap("select_item_next"),
	["<Up>"] = select_item_wrap("select_item_prev"),
	["<PageDown>"] = select_item_wrap("select_item_after", "--", -1),
	["<PageUp>"] = select_item_wrap("select_item_after", "--", 1),
	["<Esc>"] = close_submenu,
	["<C-c>"] = close_submenu,
	["<CR>"] = activate_item,
	["<Tab>"] = complete,

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
-- {{{ local function map_items(keys, cmdlist, submenu, textlist)
local function map_items(keys, cmdlist, submenu, textlist)
	local w, y = 1, 1
	for item_idx, item in ipairs(submenu.items) do
		y = y + 1
		if item.display ~= "--" then
			local display = item.display
			if item.fn_display ~= nil then
				display = item.fn_display()
				if utils.ulen(display) > utils.ulen(item.display) then
					display = display:sub(1, utils.ulen(item.display))
					display = display:sub(1, #display - 2) .. ".."
				end
			end
			if item.fn_rhs ~= nil then
				item.rhs = item.fn_rhs()
			end
			display, key_char = utils_windows.highlight_accel(cmdlist, display, y, 2)
			add_key(keys, key_char, item_idx)

			submenu.items[item_idx].menu_text = display
			table.insert(textlist, " " .. item.icon .. " " .. display .. " ")
			w = math.max(w, utils.ulen(textlist[#textlist]))
		else
			table.insert(textlist, "--")
		end
	end
	return w + 2, y + 2
end
-- }}}
-- {{{ local function select_item(idx_new, submenu, submenu_win)
local function select_item(idx_new, submenu, submenu_win)
	submenu.idx = idx_new

	local cmdlist = {"syn clear"}
	for _, cmd in ipairs(submenu_win.cmdlist) do
		table.insert(cmdlist, cmd)
	end

	table.insert(cmdlist,
		utils_windows.highlight_region(
			"QuickSel", submenu.idx + 1, 2,
			submenu.idx + 1, submenu.w, true))
	utils.win_execute(submenu_win.winid, cmdlist, false)
	utils_windows.highlight_border(
		"QuickBorder", submenu.items, submenu.w,
		submenu_win.h, submenu_win.winid)

	vim.api.nvim_buf_set_lines(
		submenu_win.prompt_bid, 0, 1, false,
		{submenu.items[submenu.idx].rhs})

	vim.fn.feedkeys(
		vim.api.nvim_replace_termcodes(
		"<End>", true, true, true))
end
-- }}}

-- {{{ local function setup_maps(M, submenu, submenu_win)
local function setup_maps(M, submenu, submenu_win)
	for lhs, rhs in pairs(maps_default) do
		if rhs == "forward_to_parent" then
			vim.keymap.set(
				{"n", "i"}, lhs,
				forward_to_parent(M, submenu, submenu_win, lhs),
				{buffer=submenu_win.prompt_bid, noremap=true})
		else
			vim.keymap.set(
				{"n", "i"}, lhs, rhs(M, submenu, submenu_win),
				{buffer=submenu_win.prompt_bid, noremap=true})
		end
	end
end
-- }}}
-- {{{ local function setup_prompt_window(submenu_win, w, h)
local function setup_prompt_window(submenu_win, w, h)
	local opts_prompt = {
		col=1, row=h-2,
		focusable=1,
		noautocmd=1,
		relative="win",
		style="minimal",
		width=w-2, height=1,
		win=submenu_win.winid,
		zindex=100,
	}

	submenu_win.prompt_bid = utils_buffer.create_scratch("prompt", {})
	submenu_win.prompt_winid = vim.api.nvim_open_win(submenu_win.prompt_bid, 0, opts_prompt)

	vim.api.nvim_set_current_win(submenu_win.prompt_winid)
	vim.api.nvim_set_current_buf(submenu_win.prompt_bid)
	vim.fn.feedkeys(vim.api.nvim_replace_termcodes("i<End>", true, true, true))

	vim.api.nvim_win_set_option(
		submenu_win.prompt_winid, "winhl",
		"Normal:Normal,CursorColumn:Normal,CursorLine:Normal")
	vim.api.nvim_win_set_option(
		submenu_win.prompt_winid, "cursorline",
		false)
end
-- }}}
-- {{{ local function setup_window(col, row, submenu, submenu_win, textlist, w, h)
local function setup_window(col, row, submenu, submenu_win, textlist, w, h)
	local opts = {
		col=col,
		row=row,
		focusable=1,
		noautocmd=1,
		relative="editor",
		style="minimal",
		width=w,
		height=h,
		zindex=50,
	}

	submenu_win.win_prev = vim.api.nvim_get_current_win()
	submenu_win.bid = utils_buffer.create_scratch("submenu", textlist)
	submenu_win.winid = vim.api.nvim_open_win(submenu_win.bid, 0, opts)

	vim.api.nvim_win_set_option(
		submenu_win.winid, "winhl",
		"Normal:QuickBG,CursorColumn:QuickBG,CursorLine:QuickBorder")

	local cmdlist = {"hi Cursor blend=0", "set guicursor-=a:Cursor/lCursor"}
	utils.win_execute(submenu_win.winid, cmdlist, false)

	vim.api.nvim_win_set_option(
		submenu_win.winid, "cursorline",
		false)

	utils_windows.highlight_border(
		"QuickBorder", submenu.items, submenu_win.w,
		#submenu.items + 2, submenu_win.winid)
end
-- }}}


-- {{{ M.close = function(submenu_win, redraw)
M.close = function(submenu_win, redraw)
	local should_redraw = false

	if submenu_win.winid ~= nil then
		vim.api.nvim_win_close(submenu_win.winid, 0)
		utils_buffer.free(submenu_win.bid, "submenu")
		submenu_win.winid = nil
		submenu_win.bid = nil
		should_redraw = true
	end

	if submenu_win.prompt_winid ~= nil then
		vim.cmd [[stopinsert]]
		vim.api.nvim_win_close(submenu_win.prompt_winid, 0)
		utils_buffer.free(submenu_win.prompt_bid, "prompt")
		submenu_win.prompt_winid = nil
		submenu_win.prompt_bid = nil
		should_redraw = true
	end

	if redraw and should_redraw then
		vim.cmd [[redraw]]
	end

	if submenu_win.win_prev ~= nil then
		vim.api.nvim_set_current_win(submenu_win.win_prev)
		submenu_win.win_prev = nil
	end

	if vim.o.guicursor ~= submenu_win.guicursor_old then
		vim.o.guicursor = submenu_win.guicursor_old
		vim.api.nvim_set_hl(0, "Cursor", submenu_win.hl_cursor_old)
	end

	submenu_win.open = false
	return submenu_win
end
-- }}}
-- {{{ M.open = function(col, row, submenu)
M.open = function(col, row, submenu)
	local submenu_win = {
		bid=nil,
		cmdlist={},
		guicursor_old=vim.o.guicursor,
		hl_cursor_old=vim.api.nvim_get_hl(0, {name="Cursor"}),
		idx=nil,
		idx_max=nil,
		keys={},
		open=nil,
		winid=nil,
		w=nil,
		h=nil,
	}

	local cmdlist, textlist = {"syn clear"}, {}
	local keys = {}
	local w, h = 4, 2

	w, h = map_items(keys, cmdlist, submenu, textlist)
	textlist = utils_buffer.frame(textlist, w, h - 2, config.border_chars)
	if col == -1 then col = (vim.o.columns - w) / 2 end
	if row == -1 then row = (vim.o.lines - h) / 2 end
	if submenu.keys == nil then submenu.keys = keys end
	M.close(submenu_win, true)

	submenu_win.cmdlist = cmdlist
	submenu.idx, submenu.idx_max = 0, #submenu.items
	submenu_win.keys = keys
	submenu_win.open = true
	submenu_win.w, submenu_win.h = w, h

	setup_window(col, row, submenu, submenu_win, textlist, w, h)
	setup_prompt_window(submenu_win, w, h)
	M.select_item_idx(1, submenu, submenu_win)
	setup_maps(M, submenu, submenu_win)

	return submenu, submenu_win
end
-- }}}

-- {{{ M.select_item_after = function(after, step, submenu, submenu_winid)
M.select_item_after = function(after, step, submenu, submenu_winid)
	local idx_new = submenu.idx

	if step < 0 then
		while idx_new < submenu.idx_max do
			if submenu.items[idx_new].display == after then
				idx_new = idx_new + 1
				break
			else
				idx_new = idx_new + 1
			end
		end
		if idx_new == submenu.idx_max then
			idx_new = 1
		end
	elseif step > 0 then
		while idx_new > 1 do
			if submenu.items[idx_new].display == after then
				idx_new = idx_new - 1
				break
			else
				idx_new = idx_new - 1
			end
		end
		if idx_new == 1 then
			idx_new = submenu.idx_max
		end
	end

	if submenu.items[idx_new].display == "--" then
		submenu.idx = idx_new
		M.select_item_after(after, step, submenu, submenu_winid)
		return
	end

	select_item(idx_new, submenu, submenu_winid)
end
-- }}}
-- {{{ M.select_item_idx = function(idx_new, submenu, submenu_winid)
M.select_item_idx = function(idx_new, submenu, submenu_winid)
	select_item(idx_new, submenu, submenu_winid)
end
-- }}}
-- {{{ M.select_item_key = function(ch, submenu, submenu_winid)
M.select_item_key = function(ch, submenu, submenu_winid)
	local idx_new, key = submenu.idx, submenu.keys[ch]
	if key ~= nil then
		if type(key) == "table" then
			idx_new = utils.array_next(key, submenu.idx)
		else
			idx_new = submenu.keys[ch]
		end
	end
	select_item(idx_new, submenu, submenu_winid)

end
-- }}}
-- {{{ M.select_item_next = function(submenu, submenu_winid)
M.select_item_next = function(submenu, submenu_winid)
	local idx_new = submenu.idx

	if submenu.idx == submenu.idx_max then
		idx_new = 1
	else
		while idx_new < submenu.idx_max do
			idx_new = idx_new + 1
			if submenu.items[idx_new].display ~= "--" then
				break
			end
		end
	end

	if submenu.items[idx_new].display == "--" then
		submenu.idx = idx_new
		M.select_item_next(submenu, submenu_winid)
		return
	end

	select_item(idx_new, submenu, submenu_winid)
end
-- }}}
-- {{{ M.select_item_prev = function(submenu, submenu_winid)
M.select_item_prev = function(submenu, submenu_winid)
	local idx_new = submenu.idx

	if submenu.idx == 1 then
		idx_new = submenu.idx_max
	else
		while idx_new > 1 do
			idx_new = idx_new - 1
			if submenu.items[idx_new].display ~= "--" then
				break
			end
		end
	end

	if submenu.items[idx_new].display == "--" then
		submenu.idx = idx_new
		M.select_item_prev(submenu, submenu_winid)
		return
	end

	select_item(idx_new, submenu, submenu_winid)
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
