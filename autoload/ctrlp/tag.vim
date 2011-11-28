" =============================================================================
" File:          autoload/ctrlp/tag.vim
" Description:   Tag file extension
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{
if exists('g:loaded_ctrlp_tag') && g:loaded_ctrlp_tag
	fini
en
let [g:loaded_ctrlp_tag, g:ctrlp_newtag] = [1, 0]

let s:tag_var = ['ctrlp#tag#init()', 'ctrlp#tag#accept', 'tags', 'tag']

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:tag_var) : [s:tag_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
"}}}
" Public {{{
fu! ctrlp#tag#init()
	if exists('s:cwd') && s:cwd == getcwd()
		let newtags = 0
	el
		let s:cwd = getcwd()
		let newtags = 1
	en
	if ( newtags && !exists('g:ctrlp_alltags['''.s:cwd.''']') ) || g:ctrlp_newtag
		let alltags = map(taglist('.*'), 'v:val["name"]."	".v:val["filename"]')
		cal extend(g:ctrlp_alltags, { s:cwd : alltags })
		let g:ctrlp_newtag = 0
	en
	sy match CtrlPTagFilename '\zs\t.*\ze$'
	hi link CtrlPTagFilename Comment
	retu g:ctrlp_alltags[s:cwd]
endf

fu! ctrlp#tag#accept(mode, str)
	cal ctrlp#exit()
	let md = a:mode
	let cmd = md == 't' ? 'tabnew' : md == 'h' ? 'new' : md == 'v' ? 'vne'
		\ : ctrlp#normcmd('ene')
	let cmd = cmd == 'ene' && &modified ? 'hid ene' : cmd
	try
		exe cmd
		cal ctrlp#setdir(s:cwd)
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
