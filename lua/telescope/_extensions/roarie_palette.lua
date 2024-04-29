--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
--

local palette = require('roarie-palette')

return require('telescope').register_extension {
  exports = {
    roarie_palette = palette.palette
  },

  setup = function(ext_config, _config)
    for k, v in pairs(ext_config) do
      palette.config[k] = v
    end
  end,
}

-- vim:expandtab sw=2 ts=2
