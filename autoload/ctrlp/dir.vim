" =============================================================================
" File:          autoload/ctrlp/dir.vim
" Description:   Directory extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{1
if exists('g:loaded_ctrlp_dir') && g:loaded_ctrlp_dir
	fini
en
let [g:loaded_ctrlp_dir, g:ctrlp_newdir] = [1, 0]

let s:ars = [
	\ 's:folsym',
	\ 's:dotfiles',
	\ 's:maxdepth',
	\ 's:maxfiles',
	\ 's:compare_lim',
	\ 's:glob',
	\ ]

let s:dir_var = ['ctrlp#dir#init('.join(s:ars, ', ').')', 'ctrlp#dir#accept',
	\ 'dirs', 'dir']

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:dir_var) : [s:dir_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
" Utilities {{{1
fu! s:globdirs(dirs, depth)
	let entries = split(globpath(a:dirs, s:glob), "\n")
	if !s:folsym
		let entries = filter(entries, 'getftype(v:val) != "link"')
	en
	let ftrfunc = s:dotfiles ? 'ctrlp#dirfilter(v:val)' : 'isdirectory(v:val)'
	let alldirs = filter(entries, ftrfunc)
	cal extend(g:ctrlp_alldirs, alldirs)
	let depth = a:depth + 1
	if !empty(g:ctrlp_alldirs) && !s:max(len(g:ctrlp_alldirs), s:maxfiles)
		\ && depth <= s:maxdepth
		sil! cal ctrlp#progress(len(g:ctrlp_alldirs))
		cal s:globdirs(join(alldirs, ','), depth)
	en
endf

fu! s:max(len, max)
	retu a:max && a:len > a:max ? 1 : 0
endf
" Public {{{1
fu! ctrlp#dir#init(...)
	let s:cwd = getcwd()
	for each in range(len(s:ars))
		exe 'let' s:ars[each] '=' string(eval('a:'.(each + 1)))
	endfo
	let cadir = ctrlp#utils#cachedir().ctrlp#utils#lash().s:dir_var[3]
	let cafile = cadir.ctrlp#utils#lash().ctrlp#utils#cachefile(s:dir_var[3])
	if g:ctrlp_newdir || !filereadable(cafile)
		let g:ctrlp_alldirs = []
		cal s:globdirs(s:cwd, 0)
		cal ctrlp#rmbasedir(g:ctrlp_alldirs)
		let read_cache = 0
	el
		let g:ctrlp_alldirs = ctrlp#utils#readfile(cafile)
		let read_cache = 1
	en
	if len(g:ctrlp_alldirs) <= s:compare_lim
		cal sort(g:ctrlp_alldirs, 'ctrlp#complen')
	en
	if !read_cache
		cal ctrlp#utils#writecache(g:ctrlp_alldirs, cadir, cafile)
		let g:ctrlp_newdir = 0
	en
	retu g:ctrlp_alldirs
endf

fu! ctrlp#dir#accept(mode, str)
	let path = a:mode == 'h' ? getcwd() : s:cwd.ctrlp#utils#lash().a:str
	if a:mode =~ 't\|v\|h'
		cal ctrlp#exit()
	en
	cal ctrlp#setdir(path, a:mode =~ 't\|h' ? 'chd!' : 'lc!')
	if a:mode == 'e'
		sil! cal ctrlp#statusline()
		cal ctrlp#setlines(s:id)
		cal ctrlp#recordhist()
		cal ctrlp#prtclear()
	en
endf

fu! ctrlp#dir#id()
	retu s:id
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
