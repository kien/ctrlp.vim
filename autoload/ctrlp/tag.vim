" =============================================================================
" File:          autoload/ctrlp/tag.vim
" Description:   Tag file extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{
if exists('g:loaded_ctrlp_tag') && g:loaded_ctrlp_tag
	fini
en
let [g:loaded_ctrlp_tag, g:ctrlp_find_tag_count] = [1, 0]

let s:tag_var = ['ctrlp#tag#init(s:tagfiles)', 'ctrlp#tag#accept',
	\ 'tags', 'tag']

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:tag_var) : [s:tag_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
"}}}
" Utilities {{{
fu! s:times(tagfiles)
	retu map(copy(a:tagfiles), 'getftime(v:val)')
endf

fu! s:nodup(items)
	let dict = {}
	for each in a:items
		cal extend(dict, { each : 0 })
	endfo
	retu keys(dict)
endf

fu! s:concat(lists)
	let lists = []
	for each in a:lists
		cal extend(lists, each)
	endfo
	retu lists
endf

fu! s:hash224(str)
	let [a, b, nHash] = [0x00000800, 0x001fffff, 7]
	let hashes = repeat([0], nHash)
	for i in range(len(a:str))
		let iHash = i % nHash
		let hashes[iHash] = hashes[iHash] * a + hashes[iHash] / b
		let hashes[iHash] += char2nr(a:str[i])
	endfo
	retu join(map(hashes, 'printf("%08x", v:val)'), '')
endf

fu! s:findcount(str)
	let leng = len(g:ctrlp_alltags[s:key])
	if leng == 1 | retu [0, 0] | en
	let tg = split(a:str, '\t[^\t]\+$')[0]
	let [fnd, fndpos, pos] = [0, 0, 0]
	for each in g:ctrlp_alltags[s:key]
		let arrtg = map(copy(each), 'split(v:val, ''\t\+[^\t]\+$'')[0]')
		if index(arrtg, tg) >= 0
			let pos += 1
			if index(each, a:str) >= 0
				let fnd += 1
				let fndpos = pos
			en
		en
		if fnd > 1 | brea | en
	endfo
	retu [fnd, fndpos]
endf
"}}}
" Public {{{
fu! ctrlp#tag#init(tagfiles)
	if empty(a:tagfiles) | retu [] | en
	let tagfiles = sort(s:nodup(a:tagfiles))
	let s:ltags  = join(tagfiles, ',')
	let s:key    = s:hash224(s:ltags)
	let cadir    = ctrlp#utils#cachedir().ctrlp#utils#lash().s:tag_var[3]
	let cafile   = cadir.ctrlp#utils#lash().'cache.'.s:key.'.txt'
	if filereadable(cafile) && max(s:times(tagfiles)) < getftime(cafile)
		if !has_key(g:ctrlp_alltags, s:key)
			try
				let g:ctrlp_alltags = { s:key : eval(ctrlp#utils#readfile(cafile)[0]) }
			cat
				sil! cal delete(cafile) | retu []
			endt
		en
		let read_cache = 1
	el
		let g:ctrlp_alltags = { s:key : [] }
		let eval = 'matchstr(v:val, ''^[^!\t][^\t]*\t\+[^\t]\+\ze\t\+'')'
		for each in tagfiles
			let alltags = map(ctrlp#utils#readfile(each), eval)
			let alltags = filter(alltags, 'v:val =~# ''\S''')
			cal extend(g:ctrlp_alltags[s:key], [alltags])
		endfo
		let read_cache = 0
	en
	if !read_cache
		let lines = [string(g:ctrlp_alltags[s:key])]
		cal ctrlp#utils#writecache(lines, cadir, cafile)
	en
	sy match CtrlPTagFilename '\zs\t.*\ze$'
	hi link CtrlPTagFilename Comment
	retu s:concat(g:ctrlp_alltags[s:key])
endf

fu! ctrlp#tag#accept(mode, str)
	cal ctrlp#exit()
	let [md, tg] = [a:mode, split(a:str, '\t\+[^\t]\+$')[0]]
	let fnd = g:ctrlp_find_tag_count ? s:findcount(a:str) : [0, 0]
	if fnd[0] == 1
		let cmd = md == 't' ? 'tabe' : md == 'h' ? 'new'
			\ : md == 'v' ? 'vne' : 'ene'
	el
		let cmd = md == 't' ? 'tab stj' : md == 'h' ? 'stj'
			\ : md == 'v' ? 'vert stj' : 'tj'
	en
	let cmd = cmd =~ 'tj\|ene' && &modified ? 'hid '.cmd : cmd
	try
		if fnd[0] == 1
			exe cmd
			let &l:tags = s:ltags
			exe fnd[1].'ta' tg
		el
			exe cmd.' '.tg
		en
	cat
		cal ctrlp#msg("Tag not found.")
	endt
endf

fu! ctrlp#tag#id()
	retu s:id
endf
"}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
