" =============================================================================
" File:          autoload/ctrlp/tag.vim
" Description:   Tag file extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{
if exists('g:loaded_ctrlp_tag') && g:loaded_ctrlp_tag
	fini
en
let g:loaded_ctrlp_tag = 1

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

fu! s:nodup(lst)
	let dict = {}
	for each in a:lst | cal extend(dict, { each : 0 }) | endfo
	retu keys(dict)
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
"}}}
" Public {{{
fu! ctrlp#tag#init(tagfiles)
	if empty(a:tagfiles) | retu [] | en
	let tagfiles = sort(s:nodup(a:tagfiles))
	let key      = s:hash224(join(tagfiles, ','))
	let cadir    = ctrlp#utils#cachedir().ctrlp#utils#lash().s:tag_var[3]
	let cafile   = cadir.ctrlp#utils#lash().'cache.'.key.'.txt'
	if filereadable(cafile) && max(s:times(tagfiles)) < getftime(cafile)
		if !has_key(g:ctrlp_alltags, key)
			let g:ctrlp_alltags = { key : ctrlp#utils#readfile(cafile) }
		en
		let read_cache = 1
	el
		let g:ctrlp_alltags = { key : [] }
		let eval = 'matchstr(v:val, ''^[^!\t][^\t]*\t\+[^\t]\+\ze\t\+'')'
		for each in tagfiles
			let alltags = filter(map(readfile(each), eval), 'v:val =~# ''\S''')
			cal extend(g:ctrlp_alltags[key], alltags)
		endfo
		let read_cache = 0
	en
	if !read_cache
		cal ctrlp#utils#writecache(g:ctrlp_alltags[key], cadir, cafile)
	en
	sy match CtrlPTagFilename '\zs\t.*\ze$'
	hi link CtrlPTagFilename Comment
	retu g:ctrlp_alltags[key]
endf

fu! ctrlp#tag#accept(mode, str)
	cal ctrlp#exit()
	let [md, tg] = [a:mode, split(a:str, '\t[^\t]\+$')[0]]
	let cmd = md == 't' ? 'tab stj' : md == 'h' ? 'stj'
		\ : md == 'v' ? 'vert stj' : 'tj'
	let cmd = cmd == 'tj' && &modified ? 'hid tj' : cmd
	try
		exe cmd.' '.tg
	cat
		cal ctrlp#msg("Tag not found.")
	endt
endf

fu! ctrlp#tag#id()
	retu s:id
endf
"}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
