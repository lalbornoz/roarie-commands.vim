--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local border_chars_default = {'╭', '─', '╮', '│', '─', '│', '╰', '─', '╯', '├', '┤'}

local utils = require("roarie-utils")

local M = {}

-- {{{ M.create_scratch = function(name, textlist)
M.create_scratch = function(name, textlist)
	local bid = vim.api.nvim_create_buf(false, true)
	vim.fn.setbufvar(bid, "&bufhidden",	"hide")
	vim.fn.setbufvar(bid, "current_syntax",	"")
	vim.fn.setbufvar(bid, "&buftype",	"nofile")
	vim.fn.setbufvar(bid, "&filetype",	"")
	vim.fn.setbufvar(bid, "&modifiable",	0)
	vim.fn.setbufvar(bid, "&modified",	0)
	vim.fn.setbufvar(bid, "noswapfile",	1)
	M.update(bid, textlist)
	return bid
end
-- }}}
-- {{{ M.frame = function(str, w, h, chars)
M.frame = function(str, w, h, chars)
	local str_ = {}

	if w == -1 then
		w = 0
		for _, line in ipairs(str) do
			w = math.max(w, utils.ulen(line))
		end
		w = w + 2
	end
	if h == -1 then
		h = #str
	end

	if chars == nil then
		chars = border_chars_default
	end

	str_[1] = chars[1] .. string.rep(chars[2], w - 2) .. chars[3]
	for y=1,h do
		local line = str[y]
		local is_sep = false
		if line == nil then
			line = ""
		elseif string.sub(line, 1, (w - 2)) == "--" then
			is_sep = true
			line = string.rep(chars[5], (w - 2))
		end
		if (not is_sep) and (utils.ulen(line) < (w - 2)) then
			line = line .. string.rep(" ", (w - utils.ulen(line) - 2))
		elseif (not is_sep) and (utils.ulen(line) > (w - 2)) then
			line = string.sub(line, 1, (w - 2))
		end
		if not is_sep then
			table.insert(str_, chars[4] .. line .. chars[6])
		else
			table.insert(str_, chars[10] .. line .. chars[11])
		end
	end
	table.insert(str_, chars[7] .. string.rep(chars[8], w - 2) .. chars[9])

	return str_
end
-- }}}
-- {{{ M.free = function()
M.free = function(bid, name)
	vim.api.nvim_buf_delete(bid, {force=true})
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

	vim.fn.setbufvar(bid, "&modifiable", 1)
	vim.fn.execute("silent call deletebufline(" .. bid .. ", 1, '$')")
	vim.fn.setbufline(bid, 1, textlist)
	vim.fn.setbufvar(bid, "&modifiable", 0)
	vim.fn.setbufvar(bid, "&modified", 0)
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
