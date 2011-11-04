" =============================================================================
" File:          autoload/ctrlp/utils.vim
" Description:   Utility functions
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Static variables {{{
fu! ctrlp#utils#opts()
	let s:cache_dir = exists('g:ctrlp_cache_dir') ? g:ctrlp_cache_dir : $HOME
endf
cal ctrlp#utils#opts()
"}}}
" Files and Directories {{{
fu! ctrlp#utils#cachedir()
	retu exists('*mkdir') ? s:cache_dir.ctrlp#utils#lash().'.ctrlp_cache' : s:cache_dir
endf

fu! ctrlp#utils#cachefile()
	let cache_file = substitute(getcwd(), '\([\/]\|^\a\zs:\)', '%', 'g').'.txt'
	retu ctrlp#utils#cachedir().ctrlp#utils#lash().cache_file
endf

fu! ctrlp#utils#readfile(file)
	if filereadable(a:file)
		let data = readfile(a:file)
		if empty(data) || type(data) != 3
			unl data | let data = []
		en
		retu data
	el
		retu []
	en
endf

fu! ctrlp#utils#mkdir(dir)
	if exists('*mkdir') && !isdirectory(a:dir)
		sil! cal mkdir(a:dir)
	en
endf

fu! ctrlp#utils#writecache(lines,...)
	let cache_dir = exists('a:1') ? a:1 : ctrlp#utils#cachedir()
	cal ctrlp#utils#mkdir(cache_dir)
	" write cache
	if isdirectory(cache_dir)
		sil! cal writefile(a:lines, exists('a:2') ? a:2 : ctrlp#utils#cachefile())
		if !exists('a:1') || !exists('a:2')
			let g:ctrlp_newcache = 0
		en
	en
endf

fu! ctrlp#utils#lash()
	retu &ssl || !exists('+ssl') ? '/' : '\'
endf
"}}}

" vim:fen:fdl=0:fdc=1:ts=2:sw=2:sts=2
