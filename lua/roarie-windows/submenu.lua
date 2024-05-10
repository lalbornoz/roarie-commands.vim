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
	["<Down>"] = select_item_wrap("select_item_step", 1),
	["<Up>"] = select_item_wrap("select_item_step", -1),
	["<PageDown>"] = select_item_wrap("select_item_after", "--", -1),
	["<PageUp>"] = select_item_wrap("select_item_after", "--", 1),
	["<Esc>"] = close_submenu,
	["<C-c>"] = close_submenu,
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
-- {{{ local function get_dimensions(submenu, w, h)
local function get_dimensions(submenu, w, h)
	for _, item in ipairs(submenu.items) do
		if item.display ~= "--" then
			w = math.max(w, utils.ulen("│ 󰘳" .. item.display .. " │"))
		end
		h = h + 1
	end
	return w, h + 1
end
-- }}}
-- {{{ local function map_items(keys, cmdlist, submenu, textlist, w)
local function map_items(keys, cmdlist, submenu, textlist, w)
	local y = 1
	for item_idx, item in ipairs(submenu.items) do
		y = y + 1
		if item.display ~= "--" then
			local display = item.display
			display, key_char = utils_windows.highlight_accel(cmdlist, display, y, 2)
			add_key(keys, key_char, item_idx)

			submenu.items[item_idx].menu_text = display
			table.insert(textlist, " " .. item.icon .. " " .. display .. " ")
		else
			table.insert(textlist, "--")
		end
	end
end
-- }}}
-- {{{ local function select_item(idx_new, submenu, submenu_win)
local function select_item(idx_new, submenu, submenu_win)
	if idx_new == submenu.idx then
		return
	end

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
		col=col, row=row,
		focusable=1,
		noautocmd=1,
		relative="editor",
		style="minimal",
		width=w,
		height=h,
		zindex=50,
	}

	submenu_win.bid = utils_buffer.create_scratch("submenu", textlist)
	submenu_win.winid = vim.api.nvim_open_win(submenu_win.bid, 0, opts)
	utils.win_execute(submenu_win.winid, cmdlist, false)

	vim.api.nvim_win_set_option(
		submenu_win.winid, "winhl",
		"Normal:QuickBG,CursorColumn:QuickBG,CursorLine:QuickBorder")
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

	submenu_win.open = false
	return submenu_win
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
		w=nil,
		h=nil,
	}
end
-- }}}
-- {{{ M.open = function(col, row, submenu, submenu_win)
M.open = function(col, row, submenu, submenu_win)
	local cmdlist, textlist = {"syn clear"}, {}
	local keys = {}
	local w, h = 4, 2

	w, h = get_dimensions(submenu, w, h)
	if col == -1 then col = (vim.o.columns - w) / 2 end
	if row == -1 then row = (vim.o.lines - h) / 2 end

	map_items(keys, cmdlist, submenu, textlist, w)
	if submenu.keys == nil then
		submenu.keys = keys
	end
	textlist = utils_buffer.frame(textlist, w, h - 2, config.border_chars)

	M.close(submenu_win, true)

	submenu_win.cmdlist = cmdlist
	submenu.idx, submenu.idx_max = 0, #submenu.items
	submenu_win.keys = keys
	submenu_win.open = true
	submenu_win.w, submenu_win.h = w, h

	setup_window(col, row, submenu, submenu_win, textlist, w, h)
	setup_prompt_window(submenu_win, w, h)
	M.select_item_idx(1, submenu, submenu_win)
	M.update(submenu)

	setup_maps(M, submenu, submenu_win)
end
-- }}}
-- {{{ M.update = function(submenu)
M.update = function(submenu)
	local cmdlist = {
		"set nocursorline",
		"syn clear"}

	for _, item in ipairs(submenu.items) do
		if item.key_pos >= 0 then
			local x = item.key_pos + 1
			table.insert(
				cmdlist, utils_windows.highlight_region(
				"QuickKey", 1, x, 1, x + 1, true))
		end
	end

	if (submenu.idx >= 1) and (submenu.idx <= #submenu.items) then
		local x0 = 1
		local x1 = x0 + submenu.items[submenu.idx].w
		table.insert(
			cmdlist, utils_windows.highlight_region(
			"QuickSel", 1, x0, 1, x1, true))
	end

	utils.win_execute(submenu.winid, cmdlist, false)
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
-- {{{ M.select_item_step = function(step, submenu, submenu_winid)
M.select_item_step = function(step, submenu, submenu_winid)
	local idx_new = submenu.idx
	if step < 0 then
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
	elseif step > 0 then
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
	end
	select_item(idx_new, submenu, submenu_winid)
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
