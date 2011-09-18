" =============================================================================
" File:          autoload/ctrlp/utils.vim
" Description:   Utility functions
" Author:        Kien Nguyen <github.com/kien>
" License:       MIT
" =============================================================================

if v:version < '700' "{{{
	fini
endif "}}}

" Option variables {{{
func! ctrlp#utils#opts()
	if !exists('g:ctrlp_cache_dir')
		let s:cache_dir = $HOME
	else
		let s:cache_dir = g:ctrlp_cache_dir
	endif
endfunc
cal ctrlp#utils#opts()
"}}}

" Files and Directories functions {{{
func! ctrlp#utils#cachedir()
	retu exists('*mkdir') ? s:cache_dir.ctrlp#utils#lash().'.ctrlp_cache' : s:cache_dir
endfunc

func! ctrlp#utils#cachefile()
	retu ctrlp#utils#cachedir().ctrlp#utils#lash().substitute(getcwd(), '\([\/]\|^\a\zs:\)', '%', 'g').'.txt'
endfunc

func! ctrlp#utils#readfile(file)
	if filereadable(a:file)
		let data = readfile(a:file)
		if empty(data) || type(data) != 3
			unl data | let data = []
		endif
		retu data
	else
		retu []
	endif
endfunc

func! ctrlp#utils#mkdir(dir)
	if exists('*mkdir') && !isdirectory(a:dir)
		sil! cal mkdir(a:dir)
	endif
endfunc

func! ctrlp#utils#writecache(lines,...)
	let cache_dir  = ctrlp#utils#cachedir()
	let cache_file = exists('a:2') ? a:2 : ctrlp#utils#cachefile()
	cal ctrlp#utils#mkdir(cache_dir)
	if exists('a:1')
		let cache_dir = a:1
		cal ctrlp#utils#mkdir(cache_dir)
	endif
	" write cache
	if isdirectory(cache_dir)
		sil! cal writefile(a:lines, cache_file)
		if !exists('a:1') || !exists('a:2')
			let g:ctrlp_newcache = 0
		endif
	endif
endfunc
"}}}

" Generic functions {{{
func! ctrlp#utils#lash()
	retu &ssl || !exists('+ssl') ? '/' : '\'
endfunc
"}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
