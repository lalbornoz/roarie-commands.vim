--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Partially based on vim-quickui code.
--

local M = {}

M.termcodes = {
	ETX=0x03,
	ESC=0x1b,
	Enter=0x0d,
	Space=0x20,
	Left=vim.api.nvim_replace_termcodes('<Left>', true, false, true),
	Right=vim.api.nvim_replace_termcodes('<Right>', true, false, true),
	Down=vim.api.nvim_replace_termcodes('<Down>', true, false, true),
	Up=vim.api.nvim_replace_termcodes('<Up>', true, false, true),
	PageDown=vim.api.nvim_replace_termcodes('<PageDown>', true, false, true),
	PageUp=vim.api.nvim_replace_termcodes('<PageUp>', true, false, true),
	Home=vim.api.nvim_replace_termcodes('<Home>', true, false, true),
	End=vim.api.nvim_replace_termcodes('<End>', true, false, true),
}

-- {{{ M.copy_config = function(config, config_defaults, config_new)
M.copy_config = function(config, config_defaults, config_new)
	for k, v in pairs(config_defaults) do
		if config_new[k] ~= nil then
			v = config_new[k]
		end
		config[k] = v
	end
end
-- }}}
-- {{{ M.get_keys = function(t)
M.get_keys = function(t)
	local keys = {}
	for key, _ in pairs(t) do
		table.insert(keys, key)
	end
	return keys
end
-- }}}
-- {{{ M.getchar = function()
M.getchar = function()
	local rc, code = pcall(vim.fn.getchar)
	if not rc then
		if code == "Keyboard interrupt" then code = M.termcodes.ETX else error(rc) end
	end
	return code, vim.fn.nr2char(code)
end
-- }}}
-- {{{ M.serialise_table = function(val, name, skipnewlines, depth)
-- <https://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions>
M.serialise_table = function(val, name, skipnewlines, depth)
	skipnewlines = skipnewlines or false
	depth = depth or 0

	local tmp = string.rep(" ", depth)

	if name then tmp = tmp .. name .. " = " end

	if type(val) == "table" then
		tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

		for k, v in pairs(val) do
			tmp =  tmp .. M.serialise_table(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
		end

		tmp = tmp .. string.rep(" ", depth) .. "}"
	elseif type(val) == "number" then
		tmp = tmp .. tostring(val)
	elseif type(val) == "string" then
		tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp .. (val and "true" or "false")
	else
		tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
	end

	return tmp
end
-- }}}
-- {{{ M.spairs = function(t, order)
-- <https://stackoverflow.com/questions/15706270/sort-a-table-in-lua>
M.spairs = function(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
	table.sort(keys, function(a,b) return order(t, a, b) end)
  else
	table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
	i = i + 1
	if keys[i] then
	  return keys[i], t[keys[i]]
	end
  end
end
-- }}}
-- {{{ M.split = function(str, pattern)
M.split = function(str, pattern)
	local list = {}
	for str_ in string.gmatch(str, pattern) do
		table.insert(list, str_)
	end
	return list
end
-- }}}
-- {{{ M.array_next = function(array, idx_cur)
M.array_next = function(array, value)
	local array_len = table.getn(array)
	for idx, value_cur in ipairs(array) do
		if value_cur == value then
			if (idx + 1) <= array_len then
				return array[(idx + 1)]
			else
				return array[1]
			end
		end
	end
	return array[1]
end
-- }}}
-- {{{ M.to_title(str)
M.to_title = function(str)
  return (str:gsub("^%l", string.upper))
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

-- {{{ M.win_execute = function(winid, command, silent)
M.win_execute = function(winid, command, silent)
	if type(command) == "string" then
		vim.fn.win_execute(winid, command, silent)
	elseif type(command) == "table" then
		vim.fn.win_execute(winid, table.concat(command, "\n"), silent)
	end
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
