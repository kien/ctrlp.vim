" =============================================================================
" File:          autoload/ctrlp/mrufiles.vim
" Description:   Most Recently Used Files extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Static variables {{{1
fu! ctrlp#mrufiles#opts()
	let opts = {
		\ 'g:ctrlp_mruf_max': ['s:max', 250],
		\ 'g:ctrlp_mruf_include': ['s:include', ''],
		\ 'g:ctrlp_mruf_exclude': ['s:exclude', ''],
		\ 'g:ctrlp_mruf_case_sensitive': ['s:csen', 1],
		\ 'g:ctrlp_mruf_relative': ['s:relate', 0],
		\ 'g:ctrlp_mruf_last_entered': ['s:mre', 0],
		\ }
	for [ke, va] in items(opts)
		exe 'let' va[0] '=' string(exists(ke) ? eval(ke) : va[1])
	endfo
	let s:csen = s:csen ? '#' : '?'
endf
cal ctrlp#mrufiles#opts()
fu! ctrlp#mrufiles#list(bufnr, ...) "{{{1
	if s:locked | retu | en
	let bufnr = a:bufnr + 0
	if bufnr > 0
		let filename = fnamemodify(bufname(bufnr), ':p')
		if empty(filename) || !empty(&bt)
			\ || ( !empty(s:include) && filename !~# s:include )
			\ || ( !empty(s:exclude) && filename =~# s:exclude )
			\ || !filereadable(filename)
			retu
		en
	en
	if !exists('s:cadir') || !exists('s:cafile')
		let s:cadir = ctrlp#utils#cachedir().ctrlp#utils#lash().'mru'
		let s:cafile = s:cadir.ctrlp#utils#lash().'cache.txt'
	en
	if a:0 && a:1 == 2
		cal ctrlp#utils#writecache([], s:cadir, s:cafile)
		retu []
	en
	" Get the list
	let mrufs = ctrlp#utils#readfile(s:cafile)
	" Remove non-existent files
	if a:0 && a:1 == 1
		cal filter(mrufs, '!empty(ctrlp#utils#glob(v:val, 1)) && !s:excl(v:val)')
		cal ctrlp#utils#writecache(mrufs, s:cadir, s:cafile)
	en
	" Return the list with the active buffer removed
	if bufnr == -1
		let crf = fnamemodify(bufname(winbufnr(winnr('#'))), ':p')
		let mrufs = empty(crf) ? mrufs : filter(mrufs, 'v:val !='.s:csen.' crf')
		if s:relate
			let cwd = getcwd()
			cal filter(mrufs, '!stridx(v:val, cwd)')
			cal ctrlp#rmbasedir(mrufs)
		el
			cal map(mrufs, 'fnamemodify(v:val, '':.'')')
		en
		retu mrufs
	en
	" Remove old entry
	cal filter(mrufs, 'v:val !='.s:csen.' filename')
	" Insert new one
	cal insert(mrufs, filename)
	" Remove oldest entry or entries
	if len(mrufs) > s:max | cal remove(mrufs, s:max, -1) | en
	cal ctrlp#utils#writecache(mrufs, s:cadir, s:cafile)
endf "}}}
fu! s:excl(fname) "{{{
	retu !empty(s:exclude) && a:fname =~# s:exclude
endf "}}}
fu! ctrlp#mrufiles#init() "{{{1
	let s:locked = 0
	aug CtrlPMRUF
		au!
		au BufReadPost,BufNewFile,BufWritePost *
			\ cal ctrlp#mrufiles#list(expand('<abuf>', 1))
		if s:mre
			au BufEnter,BufUnload *
				\ cal ctrlp#mrufiles#list(expand('<abuf>', 1))
		en
		au QuickFixCmdPre  *vimgrep* let s:locked = 1
		au QuickFixCmdPost *vimgrep* let s:locked = 0
	aug END
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
