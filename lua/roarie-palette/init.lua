--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local palette = {}
palette.config = {}

local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error 'This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)'
end

local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"
local roarie_menu = require("roarie-menu")
local utils = require("roarie-utils")

-- {{{ local function get_menu_keys()
local function get_menu_keys()
  local menu_keys = {}
  local n = 0

  for menu, _ in roarie_menu.GetMenuTitles() do
    local menu_ = roarie_menu.GetMenu(menu)
    if menu_["ignore_in_palette"] == 0 then
      for _, item in pairs(menu_["items"]) do
        if not (item["title"] == "--") then
          n = n + 1
          menu_keys[n] = {
            descr = item["descr"],
            display = menu:gsub("&", "") .. ": " .. item["icon"] .. " " .. item["title"]:gsub("&", ""),
            icon = item["icon"],
            id = item["id"],
            lhs = item["lhs"],
            menu = menu:gsub("&", ""),
            mode = item["mode"],
            ordinal = item["icon"] .. item["lhs"] .. item["title"]:gsub("&", "") .. " " .. item["id"],
            rhs = item["rhs"],
            value = nil,
          }
        end
      end
    end
  end
  return menu_keys
end
-- }}}

palette.palette = function(opts)
  menu_keys = get_menu_keys()
  opts = opts or {}

  pickers.new(opts, {
    -- {{{ attach_mappings = ...
    attach_mappings = function(_, map)
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes(selection.lhs, true, true, true))
      end)
      return true
    end,
    -- }}}
    -- {{{ finder = ...
    finder = finders.new_table {
      entry_maker = function(entry)
        return entry
      end,
      results = menu_keys
    },
    -- }}}
    -- {{{ previewer = ...
    previewer = previewers.new_buffer_previewer {
      define_preview = function(self, entry)
        local lines = {}
        if not (entry.lhs == nil) then
          lines = {
            "Menu:",
            entry.menu,
            "",
            "Id:",
            entry.id,
            "",
            "Description:",
            entry.descr,
            "",
            "Mapping:",
            entry.lhs,
            "",
            "Right-hand side:",
            entry.rhs,
            "",
            "Mode:",
            utils.to_title((entry.mode == "nvo") and ("Normal, Visual, Operator-pending") or entry.mode),
            "",
            "Icon:",
            entry.icon,
          }
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.schedule(function()
          vim.api.nvim_buf_call(self.state.bufnr, function()
            vim.fn.matchadd("RoariePaletteHeading", '^\\zs.*\\ze:$')
            vim.fn.matchadd("RoariePaletteMapping", '\\zs<.*>\\ze')
          end)
        end)
      end,
    },
    -- }}}
    -- {{{ sorter = ...
    sorter = conf.generic_sorter(opts),
    -- }}}

    results_title = "Command palette",
  }):find()
end

vim.cmd [[ high! RoariePaletteHeading gui=underline guifg=#7acaca ]]
vim.cmd [[ high! RoariePaletteMapping gui=bold ]]

return palette

-- vim:expandtab sw=2 ts=2
