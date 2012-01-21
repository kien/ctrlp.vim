" =============================================================================
" File:          autoload/ctrlp/utils.vim
" Description:   Utilities
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Static variables {{{1
fu! ctrlp#utils#lash()
	retu &ssl || !exists('+ssl') ? '/' : '\'
endf
let s:lash = ctrlp#utils#lash()

fu! s:lash(...)
	retu match(a:0 ? a:1 : getcwd(), '[\/]$') < 0 ? s:lash : ''
endf

fu! ctrlp#utils#opts()
	let cache_home = exists('$XDG_CACHE_HOME') ? $XDG_CACHE_HOME : $HOME.'/.cache'
	let s:cache_dir = cache_home.'/ctrlp'
	" Support old default, for compatibility
	if !isdirectory(s:cache_dir) && isdirectory($HOME.s:lash($HOME).'.ctrlp_cache')
		let s:cache_dir = $HOME.s:lash($HOME).'.ctrlp_cache'
	en
	" User option
	if exists('g:ctrlp_cache_dir')
		let s:cache_dir = expand(g:ctrlp_cache_dir, 1)
		" Support old suffix
		if isdirectory(s:cache_dir.s:lash(s:cache_dir).'.ctrlp_cache')
			let s:cache_dir = s:cache_dir.s:lash(s:cache_dir).'.ctrlp_cache'
		en
	en
endf
cal ctrlp#utils#opts()
" Files and Directories {{{1
fu! ctrlp#utils#cachedir()
	retu s:cache_dir
endf

fu! ctrlp#utils#cachefile(...)
	let tail = exists('a:1') ? '.'.a:1 : ''
	let cache_file = substitute(getcwd(), '\([\/]\|^\a\zs:\)', '%', 'g').tail.'.txt'
	retu exists('a:1') ? cache_file : s:cache_dir.s:lash(s:cache_dir).cache_file
endf

fu! ctrlp#utils#readfile(file)
	if filereadable(a:file)
		let data = readfile(a:file)
		if empty(data) || type(data) != 3
			unl data
			let data = []
		en
		retu data
	en
	retu []
endf

fu! ctrlp#utils#mkdir(dir)
	if exists('*mkdir') && !isdirectory(a:dir)
		sil! cal mkdir(a:dir)
	en
endf

fu! ctrlp#utils#writecache(lines, ...)
	let cache_dir = exists('a:1') ? a:1 : s:cache_dir
	cal ctrlp#utils#mkdir(cache_dir)
	if isdirectory(cache_dir)
		sil! cal writefile(a:lines, exists('a:2') ? a:2 : ctrlp#utils#cachefile())
		if !exists('a:1')
			let g:ctrlp_newcache = 0
		en
	en
endf

fu! ctrlp#utils#glob(...)
	let cond = v:version > 702 || ( v:version == 702 && has('patch051') )
	retu call('glob', cond ? a:000 : [a:1])
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
