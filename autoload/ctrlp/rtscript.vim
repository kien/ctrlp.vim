" =============================================================================
" File:          autoload/ctrlp/rtscript.vim
" Description:   Runtime scripts extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{1
if exists('g:loaded_ctrlp_rtscript') && g:loaded_ctrlp_rtscript
	fini
en
let [g:loaded_ctrlp_rtscript, g:ctrlp_newrts] = [1, 0]

let s:rtscript_var = {
	\ 'init': 'ctrlp#rtscript#init()',
	\ 'accept': 'ctrlp#rtscript#accept',
	\ 'lname': 'runtime scripts',
	\ 'sname': 'rts',
	\ 'type': 'path',
	\ }

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:rtscript_var) : [s:rtscript_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
" Public {{{1
fu! ctrlp#rtscript#init()
	if g:ctrlp_newrts || !exists('g:ctrlp_rtscache')
		sil! cal ctrlp#progress('Indexing...')
		let entries = split(globpath(&rtp, '**/*.*'), "\n")
		cal filter(entries, 'index(entries, v:val, v:key + 1) < 0')
		cal map(entries, 'fnamemodify(v:val, '':.'')')
		let [g:ctrlp_rtscache, g:ctrlp_newrts] = [ctrlp#dirnfile(entries)[1], 0]
	en
	retu g:ctrlp_rtscache
endf

fu! ctrlp#rtscript#accept(mode, str)
	cal ctrlp#acceptfile(a:mode, a:str)
endf

fu! ctrlp#rtscript#id()
	retu s:id
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
