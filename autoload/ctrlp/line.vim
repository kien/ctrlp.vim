" =============================================================================
" File:          autoload/ctrlp/line.vim
" Description:   Line extension - Find a line in any buffer
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" User Configuration {{{1
" Enable:
"        let g:ctrlp_extensions += ['line']
" Create A Command:
"        com! CtrlPLine cal ctrlp#init(ctrlp#line#id())
"}}}

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
" Public {{{1
fu! ctrlp#line#init()
	let [bufs, lines] = [ctrlp#allbufs(), []]
	for each in bufs
		let from_file = readfile(each)
		cal map(from_file, 'tr(v:val, ''	'', '' '')')
		let [id, len_ff, bufnr] = [1, len(from_file), bufnr('^'.each.'$')]
		wh id <= len_ff
			let from_file[id-1] .= '	#:'.bufnr.':'.id
			let id += 1
		endw
		cal filter(from_file, 'v:val !~ ''^\s*\t#:\d\+:\d\+$''')
		cal extend(lines, from_file)
	endfo
	sy match CtrlPTabExtra '\zs\t.*\ze$'
	hi link CtrlPTabExtra Comment
	retu lines
endf

fu! ctrlp#line#accept(mode, str)
	let info   = get(split(a:str, '\t#:\ze\d\+:\d\+$'), 1, 0)
	let bufnr  = str2nr(get(split(info, ':'), 0, 0))
	let linenr = get(split(info, ':'), 1, 0)
	if bufnr
		cal ctrlp#acceptfile(a:mode, fnamemodify(bufname(bufnr), ':p'), linenr)
	en
endf

fu! ctrlp#line#id()
	retu s:id
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
