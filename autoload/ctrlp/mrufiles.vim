" =============================================================================
" File:          autoload/ctrlp/mrufiles.vim
" Description:   Most Recently Used Files extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Static variables {{{1
fu! ctrlp#mrufiles#opts()
	let opts = {
		\ 'g:ctrlp_mruf_max': ['s:max', 250],
		\ 'g:ctrlp_mruf_include': ['s:in', ''],
		\ 'g:ctrlp_mruf_exclude': ['s:ex', ''],
		\ 'g:ctrlp_mruf_case_sensitive': ['s:csen', 1],
		\ 'g:ctrlp_mruf_relative': ['s:re', 0],
		\ 'g:ctrlp_mruf_last_entered': ['s:mre', 0],
		\ }
	for [ke, va] in items(opts)
		exe 'let' va[0] '=' string(exists(ke) ? eval(ke) : va[1])
	endfo
	let [s:csen, s:mrbs] = [s:csen ? '#' : '?', []]
	if exists('s:locked')
		cal ctrlp#mrufiles#init()
	en
endf
cal ctrlp#mrufiles#opts()
" Utilities {{{1
fu! s:excl(fn)
	retu !empty(s:ex) && a:fn =~# s:ex
endf

fu! s:readcache()
	if !exists('s:cadir') || !exists('s:cafile')
		let s:cadir = ctrlp#utils#cachedir().ctrlp#utils#lash().'mru'
		let s:cafile = s:cadir.ctrlp#utils#lash().'cache.txt'
	en
	retu ctrlp#utils#readfile(s:cafile)
endf

fu! s:reformat(mrufs)
	if s:re
		let cwd = exists('+ssl') ? tr(getcwd(), '/', '\') : getcwd()
		cal filter(a:mrufs, '!stridx(v:val, cwd)')
	en
	retu map(a:mrufs, 'fnamemodify(v:val, '':.'')')
endf

fu! s:record(bufnr, ...)
	if s:locked | retu | en
	let bufnr = a:bufnr + 0
	if bufnr <= 0 | retu | en
	let fn = fnamemodify(bufname(bufnr), ':p')
	let fn = exists('+ssl') ? tr(fn, '/', '\') : fn
	cal filter(s:mrbs, 'v:val !='.s:csen.' fn')
	cal insert(s:mrbs, fn)
	if empty(fn) || !empty(&bt) || ( !empty(s:in) && fn !~# s:in )
		\ || ( !empty(s:ex) && fn =~# s:ex ) || !filereadable(fn)
		\ || ( a:0 && a:1 == 1 )
		retu
	en
	let mrufs = s:readcache()
	cal filter(mrufs, 'v:val !='.s:csen.' fn')
	cal insert(mrufs, fn)
	if len(mrufs) > s:max | cal remove(mrufs, s:max, -1) | en
	cal ctrlp#utils#writecache(mrufs, s:cadir, s:cafile)
endf
" Public {{{1
fu! ctrlp#mrufiles#refresh()
	let mrufs = s:readcache()
	cal filter(mrufs, '!empty(ctrlp#utils#glob(v:val, 1)) && !s:excl(v:val)')
	if exists('+ssl')
		cal map(mrufs, 'tr(v:val, ''/'', ''\'')')
		cal filter(mrufs, 'count(mrufs, v:val) == 1')
	en
	cal ctrlp#utils#writecache(mrufs, s:cadir, s:cafile)
	retu s:reformat(mrufs)
endf

fu! ctrlp#mrufiles#remove(files)
	let mrufs = []
	if a:files != []
		let mrufs = s:readcache()
		cal filter(mrufs, 'index(a:files, v:val) < 0')
	en
	cal ctrlp#utils#writecache(mrufs, s:cadir, s:cafile)
	retu map(mrufs, 'fnamemodify(v:val, '':.'')')
endf

fu! ctrlp#mrufiles#list(...)
	if a:0 | cal s:record(a:1) | retu | en
	retu s:reformat(s:readcache())
endf

fu! ctrlp#mrufiles#bufs()
	retu s:mrbs
endf

fu! ctrlp#mrufiles#init()
	if !has('autocmd') | retu | en
	let s:locked = 0
	aug CtrlPMRUF
		au!
		au BufReadPost,BufNewFile,BufWritePost * cal s:record(expand('<abuf>', 1))
		au QuickFixCmdPre  *vimgrep* let s:locked = 1
		au QuickFixCmdPost *vimgrep* let s:locked = 0
	aug END
	aug CtrlPMREB
		au!
		au BufEnter,BufUnload * cal s:record(expand('<abuf>', 1), 1)
	aug END
	if exists('#CtrlPMREF')
		au! CtrlPMREF
	en
	if s:mre
		aug CtrlPMREF
			au!
			au BufEnter,BufUnload * cal s:record(expand('<abuf>', 1))
		aug END
		if exists('#CtrlPMREB')
			au! CtrlPMREB
		en
	en
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
