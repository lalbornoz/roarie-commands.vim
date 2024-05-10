--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local config = require("roarie-menu.config")
local utils_buffer = require("roarie-utils.buffer")
local utils_windows = require("roarie-windows.utils")

local M = {}

local help_window = {
	bid=nil,
	open=false,
	winid=nil,
}

-- {{{ local maps_default = {}
local maps_default = {
}
-- }}}

-- {{{ local function setup_maps(help_window, parent)
local function setup_maps(help_window, parent)
	for lhs, rhs in pairs(maps_default) do
		vim.keymap.set(
			{"n", "i"}, lhs, rhs(parent),
			{buffer=help_window.bid, noremap=true})
	end
end
-- }}}
-- {{{ local function setup_window(help_screen, help_window, is_current)
local function setup_window(help_screen, help_window, is_current)
	local opts = {
		col=1, row=vim.o.lines,
		focusable=1,
		noautocmd=1,
		relative="editor",
		style="minimal",
		width=vim.o.columns,
		height=#help_screen + 2,
	}

	help_window.bid = utils_buffer.create_scratch("help", textlist)
	local winid_old = vim.api.nvim_get_current_win()
	help_window.winid = vim.api.nvim_open_win(help_window.bid, 0, opts)
	if (not is_current) and (winid_old ~= vim.api.nvim_get_current_win()) then
		vim.api.nvim_set_current_win(winid_old)
	end

	vim.api.nvim_win_set_option(
		help_window.winid, "winhl",
		"Normal:QuickBG,CursorColumn:Normal,CursorLine:QuickBorder")
	utils_windows.highlight_border(
		"QuickBorder", {}, opts.width,
		opts.height, help_window.winid)
end
-- }}}

-- {{{ M.close = function()
M.close = function()
	if help_window.open then
		vim.api.nvim_win_close(help_window.winid, 0)
		vim.cmd [[redraw]]

		help_window = {
			bid=nil,
			open=false,
			winid=nil,
		}
	end
end
-- }}}
-- {{{ M.open = function(help_screen, parent, is_current)
M.open = function(help_screen, parent, is_current)
	if not help_window.open then
		setup_window(help_screen, help_window, is_current)
		setup_maps(help_window, parent)

		help_screen = utils_buffer.frame(
			help_screen, vim.o.columns,
			-1, config.border_chars)
		vim.api.nvim_buf_set_lines(
			help_window.bid, 0, -1,
			true, help_screen)
		help_window.open = true
	end
end
-- }}}
-- {{{ M.toggle = function(help_screen, parent)
M.toggle = function(help_screen, parent)
	if help_window.open then
		M.close()
	else
		M.open(help_screen, parent)
	end
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
