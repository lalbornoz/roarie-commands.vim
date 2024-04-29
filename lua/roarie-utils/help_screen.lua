--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Partially based on vim-quickui code.
--

local help_window = {bid=nil, open=false, winid=nil}

local utils_buffer = require("roarie-utils.buffer")

local M = {}

-- {{{ M.close = function()
M.close = function()
	if help_window.open then
		vim.api.nvim_win_close(help_window.winid, 0)
		vim.cmd [[redraw]]
		help_window = {bid=nil, open=false, winid=nil}
	end
end
-- }}}
-- {{{ M.open = function(help_screen)
M.open = function(help_screen)
	if not help_window.open then
		local opts = {
			col=1, row=vim.o.lines,
			focusable=1,
			noautocmd=1,
			relative='editor',
			style='minimal',
			width=vim.o.columns, height=table.getn(help_screen),
		}

		help_window.bid = utils_buffer.create_scratch("help", textlist)
		help_window.winid = vim.api.nvim_open_win(help_window.bid, 0, opts)
		help_window.open = true
		vim.api.nvim_buf_set_lines(help_window.bid, 0, -1, true, help_screen)
		vim.cmd [[redraw]]
	end
end
-- }}}
-- {{{ M.toggle = function(help_screen)
M.toggle = function(help_screen)
	if help_window.open then
		M.close()
	else
		M.open(help_screen)
	end
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
