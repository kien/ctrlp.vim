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

fu! ctrlp#utils#opts()
	let s:cache_dir = $HOME.s:lash.'.ctrlp_cache'
	if exists('g:ctrlp_cache_dir')
		let s:cache_dir = expand(g:ctrlp_cache_dir, 1)
		if isdirectory(s:cache_dir.s:lash.'.ctrlp_cache')
			let s:cache_dir = s:cache_dir.s:lash.'.ctrlp_cache'
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
	retu exists('a:1') ? cache_file : s:cache_dir.s:lash.cache_file
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
	retu call('glob',  v:version > 701 ? a:000 : a:1)
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
