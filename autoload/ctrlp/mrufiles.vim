" =============================================================================
" File:          autoload/ctrlp/mrufiles.vim
" Description:   Most Recently Used Files extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Static variables {{{1
fu! ctrlp#mrufiles#opts()
	let [pref, opts] = ['g:ctrlp_mruf_', {
		\ 'max': ['s:max', 250],
		\ 'include': ['s:in', ''],
		\ 'exclude': ['s:ex', ''],
		\ 'case_sensitive': ['s:csen', 1],
		\ 'relative': ['s:re', 0],
		\ }]
	for [ke, va] in items(opts)
		exe 'let' va[0] '=' string(exists(pref.ke) ? eval(pref.ke) : va[1])
	endfo
	let [s:csen, s:mrbs, s:mrufs] = [s:csen ? '#' : '?', [], []]
	if exists('s:locked') | cal ctrlp#mrufiles#init() | en
endf
cal ctrlp#mrufiles#opts()
" Utilities {{{1
fu! s:excl(fn)
	retu !empty(s:ex) && a:fn =~# s:ex
endf

fu! s:mergelists(...)
	let diskmrufs = ctrlp#utils#readfile(ctrlp#mrufiles#cachefile())
	let mrus = a:0 && a:1 == 'raw' ? s:mrbs : s:mrufs
	cal filter(diskmrufs, 'index(mrus, v:val) < 0')
	let mrua = mrus + diskmrufs
	retu a:0 && a:1 == 'raw' ? mrua : s:chop(mrua)
endf

fu! s:chop(mrufs)
	if len(a:mrufs) > s:max | cal remove(a:mrufs, s:max, -1) | en
	retu a:mrufs
endf

fu! s:reformat(mrufs)
	if s:re
		let cwd = exists('+ssl') ? tr(getcwd(), '/', '\') : getcwd()
		cal filter(a:mrufs, '!stridx(v:val, cwd)')
	en
	retu map(a:mrufs, 'fnamemodify(v:val, ":.")')
endf

fu! s:record(bufnr)
	if s:locked | retu | en
	let bufnr = a:bufnr + 0
	if bufnr <= 0 | retu | en
	let bufname = bufname(bufnr)
	if empty(bufname) | retu | en
	let fn = fnamemodify(bufname, ':p')
	let fn = exists('+ssl') ? tr(fn, '/', '\') : fn
	if empty(fn) || !empty(&bt) | retu | en
	cal filter(s:mrbs, 'v:val !='.s:csen.' fn')
	cal insert(s:mrbs, fn)
	if ( !empty(s:in) && fn !~# s:in ) || ( !empty(s:ex) && fn =~# s:ex )
		\ || !filereadable(fn) | retu
	en
	cal filter(s:mrufs, 'v:val !='.s:csen.' fn')
	cal insert(s:mrufs, fn)
	let s:mrufs = s:chop(s:mrufs)
endf

fu! s:savetofile(mrufs)
	cal ctrlp#utils#writecache(a:mrufs, s:cadir, s:cafile)
endf
" Public {{{1
fu! ctrlp#mrufiles#refresh(...)
	let mrufs = s:mergelists()
	cal filter(mrufs, '!empty(ctrlp#utils#glob(v:val, 1)) && !s:excl(v:val)')
	if exists('+ssl')
		cal map(mrufs, 'tr(v:val, "/", "\\")')
		cal filter(mrufs, 'count(mrufs, v:val) == 1')
	en
	cal s:savetofile(mrufs)
	retu a:0 && a:1 == 'raw' ? [] : s:reformat(mrufs)
endf

fu! ctrlp#mrufiles#remove(files)
	let mrufs = []
	if a:files != []
		let mrufs = s:mergelists()
		cal filter(mrufs, 'index(a:files, v:val) < 0')
	en
	cal s:savetofile(mrufs)
	retu s:reformat(mrufs)
endf

fu! ctrlp#mrufiles#list(...)
	retu a:0 ? a:1 == 'raw' ? s:mergelists(a:1) : 0 : s:reformat(s:mergelists())
endf

fu! ctrlp#mrufiles#bufs()
	retu s:mrbs
endf

fu! ctrlp#mrufiles#mrufs()
	retu s:mrufs
endf

fu! ctrlp#mrufiles#cachefile()
	if !exists('s:cadir') || !exists('s:cafile')
		let s:cadir = ctrlp#utils#cachedir().ctrlp#utils#lash().'mru'
		let s:cafile = s:cadir.ctrlp#utils#lash().'cache.txt'
	en
	retu s:cafile
endf

fu! ctrlp#mrufiles#init()
	if !has('autocmd') | retu | en
	let s:locked = 0
	aug CtrlPMRUF
		au!
		au BufAdd,BufEnter,BufUnload * cal s:record(expand('<abuf>', 1))
		au QuickFixCmdPre  *vimgrep* let s:locked = 1
		au QuickFixCmdPost *vimgrep* let s:locked = 0
		au VimLeavePre * cal s:savetofile(s:mergelists())
	aug END
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
