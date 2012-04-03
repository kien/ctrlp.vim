" =============================================================================
" File:          autoload/ctrlp/mixed.vim
" Description:   Files + MRU
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{1
if exists('g:loaded_ctrlp_mixed') && g:loaded_ctrlp_mixed
	fini
en
let [g:loaded_ctrlp_mixed, g:ctrlp_newmix] = [1, 0]

let s:mixed_var = {
	\ 'init': 'ctrlp#mixed#init(s:compare_lim)',
	\ 'accept': 'ctrlp#acceptfile',
	\ 'lname': 'fil + mru',
	\ 'sname': 'mix',
	\ 'type': 'path',
	\ 'opmul': 1,
	\ 'specinput': 1,
	\ }

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:mixed_var) : [s:mixed_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
" Utilities {{{1
fu! s:newcache(cwd)
	if !has_key(g:ctrlp_allmixes, 'data') | retu 1 | en
	retu g:ctrlp_allmixes['cwd'] != a:cwd
		\ || g:ctrlp_allmixes['time'] < getftime(ctrlp#utils#cachefile())
		\ || g:ctrlp_allmixes['bufs'] < len(ctrlp#mrufiles#mrufs())
endf

fu! s:getnewmix(cwd, clim)
	if g:ctrlp_newmix
		cal ctrlp#mrufiles#refresh('raw')
		let g:ctrlp_newcache = 1
	en
	cal ctrlp#files()
	cal ctrlp#progress('Mixing...')
	let mrufs = ctrlp#mrufiles#list('raw')
	if exists('+ssl') && &ssl
		cal map(mrufs, 'tr(v:val, "\\", "/")')
	en
	if len(mrufs) > len(g:ctrlp_allfiles) || v:version < 702
		cal filter(mrufs, 'stridx(v:val, a:cwd)')
	el
		let cwd_mrufs = filter(copy(mrufs), '!stridx(v:val, a:cwd)')
		let cwd_mrufs = ctrlp#rmbasedir(cwd_mrufs)
		for each in cwd_mrufs
			let id = index(g:ctrlp_allfiles, each)
			if id >= 0 | cal remove(g:ctrlp_allfiles, id) | en
		endfo
	en
	cal map(mrufs, 'fnamemodify(v:val, ":.")')
	let g:ctrlp_lines = len(mrufs) > len(g:ctrlp_allfiles)
		\ ? g:ctrlp_allfiles + mrufs : mrufs + g:ctrlp_allfiles
	if len(g:ctrlp_lines) <= a:clim
		cal sort(g:ctrlp_lines, 'ctrlp#complen')
	en
	let g:ctrlp_allmixes = { 'time': getftime(ctrlp#utils#cachefile()),
		\ 'cwd': a:cwd, 'bufs': len(ctrlp#mrufiles#mrufs()), 'data': g:ctrlp_lines }
endf
" Public {{{1
fu! ctrlp#mixed#init(clim)
	let cwd = getcwd()
	if g:ctrlp_newmix || s:newcache(cwd)
		cal s:getnewmix(cwd, a:clim)
	el
		let g:ctrlp_lines = g:ctrlp_allmixes['data']
	en
	let g:ctrlp_newmix = 0
	retu g:ctrlp_lines
endf

fu! ctrlp#mixed#id()
	retu s:id
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
