--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Partially based on vim-quickui code.
--

local border_chars_default = {'┌', '─', '┐', '│', '─', '│', '└', '─', '┘', '├', '┤'}

local buffer_array = {}
local buffer_cache = {}

local M = {}

-- {{{ M.alloc = function()
M.alloc = function()
	local bid, idx = nil, table.getn(buffer_array)
	if idx > 0 then
		bid = buffer_array[idx]
		table.remove(buffer_array, idx)
	else
		bid = vim.api.nvim_create_buf(false, true)
		vim.fn.setbufvar(bid, '&bufhidden',	'hide')
		vim.fn.setbufvar(bid, '&buftype',	'nofile')
		vim.fn.setbufvar(bid, 'noswapfile',	1)
	end
	vim.fn.setbufvar(bid, '&filetype',	'')
	vim.fn.execute("silent call deletebufline(" .. bid .. ", 1, '$')")
	vim.fn.setbufvar(bid, '&modifiable',	1)
	vim.fn.setbufvar(bid, '&modified',	0)
	return bid
end
-- }}}
-- {{{ M.create_scratch = function(name, textlist)
M.create_scratch = function(name, textlist)
	local bid = -1
	if (name ~= "") and (buffer_cache[name] ~= nil) then
		bid = buffer_cache[name]
	end
	if bid == -1 then
		bid = M.alloc()
		if name ~= "" then
			buffer_cache[name] = bid
		end
	end
	M.update(bid, textlist)
	vim.fn.setbufvar(bid, 'current_syntax', '')
	return bid
end
-- }}}
-- {{{ M.frame = function(str, w, h, chars)
M.frame = function(str, w, h, chars)
	local str_ = {}
	if chars == nil then
		chars = border_chars_default
	end

	str_[1] = chars[1] .. string.rep(chars[2], w - 2) .. chars[3]
	for y=2,(h - 1) do
		local line = str[y - 1]
		local is_sep = false
		if line == nil then
			line = ""
		elseif string.sub(line, 1, (w - 2)) == "--" then
			is_sep = true
			line = string.rep(chars[5], (w - 2))
		end
		if (not is_sep) and (line:len() < (w - 2)) then
			line = line .. string.rep(" ", (w - line:len() - 2))
		elseif (not is_sep) and (line:len() > (w - 2)) then
			line = string.sub(line, 1, (w - 2))
		end
		if not is_sep then
			str_[y] = chars[4] .. line .. chars[6]
		else
			str_[y] = chars[10] .. line .. chars[11]
		end
	end
	str_[h] = chars[7] .. string.rep(chars[8], w - 2) .. chars[9]

	return str_
end
-- }}}
-- {{{ M.free = function()
M.free = function(bid)
	local idx = table.getn(buffer_array) + 1
	buffer_array[idx] = bid
	vim.fn.setbufvar(bid, '&modifiable',	1)
	vim.fn.execute("silent call deletebufline(" .. bid .. ", 1, '$')")
	vim.fn.setbufvar(bid, '&modified',	0)
end
-- }}}
-- {{{ M.update = function(bid, textlist)
M.update = function(bid, textlist)
	if type(textlist) == "string" then
		local textlist_ = {}
		for line in string.gmatch(textlist, "[^\n]+") do
			table.insert(textlist_, line)
		end
		textlist = textlist_
	end
	vim.fn.setbufvar(bid, '&modifiable', 1)
	vim.fn.execute("silent call deletebufline(" .. bid .. ", 1, '$')")
	vim.fn.setbufline(bid, 1, textlist)
	vim.fn.setbufvar(bid, '&modified', 0)
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
