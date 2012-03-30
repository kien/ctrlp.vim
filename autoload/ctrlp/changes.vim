" =============================================================================
" File:          autoload/ctrlp/changes.vim
" Description:   Change list extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{1
if exists('g:loaded_ctrlp_changes') && g:loaded_ctrlp_changes
	fini
en
let g:loaded_ctrlp_changes = 1

let s:changes_var = {
	\ 'init': 'ctrlp#changes#init(s:bufnr, s:crfile)',
	\ 'accept': 'ctrlp#changes#accept',
	\ 'lname': 'changes',
	\ 'sname': 'chs',
	\ 'exit': 'ctrlp#changes#exit()',
	\ 'type': 'tabe',
	\ 'sort': 0,
	\ }

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:changes_var) : [s:changes_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
" Utilities {{{1
fu! s:changelist(bufnr)
	sil! exe 'noa hid b' a:bufnr
	redi => result
	sil! changes
	redi END
	retu map(split(result, "\n")[1:], 'tr(v:val, "	", " ")')
endf

fu! s:process(clines, ...)
	let [clines, evas] = [[], []]
	for each in a:clines
		let parts = matchlist(each, '\v^.\s*\d+\s+(\d+)\s+(\d+)\s(.*)$')
		if !empty(parts)
			if parts[3] == '' | let parts[3] = ' ' | en
			cal add(clines, parts[3].'	|'.a:1.':'.a:2.'|'.parts[1].':'.parts[2].'|')
		en
	endfo
	retu reverse(filter(clines, 'count(clines, v:val) == 1'))
endf

fu! s:syntax()
	if !hlexists('CtrlPBufName')
		hi link CtrlPBufName Directory
	en
	if !hlexists('CtrlPTabExtra')
		hi link CtrlPTabExtra Comment
	en
	sy match CtrlPBufName '\t|\d\+:\zs[^|]\+\ze|\d\+:\d\+|$'
	sy match CtrlPTabExtra '\zs\t.*\ze$' contains=CtrlPBufName
endf
" Public {{{1
fu! ctrlp#changes#init(original_bufnr, fname)
	let fname = exists('s:bufname') ? s:bufname : a:fname
	let bufs = exists('s:clmode') && s:clmode
		\ ? filter(ctrlp#buffers(), 'filereadable(v:val)') : [fname]
	let [swb, &swb] = [&swb, '']
	let lines = []
	for each in bufs
		let [bname, fnamet] = [fnamemodify(each, ':p'), fnamemodify(each, ':t')]
		let bufnr = bufnr('^'.bname.'$')
		if bufnr > 0
			cal extend(lines, s:process(s:changelist(bufnr), bufnr, fnamet))
		en
	endfo
	sil! exe 'noa hid b' a:original_bufnr
	let &swb = swb
	let g:ctrlp_nolimit = 1
	if has('syntax') && exists('g:syntax_on')
		cal ctrlp#syntax()
		cal s:syntax()
	en
	retu lines
endf

fu! ctrlp#changes#accept(mode, str)
	let info = matchlist(a:str, '\t|\(\d\+\):[^|]\+|\(\d\+\):\(\d\+\)|$')
	let bufnr = str2nr(get(info, 1))
	if bufnr
		cal ctrlp#acceptfile(a:mode, fnamemodify(bufname(bufnr), ':p'))
		cal cursor(get(info, 2), get(info, 3))
		sil! norm! zvzz
	en
endf

fu! ctrlp#changes#cmd(mode, ...)
	let s:clmode = a:mode
	if a:0 && !empty(a:1)
		let s:bufname = fnamemodify(a:1, ':p')
	en
	retu s:id
endf

fu! ctrlp#changes#exit()
	unl! s:clmode s:bufname
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
