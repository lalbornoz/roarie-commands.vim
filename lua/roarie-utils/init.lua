--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Partially based on vim-quickui code.
--

local utf8 = require("utf8")

local M = {}

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
-- {{{ M.get_keys = function(t)
M.get_keys = function(t)
	local keys = {}
	for key, _ in pairs(t) do
		table.insert(keys, key)
	end
	return keys
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
-- {{{ M.copy_table = function(src)
M.copy_table = function(src)
	local dst = {}
	for k, v in pairs(src) do
		dst[k] = v
	end
	return dst
end
-- }}}

-- {{{ M.to_title(str)
M.to_title = function(str)
  return (str:gsub("^%l", string.upper))
end
-- }}}
-- {{{ M.ulen = function(str)
M.ulen = function(str)
	if str == "" then
		return 0
	else
		return utf8.len(str)
	end
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
