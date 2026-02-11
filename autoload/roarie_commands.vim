	"
" Copyright (c) 2024, 2026 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
"

if has('nvim')

" {{{ fun! roarie_commands#AddMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	call luaeval(
		\ 'require("roarie-menu").AddMapping(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7], _A[8], _A[9])',
		\ [a:menu, a:id, a:title, a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " ")])
endfun
" }}}
" {{{ fun! roarie_commands#AddIMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddIMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	call luaeval(
		\ 'require("roarie-menu").AddIMapping(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7], _A[8], _A[9])',
		\ [a:menu, a:id, a:title, a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " ")])
endfun
" }}}
" {{{ fun! roarie_commands#AddINVOMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddINVOMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	call luaeval(
		\ 'require("roarie-menu").AddINVOMapping(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7], _A[8], _A[9])',
		\ [a:menu, a:id, a:title, a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " ")])
endfun
" }}}
" {{{ fun! roarie_commands#AddNMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddNMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	call luaeval(
		\ 'require("roarie-menu").AddNMapping(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7], _A[8], _A[9])',
		\ [a:menu, a:id, a:title, a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " ")])
endfun
" }}}
" {{{ fun! roarie_commands#AddTMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddTMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	call luaeval(
		\ 'require("roarie-menu").AddTMapping(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7], _A[8], _A[9])',
		\ [a:menu, a:id, a:title, a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " ")])
endfun
" }}}
" {{{ fun! roarie_commands#AddVMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddVMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	call luaeval(
		\ 'require("roarie-menu").AddVMapping(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7], _A[8], _A[9])',
		\ [a:menu, a:id, a:title, a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " ")])
endfun
" }}}

" {{{ fun! roarie_commands#AddMenu(title, ...)
fun! roarie_commands#AddMenu(title, ...)
	let l:priority = get(a:, 1, str2nr(substitute(expand('<sfile>:t'), '\..*$', '', '')))
	call luaeval(
		\ 'require("roarie-menu").AddMenu(_A[1], _A[2], (_A[3] == 1))',
		\ [a:title, l:priority, get(a:, 2, 0)])
endfun
" }}}
" {{{ fun! roarie_commands#AddSeparator(menu)
fun! roarie_commands#AddSeparator(menu)
	call luaeval(
		\ 'require("roarie-menu").AddSeparator(_A[1])',
		\ [a:menu])
endfun
" }}}
" {{{ fun! roarie_commands#AddSubMenu(id, title, ...)
fun! roarie_commands#AddSubMenu(id, title, ...)
	call luaeval(
		\ 'require("roarie-menu").AddSubMenu(_A[1], _A[2], (_A[3] == 1))',
		\ [a:id, a:title, get(a:, 3, 0)])
endfun
" }}}
" {{{ fun! roarie_commands#AddSubMenuItem(id_submenu, id, icon, title, rhs, ...)
fun! roarie_commands#AddSubMenuItem(id_submenu, id, icon, title, rhs, ...)
	call luaeval(
		\ 'require("roarie-menu").AddSubMenuItem(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7])',
		\ [a:id_submenu, a:id, a:icon, a:title, a:rhs, get(a:, 1, ""), get(a:, 2, "")])
endfun
" }}}

" {{{ fun! roarie_commands#GetMapping(menu, id)
fun! roarie_commands#GetMapping(menu, id)
	call luaeval(
		\ 'require("roarie-menu").GetMapping(_A[1], _A[2])',
		\ [a:menu, a:id])
endfun
" }}}

" {{{ fun! roarie_commands#Install()
fun! roarie_commands#Install()
endfun
" }}}
"" {{{ fun! roarie_commands#SetupFnMenus(ltitle, lpriority, lkey_to, lsep_each)
fun! roarie_commands#SetupFnMenus(ltitle, lpriority, lkey_to, lsep_each)
	call luaeval(
		\ 'require("roarie-menu").SetupFnMenus(_A[1], _A[2], _A[3], _A[4])',
		\ [a:ltitle, a:lpriority, a:lkey_to, a:lsep_each])
endfun
" }}}

" {{{ fun! roarie_commands#OpenMenu()
fun! roarie_commands#OpenMenu()
	lua require("roarie-menu").OpenMenu()
endfun
" }}}
" {{{ fun! roarie_commands#OpenSubMenu(id)
fun! roarie_commands#OpenSubMenu(id)
	call luaeval(
		\ 'require("roarie-menu").OpenSubMenu(_A[1])',
		\ [a:id])
endfun
" }}}

else

let g:roarie_commands = {}
let g:roarie_menus = {}
let g:roarie_mod_order = [
	\ '',
	\ 'S-',
	\ 'C-',
	\ 'C-S-',
	\ 'M-',
	\ 'M-S-',
	\ 'M-C-',
	\ 'M-C-S-',
	\ ]

let s:fn_tmp_menu = "<Fn>"

" {{{ fun! s:AddMapping_(noaddfl, menu, id, title, mode, descr, silent, lhs, rhs, pseudofl, icon)
fun! s:AddMapping_(noaddfl, menu, id, title, mode, descr, silent, lhs, rhs, pseudofl, icon)
	let l:map_line = [s:GetMappingMode(a:mode, a:lhs)]
	let lhs_map = s:FixMapping(a:lhs)

	if a:noaddfl == 0
		let l:descr = (len(a:descr) == 0) ? a:title : a:descr
		let l:menu_item = {
			\ 'descr': l:descr,
			\ 'icon': a:icon,
			\ 'id': a:id,
			\ 'lhs': a:lhs,
			\ 'menu': a:menu,
			\ 'mode': a:mode,
			\ 'rhs': a:rhs,
			\ 'silent': a:silent,
			\ 'title': a:title,
			\ }

		if !has_key(g:roarie_commands, a:id)
			let g:roarie_commands[a:id] = []
		endif

		let g:roarie_commands[a:id] += [menu_item]
		let g:roarie_menus[a:menu]['items'] += [menu_item]
	endif

	if a:pseudofl is "<fnalias>"
		if !has_key(g:roarie_menus, s:fn_tmp_menu)
			call roarie_commands#AddMenu(s:fn_tmp_menu, 0, 1)
		endif

		call s:AddMapping_(
			\ a:noaddfl, s:fn_tmp_menu, a:id, a:title,
			\ a:mode, a:descr, a:silent, a:lhs, a:rhs,
			\ "<pseudo>", a:icon)
	endif

	if !(a:pseudofl is "<pseudo>")
		if len(a:silent) > 0
			let l:map_line += ['<silent>']
		endif

		let l:map_line += [lhs_map, a:rhs]
		execute join(l:map_line, ' ')
	endif
endfun
" }}}
" {{{ fun! s:FixMappingLhs(lhs)
fun! s:FixMapping(lhs)
	let lhs = a:lhs
	if !has('nvim')
		let lhs = substitute(lhs, '^<M-\([a-z0-9]\)>$', '<Esc>\1', 'g')
	endif
	return lhs
endfun
" }}}
" {{{ fun! s:GetMappingMode(mode, lhs)
fun! s:GetMappingMode(mode, lhs)
	if a:mode == "insert"
		return "inoremap"
	elseif a:mode == "normal"
		return "nnoremap"
	elseif a:mode == "nvo"
		return "noremap"
	elseif a:mode == "terminal"
		return "tnoremap"
	elseif a:mode == "visual"
		return "vnoremap"
	else
		echoerr "Invalid mode " . a:mode . " for mapping: " . lhs
	endif
endfun
" }}}

" {{{ fun! s:PopulateFnMenu(src_items, dst_title, key_to, sep_each)
fun! s:PopulateFnMenu(src_items, dst_title, key_to, sep_each)
	let item_idx = 0
	let key_last = 0

	for item_idx in range(len(a:src_items))
		let item = a:src_items[item_idx]
		let key_cur = str2nr(matchstr(item["lhs"], '^<\([MCS]-\)*F\zs[0-9]\+\ze'))

		if key_cur > a:key_to
			break
		else
			if key_last == 0
				let key_last = key_cur
			elseif (key_cur != key_last) && (((key_cur - 1) % a:sep_each) == 0)
				let key_last = key_cur
				call roarie_commands#AddSeparator(a:dst_title)
			endif
			let g:roarie_menus[a:dst_title]["items"] += [item]
		endif
	endfor

	if item_idx > 0
		unlet a:src_items[:item_idx]
	endif
	return a:src_items
endfun
" }}}
" {{{ fun! s:SortFnMenu_(lhs, rhs)
fun! s:SortFnMenu_(lhs, rhs)
	let lhs_key = str2nr(matchstr(a:lhs["lhs"], '^<\([MCS]-\)*F\zs[0-9]\+\ze'))
	let rhs_key = str2nr(matchstr(a:rhs["lhs"], '^<\([MCS]-\)*F\zs[0-9]\+\ze'))
	if lhs_key < rhs_key
		return -1
	elseif lhs_key > rhs_key
		return 1
	else
		let lhs_mod = matchstr(a:lhs["lhs"], '^<\zs\([MCS-]\)*\ze')
		let lhs_priority = index(g:roarie_mod_order, lhs_mod)
		let rhs_mod = matchstr(a:rhs["lhs"], '^<\zs\([MCS-]\)*\ze')
		let rhs_priority = index(g:roarie_mod_order, rhs_mod)
		if lhs_priority < rhs_priority
			return -1
		elseif lhs_priority > rhs_priority
			return 1
		else
			return 0
		endif
	endif
endfun
" }}}
" {{{ fun! s:SortFnMenu()
fun! s:SortFnMenu()
	return sort(g:roarie_menus[s:fn_tmp_menu]["items"], function("s:SortFnMenu_"))
endfun
" }}}
" {{{ fun! s:SortMenus(lhs, rhs)
fun! s:SortMenus(lhs, rhs)
	let lhs_item = g:roarie_menus[a:lhs]
	let rhs_item = g:roarie_menus[a:rhs]
	if lhs_item['priority'] < rhs_item['priority']
		return -1
	elseif lhs_item['priority'] > rhs_item['priority']
		return 1
	else
		return 0
	endif
endfun
" }}}

" {{{ fun! roarie_commands#AddMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	return s:AddMapping_(0, a:menu, a:id, a:title, 'nvo', a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " "))
endfun
" }}}
" {{{ fun! roarie_commands#AddIMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddIMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	return s:AddMapping_(0, a:menu, a:id, a:title, 'insert', a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " "))
endfun
" }}}
" {{{ fun! roarie_commands#AddINVOMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddINVOMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	call s:AddMapping_(0, a:menu, a:id, a:title, 'nvo', a:descr, a:silent, a:lhs, a:rhs)
	return s:AddMapping_(1, a:menu, a:id, a:title, 'insert', a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " "))
endfun
" }}}
" {{{ fun! roarie_commands#AddNMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddNMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	return s:AddMapping_(0, a:menu, a:id, a:title, 'normal', a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " "))
endfun
" }}}
" {{{ fun! roarie_commands#AddTMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddTMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	return s:AddMapping_(0, a:menu, a:id, a:title, 'terminal', a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " "))
endfun
" }}}
" {{{ fun! roarie_commands#AddVMapping(menu, id, title, descr, silent, lhs, rhs, ...)
fun! roarie_commands#AddVMapping(menu, id, title, descr, silent, lhs, rhs, ...)
	return s:AddMapping_(0, a:menu, a:id, a:title, 'visual', a:descr, a:silent, a:lhs, a:rhs, get(a:, 1, ""), get(a:, 2, " "))
endfun
" }}}

" {{{ fun! roarie_commands#AddMenu(title, ...)
fun! roarie_commands#AddMenu(title, ...)
	let l:priority = get(a:, 1, str2nr(substitute(expand('<sfile>:t'), '\..*$', '', '')))
	let g:roarie_menus[a:title] = {}
	let g:roarie_menus[a:title]['items'] = []
	let g:roarie_menus[a:title]['priority'] = l:priority
	let ignore_in_palette = get(a:, 2, 0)
	if ignore_in_palette == 1
		let g:roarie_menus[a:title]['ignore_in_palette'] = 1
	else
		let g:roarie_menus[a:title]['ignore_in_palette'] = 0
	endif
endfun
" }}}
" {{{ fun! roarie_commands#AddSeparator(menu)
fun! roarie_commands#AddSeparator(menu)
	let g:roarie_menus[a:menu]['items'] += [{
		\ 'descr': '',
		\ 'lhs': '',
		\ 'rhs': '',
		\ 'silent': '',
		\ 'title': '--',
		\ }]
endfun
" }}}
" {{{ fun! roarie_commands#AddSubMenu(id, title, ...)
fun! roarie_commands#AddSubMenu(id, title, ...)
endfun
" }}}
" {{{ fun! roarie_commands#AddSubMenuItem(id_submenu, id, icon, title, rhs, ...)
fun! roarie_commands#AddSubMenuItem(id_submenu, id, icon, title, rhs, ...)
endfun
" }}}

" {{{ fun! roarie_commands#GetMapping(menu, id)
fun! roarie_commands#GetMapping(menu, id)
	if has_key(g:roarie_commands, a:id)
		for cmd in g:roarie_commands[a:id]
			if cmd["menu"] is a:menu
				return cmd
			endif
		endfor
	endif
	return nil
endfun
" }}}

" {{{ fun! roarie_commands#Install()
fun! roarie_commands#Install()
	call quickui#menu#reset()
	let menu_keys = sort(keys(g:roarie_menus), function("s:SortMenus"))
	for l:menu in menu_keys
		let l:menu_items = []
		for l:menu_item in g:roarie_menus[l:menu]['items']
			let l:keys = l:menu_item['lhs']
			let l:keys = substitute(l:keys, '<Leader>', g:mapleader, '')
			let l:keys = substitute(l:keys, '<', '\\<', '')
			let l:title = l:menu_item['title']
			if l:title != "--"
				if (l:menu_item['icon'] != " ")
					let l:title = l:menu_item['icon'] ." ". l:title
				else
					let l:title = " " ." ". l:title
				endif
				let l:title .= "\t". l:menu_item['lhs']
			endif
			let l:menu_items += [[l:title, ':call feedkeys("'. l:keys .'")', '']]
		endfor
		call quickui#menu#install(l:menu, l:menu_items, g:roarie_menus[l:menu]['priority'])
	endfor
endfun
" }}}
"" {{{ fun! roarie_commands#SetupFnMenus(ltitle, lpriority, lkey_to, lsep_each)
fun! roarie_commands#SetupFnMenus(ltitle, lpriority, lkey_to, lsep_each)
	let menu_items = s:SortFnMenu()
	unlet g:roarie_menus[s:fn_tmp_menu]
	for idx in range(len(a:lpriority))
		call roarie_commands#AddMenu(a:ltitle[idx], a:lpriority[idx], 1)
		let menu_items = s:PopulateFnMenu(menu_items, a:ltitle[idx], a:lkey_to[idx], a:lsep_each[idx])
	endfor
endfun
" }}}

" {{{ fun! roarie_commands#OpenMenu()
fun! roarie_commands#OpenMenu()
	call quickui#menu#open()
endfun
" }}}
" {{{ fun! roarie_commands#OpenSubMenu(id)
fun! roarie_commands#OpenSubMenu(id)
endfun
" }}}

endif

" vim:filetype=vim noexpandtab sw=8 ts=8 tw=0
