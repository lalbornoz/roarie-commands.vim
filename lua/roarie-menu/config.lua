--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local utils = require("roarie-utils")

local M = {}

-- {{{ M.setup = function(opts, config_defaults)
M.setup = function(opts, config_defaults)
	utils.copy_config(M, config_defaults, opts)
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
