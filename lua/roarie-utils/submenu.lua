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
-- {{{ local function get_dimensions(submenu, w, h)
local function get_dimensions(submenu, w, h)
	for _, item in ipairs(submenu.items) do
		if item["display"] ~= "--" then
			w = math.max(w, 2 + 1 + utils.ulen(item["display"]) + 2)
		end
		h = h + 1
	end
	return w, h
end
-- }}}
-- {{{ local function items_to_textlist(keys, cmdlist, submenu, textlist, w)
local function items_to_textlist(keys, cmdlist, submenu, textlist, w)
	local y = 1
	for item_idx, item in ipairs(submenu.items) do
		y = y + 1
		if item["display"] ~= "--" then
			local display = item["display"]
			display, key_char = utils_menu.highlight_accel(cmdlist, display, y, 2)
			add_key(keys, key_char, item_idx)

			submenu.items[item_idx].menu_text = display
			table.insert(textlist, " " .. item["icon"] .. " " .. display .. " ")
		else
			table.insert(textlist, "--")
		end
	end
end
-- }}}
-- {{{ local function select_item(idx_new, submenu, submenu_win)
local function select_item(idx_new, submenu, submenu_win)
	if idx_new ~= submenu.idx then
		submenu.idx = idx_new

		local cmdlist = {"syn clear"}
		for _, cmd in ipairs(submenu_win.cmdlist) do
			table.insert(cmdlist, cmd)
		end
		table.insert(cmdlist, utils.highlight_region(
			'QuickSel',
			submenu.idx + 1, 2,
			submenu.idx + 1, submenu.w,
			true))
		utils.win_execute(submenu_win.winid, cmdlist, false)
		utils.highlight_border(
			"QuickBorder", submenu.items, submenu.w,
			submenu_win.h, submenu_win.winid)
		vim.api.nvim_buf_set_lines(
			submenu_win.prompt_bid, 0, 1, false,
			{submenu.items[submenu.idx].rhs})
		vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<End>", true, true, true))
	end
end
-- }}}

-- {{{ M.close = function(popup, redraw)
M.close = function(popup, redraw)
	local should_redraw = false
	if popup.winid ~= nil then
		vim.api.nvim_win_close(popup.winid, 0)
		utils_buffer.free(popup.bid)
		popup.winid = nil
		popup.bid = nil
		should_redraw = true
	end
	if popup.prompt_winid ~= nil then
		vim.cmd [[stopinsert]]
		vim.api.nvim_win_close(popup.prompt_winid, 0)
		utils_buffer.free(popup.prompt_bid)
		popup.prompt_winid = nil
		popup.prompt_bid = nil
		should_redraw = true
	end
	if redraw and should_redraw then
		vim.cmd [[redraw]]
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
-- {{{ M.open = function(col, row, submenu, submenu_win)
M.open = function(col, row, submenu, submenu_win)
	local cmdlist, textlist = {"syn clear"}, {}
	local keys = {}
	local w, h = 4, 2

	w, h = get_dimensions(submenu, w, h)
	h = h + 1
	items_to_textlist(keys, cmdlist, submenu, textlist, w)
	if submenu.keys == nil then
		submenu.keys = keys
	end
	textlist = utils_buffer.frame(textlist, w, h, nil)
	submenu_win = M.close(submenu_win, true)

	if col == -1 then
		col = (vim.o.columns - w) / 2
	end
	if row == -1 then
		row = (vim.o.lines - h) / 2
	end

	local opts = {
		col=col, row=row,
		focusable=1,
		noautocmd=1,
		relative='editor',
		style='minimal',
		width=w, height=h,
		zindex=50,
	}

	submenu_win.cmdlist = cmdlist
	submenu_win.idx, submenu_win.idx_max = 0, h - 2
	submenu_win.keys = keys
	submenu_win.open = true
	submenu_win.w, submenu_win.h = w, h

	submenu_win.bid = utils_buffer.create_scratch("context", textlist)
	submenu_win.winid = vim.api.nvim_open_win(submenu_win.bid, 0, opts)

	local opts_prompt = {
		col=1, row=h-2,
		focusable=1,
		noautocmd=1,
		relative='win',
		style='minimal',
		width=w-2, height=1,
		win=submenu_win.winid,
		zindex=100,
	}

	submenu_win.prompt_bid = utils_buffer.create_scratch("prompt", {})
	submenu_win.prompt_winid = vim.api.nvim_open_win(submenu_win.prompt_bid, 0, opts_prompt)

	vim.api.nvim_set_current_win(submenu_win.prompt_winid)
	vim.api.nvim_set_current_buf(submenu_win.prompt_bid)
	vim.fn.feedkeys(vim.api.nvim_replace_termcodes("i<End>", true, true, true))
	for key=tonumber(string.byte("a")),tonumber(string.byte("z")) do
		local key_char = string.char(key)
		vim.keymap.set({"n", "i"}, "<M-" .. key_char .. ">", function() M.select_item_key(key_char, submenu, submenu_win) end, {buffer=submenu_win.prompt_bid, remap=false})
	end
	--utils_submenu.select_item_key(code, submenu, submenu_win)
	vim.keymap.set({"n", "i"}, "<Down>", function() M.select_item_step(1, submenu, submenu_win) end, {buffer=submenu_win.prompt_bid, remap=false})
	vim.keymap.set({"n", "i"}, "<Up>", function() M.select_item_step(-1, submenu, submenu_win) end, {buffer=submenu_win.prompt_bid, remap=false})
	vim.keymap.set({"n", "i"}, "<PageDown>", function() M.select_item_after("--", -1, submenu, submenu_win) end, {buffer=submenu_win.prompt_bid, remap=false})
	vim.keymap.set({"n", "i"}, "<PageUp>", function() M.select_item_after("--", 1, submenu, submenu_win) end, {buffer=submenu_win.prompt_bid, remap=false})
	vim.keymap.set({"n", "i"}, "<Esc>", function() M.close(submenu_win, true) end, {buffer=submenu_win.prompt_bid, remap=false})
	vim.keymap.set({"n", "i"}, "<C-c>", function() M.close(submenu_win, true) end, {buffer=submenu_win.prompt_bid, remap=false})
	vim.keymap.set({"n", "i"}, "<CR>", function() local str = vim.api.nvim_buf_get_lines(submenu_win.prompt_bid, 0, 1, false)[1]; M.close(submenu_win, true); vim.fn.feedkeys(str .. "\n"); end, {buffer=submenu_win.prompt_bid, remap=false})
	utils.win_execute(submenu_win.winid, cmdlist, false)
	vim.api.nvim_win_set_option(submenu_win.winid, 'winhl', 'Normal:QuickBG,CursorColumn:QuickBG,CursorLine:QuickBorder')
	vim.api.nvim_win_set_option(submenu_win.winid, 'cursorline', false)
	vim.api.nvim_win_set_option(submenu_win.prompt_winid, 'winhl', 'Normal:Normal,CursorColumn:Normal,CursorLine:Normal')
	vim.api.nvim_win_set_option(submenu_win.prompt_winid, 'cursorline', false)
	M.select_item_idx(1, submenu, submenu_win)
	utils.highlight_border(
		"QuickBorder", submenu.items, submenu_win.w,
		#submenu.items + 2, submenu_win.winid)
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

-- {{{ M.update = function(submenu)
M.update = function(submenu)
	local guicursor_old = vim.o.guicursor
	local hl_cursor_old = vim.api.nvim_get_hl(0, {name="Cursor"})
	local cmdlist = {
		"hi Cursor blend=100",
		"set guicursor+=a:Cursor/lCursor",
		"set nocursorline",
		"syn clear"}

	for _, item in ipairs(submenu.items) do
		if item.key_pos >= 0 then
			local x = item.key_pos + 1
			table.insert(cmdlist, utils.highlight_region('QuickKey', 1, x, 1, x + 1, true))
		end
	end

	if (submenu.idx >= 1) and (submenu.idx <= #submenu.items) then
		local x0 = 1
		local x1 = x0 + submenu.items[submenu.idx].w
		table.insert(cmdlist, utils.highlight_region('QuickSel', 1, x0, 1, x1, true))
	end

	utils.win_execute(submenu.winid, cmdlist, false)
	return guicursor_old, hl_cursor_old
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
