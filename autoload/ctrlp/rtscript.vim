" =============================================================================
" File:          autoload/ctrlp/rtscript.vim
" Description:   Runtime scripts extension - Find vimscripts in runtimepath
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" User Configuration {{{1
" Enable:
"        let g:ctrlp_extensions += ['rtscript']
" Create A Command:
"        com! CtrlPRTS cal ctrlp#init(ctrlp#rtscript#id())
"}}}

" Init {{{1
if exists('g:loaded_ctrlp_rtscript') && g:loaded_ctrlp_rtscript
	fini
en
let [g:loaded_ctrlp_rtscript, g:ctrlp_newrts] = [1, 0]

let s:rtscript_var = ['ctrlp#rtscript#init()', 'ctrlp#rtscript#accept',
	\ 'runtime scripts', 'rts']

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:rtscript_var) : [s:rtscript_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
" Public {{{1
fu! ctrlp#rtscript#init()
	if g:ctrlp_newrts || !exists('g:ctrlp_rtscache')
		let entries = split(globpath(&rtp, '**/*.\(vim\|txt\)'), "\n")
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
