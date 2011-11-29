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
	retu sort(map(copy(a:tagfiles), 'getftime(v:val)'), 's:compval')
endf

fu! s:compval(...)
	retu a:1 - a:2
endf

fu! s:concat(lst)
	let result = ''
	for each in a:lst
		let result .= each
	endfo
	retu result
endf

fu! s:nodup(lst)
	let dict = {}
	for each in a:lst
		cal extend(dict, { each : 0 })
	endfo
	retu keys(dict)
endf
"}}}
" Public {{{
fu! ctrlp#tag#init(tagfiles)
	if empty(a:tagfiles) | retu [] | en
	let tagfiles = sort(s:nodup(a:tagfiles))
	let &l:tags = join(tagfiles, ',')
	let [tkey, s:ltags] = [s:concat(s:times(tagfiles)), &l:tags]
	let newtags = exists('g:ctrlp_alltags['''.s:ltags.''']')
		\ && keys(g:ctrlp_alltags[s:ltags]) == [tkey] ? 0 : 1
	if newtags
		let tags = taglist('^.*$')
		let alltags = empty(tags) ? []
			\ : map(tags, 'v:val["name"]."	".v:val["filename"]')
		cal extend(g:ctrlp_alltags, { s:ltags : { tkey : alltags } })
	en
	sy match CtrlPTagFilename '\zs\t.*\ze$'
	hi link CtrlPTagFilename Comment
	retu g:ctrlp_alltags[s:ltags][tkey]
endf

fu! ctrlp#tag#accept(mode, str)
	cal ctrlp#exit()
	let md = a:mode
	let cmd = md == 't' ? 'tabnew' : md == 'h' ? 'new' : md == 'v' ? 'vne'
		\ : ctrlp#normcmd('ene')
	let cmd = cmd == 'ene' && &modified ? 'hid ene' : cmd
	try
		exe cmd
		let &l:tags = s:ltags
		exe 'ta' split(a:str, '\t[^\t]\+$')[0]
	cat
		cal ctrlp#msg("Tag not found.")
	endt
endf

fu! ctrlp#tag#id()
	retu s:id
endf
"}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
