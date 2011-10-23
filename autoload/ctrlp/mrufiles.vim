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

func! ctrlp#mrufiles#list(bufnr,...) "{{{
	if s:locked | retu | endif
	" get the list
	let cadir  = ctrlp#utils#cachedir().ctrlp#utils#lash().'mru'
	let cafile = cadir.ctrlp#utils#lash().'cache.txt'
	let mrufs  = ctrlp#utils#readfile(cafile)
	" remove non-existent files
	if exists('a:1')
		let mrufs = s:clearnonexists(mrufs, cadir, cafile)
	endif
	" return the list
	if a:bufnr == -1 | retu mrufs | endif
	" filter it
	let filename = fnamemodify(bufname(a:bufnr + 0), ':p')
	if empty(filename) || !empty(&bt)
				\ || ( !empty(s:include) && filename !~# s:include )
				\ || ( !empty(s:exclude) && filename =~# s:exclude )
				\ || ( index(mrufs, filename) == -1 && !filereadable(filename) )
		retu
	endif
	" remove old matched entry
	cal filter(mrufs, 'v:val !=# filename')
	" insert new one
	cal insert(mrufs, filename)
	" remove oldest entry
	if len(mrufs) > s:max
		cal remove(mrufs, s:max, -1)
	endif
	cal ctrlp#utils#writecache(mrufs, cadir, cafile)
endfunc "}}}

func! s:clearnonexists(mrufs, cadir, cafile) "{{{
	let mrufs = a:mrufs
	for each in range(len(mrufs) - 1, 0, -1)
		if empty(glob(mrufs[each], 1))
			cal remove(mrufs, each)
		endif
	endfor
	cal ctrlp#utils#writecache(mrufs, a:cadir, a:cafile)
	retu mrufs
endfunc "}}}

func! ctrlp#mrufiles#init() "{{{
	let s:locked = 0
	aug CtrlPMRUF
		au!
		au BufReadPost,BufNewFile,BufWritePost * cal ctrlp#mrufiles#list(expand('<abuf>', 1))
		au QuickFixCmdPre *vimgrep* let s:locked = 1
		au QuickFixCmdPost *vimgrep* let s:locked = 0
	aug END
endfunc "}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
