" =============================================================================
" File:          autoload/ctrlp/mrufiles.vim
" Description:   Most Recently Used Files extension
" Author:        Kien Nguyen <github.com/kien>
" License:       MIT
" =============================================================================

if v:version < '700' "{{{
	fini
endif "}}}

" Option variables {{{
func! ctrlp#mrufiles#opts()
	if !exists('g:ctrlp_mruf_max')
		let s:max = 150
	else
		let s:max = g:ctrlp_mruf_max
		unl g:ctrlp_mruf_max
	endif

	if !exists('g:ctrlp_mruf_include')
		let s:include = ''
	else
		let s:include = g:ctrlp_mruf_include
		unl g:ctrlp_mruf_include
	endif

	if !exists('g:ctrlp_mruf_exclude')
		let s:exclude = ''
	else
		let s:exclude = g:ctrlp_mruf_exclude
		unl g:ctrlp_mruf_exclude
	endif
endfunc
cal ctrlp#mrufiles#opts()
"}}}

func! ctrlp#mrufiles#list(bufnr) "{{{
	if s:locked | retu | endif
	" get the list
	let cache_dir  = ctrlp#utils#cachedir().ctrlp#utils#lash().'mru'
	let cache_file = cache_dir.ctrlp#utils#lash().'cache.txt'
	let mrufiles   = ctrlp#utils#readfile(cache_file)
	" return the list
	if a:bufnr == -1 | retu mrufiles | endif
	" filter it
	let filename = fnamemodify(bufname(a:bufnr + 0), ':p')
	if empty(filename) || !empty(&bt)
				\ || ( !empty(s:include) && filename !~# s:include )
				\ || ( !empty(s:exclude) && filename =~# s:exclude )
				\ || ( index(mrufiles, filename) == -1 && !filereadable(filename) )
		retu
	endif
	" remove old matched entry
	cal filter(mrufiles, 'v:val !=# filename')
	" insert new one
	cal insert(mrufiles, filename)
	" remove oldest entry
	if len(mrufiles) > s:max
		cal remove(mrufiles, s:max, -1)
	endif
	cal ctrlp#utils#writecache(mrufiles, cache_dir, cache_file)
endfunc "}}}

func! ctrlp#mrufiles#init() "{{{
	let s:locked = 0
	aug CtrlPMRUF
		au!
		au BufReadPost,BufNewFile,BufWritePost * cal ctrlp#mrufiles#list(expand('<abuf>'))
		au QuickFixCmdPre *vimgrep* let s:locked = 1
		au QuickFixCmdPost *vimgrep* let s:locked = 0
	aug END
endfunc "}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
