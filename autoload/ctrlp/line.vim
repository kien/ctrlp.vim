" =============================================================================
" File:          autoload/ctrlp/line.vim
" Description:   Line extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{1
if exists('g:loaded_ctrlp_line') && g:loaded_ctrlp_line
	fini
en
let g:loaded_ctrlp_line = 1

let s:line_var = {
	\ 'init': 'ctrlp#line#init()',
	\ 'accept': 'ctrlp#line#accept',
	\ 'lname': 'lines',
	\ 'sname': 'lns',
	\ 'type': 'tabe',
	\ }

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:line_var) : [s:line_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
" Utilities {{{1
fu! s:syntax()
	if !hlexists('CtrlPBufName')
		hi link CtrlPBufName Directory
	en
	if !hlexists('CtrlPTabExtra')
		hi link CtrlPTabExtra Comment
	en
	sy match CtrlPBufName '\t|\zs[^|]\+\ze|\d\+:\d\+|$'
	sy match CtrlPTabExtra '\zs\t.*\ze$' contains=CtrlPBufName
endf
" Public {{{1
fu! ctrlp#line#init()
	let [bufs, lines] = [filter(ctrlp#buffers(), 'filereadable(v:val)'), []]
	for each in bufs
		let [fnamet, from_file] = [fnamemodify(each, ':t'), readfile(each)]
		let bname = fnamemodify(each, ':p')
		cal map(from_file, 'tr(v:val, ''	'', '' '')')
		let [id, len_ff, bufnr] = [1, len(from_file), bufnr('^'.bname.'$')]
		wh id <= len_ff
			let from_file[id-1] .= '	|'.fnamet.'|'.bufnr.':'.id.'|'
			let id += 1
		endw
		cal filter(from_file, 'v:val !~ ''^\s*\t|[^|]\+|\d\+:\d\+|$''')
		cal extend(lines, from_file)
	endfo
	if has('syntax') && exists('g:syntax_on')
		cal s:syntax()
	en
	retu lines
endf

fu! ctrlp#line#accept(mode, str)
	let info = matchlist(a:str, '\t|[^|]\+|\(\d\+\):\(\d\+\)|$')
	let [bufnr, linenr] = [str2nr(get(info, 1)), get(info, 2)]
	if bufnr > 0
		cal ctrlp#acceptfile(a:mode, fnamemodify(bufname(bufnr), ':p'), linenr)
	en
endf

fu! ctrlp#line#id()
	retu s:id
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
