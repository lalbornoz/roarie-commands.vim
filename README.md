# roarie-commands

This plugin implements a unified interface for adding self-documenting
mappings/commands and a menu UI akin to Turbo Pascal, etc. as well as
an optional [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
command palette picker. Both Neovim as well as Vim, with [vim-quickui](https://github.com/skywind3000/vim-quickui)
as dependency, are supported.

# Demo

![Menu UI](https://github.com/lalbornoz/roarie-commands.vim/blob/master/Screenshot1.png?raw=true)
![Telescope command palette picker](https://github.com/lalbornoz/roarie-commands.vim/blob/master/Screenshot2.png?raw=true)

# Installation

When using Vim, no further specific setup is required. When using Neovim:

```lua
--
-- If telescope.nvim is present, ensure this executes after
-- telescope.nvim has been loaded and setup successfully.
-- The following reflects the builtin default configuration.
--
require("roarie-commands").setup({
	help_screen = {
		"<{Esc,C-C}>                                  Exit menu mode",
		"<{S-[a-z0-9],Down,Space}>, <{Left,Right}>    Open/select menu",
		"[a-z0-9], <{Page,}Down,Up,Home,End>          Select menu items",
		"<{Space,Enter}>                              Activate menu item",
	},
	help_text = "Press ? for help",

	highlights = {
		QuickBG = {ctermfg=251, ctermbg=236, fg="#c6c6c6", bg="#303030"},
		QuickBorder = {ctermfg=251, ctermbg=236, fg="#0679a5", bg="#303030"},
		QuickSel = {ctermfg=236, ctermbg=251, fg="#303030", bg="#f5a9b8"},
		QuickSelMap = {ctermfg=236, ctermbg=251, underline=true, fg="#0679a5", bg="#f5a9b8"},
		QuickKey = {ctermfg=179, underline=true, fg="#87d7d7"},
	},

	mod_order = {
		'',
		'S-',
		'C-',
		'C-S-',
		'M-',
		'M-S-',
		'M-C-',
		'M-C-S-',
	},
})
```

# Usage

```vim
"
" Adds a menu titled "File" with accelerator "F" and priority 200,
" a pseudo-mapping (purely descriptive, no mapping is executed,)
" a regular mapping, and a regular mapping with a function keys
" menu item; see below wrt. this and why priority starts at 200
" as opposed to 100.
"
call roarie_commands#AddMenu("&File", 200)
call roarie_commands#AddIMapping("&File", "complete", "Complete in insert mode...", "Complete in insert mode...", '', '<S-Tab>', '', "<pseudo>")
call roarie_commands#AddSeparator("&File")
call roarie_commands#AddMapping("&File", "buffer_next", "Next &buffer", "Go to next buffer in buffer list", "<silent>", '<S-Tab>', ':<C-U>bn<CR>')
call roarie_commands#AddSeparator("&File")
call roarie_commands#AddMapping("&File", "read_program", "&Read from program...", "Read from program prompt into new scratch window", '', '<M-F9>', ':<C-U>CReadNewScratch ', "<fnalias>")

"
" If desired, menus encompassing all mappings that are mapped by
" a function key with optional modifiers (e.g. <F2>, <S-F9>) can
" be automatically added. In this case, two menus, "<F1-7>" and
" <F8-12>" with accelerators "1" and "8" and priorities 100 and 150,
" resp., are added, encompassing all mappings mapped by <F1-7> and
" <F8-12>, resp., and a separator menu item between every 3rd menu
" item.
"
call roarie_commands#SetupFnMenus(
	\ ["<F&1-7>", "<F&8-12>"],
	\ [100, 150],
	\ [7, 12], [2, 2])

" Call this near or at the end of your ~/.vimrc. 
call roarie_commands#Install()

" Map this in order to activate the menu bar.
call roarie_commands#OpenMenu()
```

Please refer to `autoload/roarie_commands.vim` for the full API.

[modeline]: # ( vim: set tw=0: )
