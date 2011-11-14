" =============================================================================
" File:          autoload/ctrlp/utils.vim
" Description:   Utilities
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Static variables {{{
fu! ctrlp#utils#lash()
	retu &ssl || !exists('+ssl') ? '/' : '\'
endf
let s:lash = ctrlp#utils#lash()

fu! ctrlp#utils#opts()
	let cache_dir = exists('g:ctrlp_cache_dir') ?
		\ isdirectory(g:ctrlp_cache_dir.s:lash.'.ctrlp_cache')
		\ ? g:ctrlp_cache_dir.s:lash.'.ctrlp_cache'
		\ : g:ctrlp_cache_dir : $HOME.s:lash.'.ctrlp_cache'
	let s:cache_dir = expand(cache_dir, 1)
endf
cal ctrlp#utils#opts()
"}}}
" Files and Directories {{{
fu! ctrlp#utils#cachedir()
	retu s:cache_dir
endf

fu! ctrlp#utils#cachefile()
	let cache_file = substitute(getcwd(), '\([\/]\|^\a\zs:\)', '%', 'g').'.txt'
	retu s:cache_dir.s:lash.cache_file
endf

fu! ctrlp#utils#readfile(file)
	if filereadable(a:file)
		let data = readfile(a:file)
		if empty(data) || type(data) != 3 | unl data | let data = [] | en
		retu data
	en
	retu []
endf

fu! ctrlp#utils#mkdir(dir)
	if exists('*mkdir') && !isdirectory(a:dir) | sil! cal mkdir(a:dir) | en
endf

fu! ctrlp#utils#writecache(lines, ...)
	let cache_dir = exists('a:1') ? a:1 : s:cache_dir
	cal ctrlp#utils#mkdir(cache_dir)
	if isdirectory(cache_dir)
		sil! cal writefile(a:lines, exists('a:2') ? a:2 : ctrlp#utils#cachefile())
		if !exists('a:1') || !exists('a:2') | let g:ctrlp_newcache = 0 | en
	en
endf

fu! ctrlp#utils#glob(...)
	retu call('glob',  v:version > 701 ? [a:1, a:2] : [a:1])
endf
"}}}

" vim:fen:fdl=0:fdc=1:ts=2:sw=2:sts=2
