" =============================================================================
" File:          autoload/ctrlp/quickfix.vim
" Description:   Quickfix extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{1
if exists('g:loaded_ctrlp_quickfix') && g:loaded_ctrlp_quickfix
	fini
en
let g:loaded_ctrlp_quickfix = 1

let s:var_qf = ['ctrlp#quickfix#init()', 'ctrlp#quickfix#accept', 'quickfix',
	\ 'qfx', [1]]

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:var_qf) : [s:var_qf]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

fu! s:lineout(dict)
	retu printf('%s|%d:%d| %s', bufname(a:dict['bufnr']), a:dict['lnum'],
		\ a:dict['col'], matchstr(a:dict['text'], '\s*\zs.*\S'))
endf
" Public {{{1
fu! ctrlp#quickfix#init()
	let g:ctrlp_nolimit = 1
	sy match CtrlPqfLineCol '|\zs\d\+:\d\+\ze|'
	hi def link CtrlPqfLineCol Search
	retu map(getqflist(), 's:lineout(v:val)')
endf

fu! ctrlp#quickfix#accept(mode, str)
	let items = matchlist(a:str, '^\([^|]\+\ze\)|\(\d\+\):\(\d\+\)|')
	let [md, filpath] = [a:mode, fnamemodify(items[1], ':p')]
	if empty(filpath) | retu | en
	cal ctrlp#exit()
	let cmd = md == 't' ? 'tabe' : md == 'h' ? 'new' : md == 'v' ? 'vne'
		\ : ctrlp#normcmd('e')
	let cmd = cmd == 'e' && &modified ? 'hid e' : cmd
	try
		exe cmd.' '.ctrlp#fnesc(filpath)
	cat
		cal ctrlp#msg("Invalid command or argument.")
	fina
		cal cursor(items[2], items[3]) | sil! norm! zOzz
	endt
endf

fu! ctrlp#quickfix#id()
	retu s:id
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
