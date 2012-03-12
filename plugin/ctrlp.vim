" =============================================================================
" File:          plugin/ctrlp.vim
" Description:   Fuzzy file, buffer, mru and tag finder.
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================
" GetLatestVimScripts: 3736 1 :AutoInstall: ctrlp.zip

if ( exists('g:loaded_ctrlp') && g:loaded_ctrlp ) || v:version < 700 || &cp
	fini
en
let [g:loaded_ctrlp, g:ctrlp_lines, g:ctrlp_allfiles] = [1, [], []]

if !exists('g:ctrlp_map') | let g:ctrlp_map = '<c-p>' | en
if !exists('g:ctrlp_cmd') | let g:ctrlp_cmd = 'CtrlP' | en

com! -n=? -com=dir CtrlP cal ctrlp#init(0, <q-args>)

com! CtrlPBuffer   cal ctrlp#init(1)
com! CtrlPMRUFiles cal ctrlp#init(2)

com! CtrlPClearCache     cal ctrlp#clr()
com! CtrlPClearAllCaches cal ctrlp#clra()
com! CtrlPReload         cal ctrlp#reset()

com! ClearCtrlPCache     cal ctrlp#clr()
com! ClearAllCtrlPCaches cal ctrlp#clra()
com! ResetCtrlP          cal ctrlp#reset()

com! CtrlPCurWD   cal ctrlp#init(0, 0)
com! CtrlPCurFile cal ctrlp#init(0, 1)
com! CtrlPRoot    cal ctrlp#init(0, 2)

if g:ctrlp_map != '' && !hasmapto(':<c-u>'.g:ctrlp_cmd.'<cr>', 'n')
	exe 'nn <silent>' g:ctrlp_map ':<c-u>'.g:ctrlp_cmd.'<cr>'
en

cal ctrlp#mrufiles#init()

if !exists('g:ctrlp_extensions') | fini | en

let s:ext = g:ctrlp_extensions

if index(s:ext, 'tag') >= 0
	let g:ctrlp_alltags = []
	com! CtrlPTag cal ctrlp#init(ctrlp#tag#id())
en

if index(s:ext, 'quickfix') >= 0
	com! CtrlPQuickfix cal ctrlp#init(ctrlp#quickfix#id())
en

if index(s:ext, 'dir') >= 0
	let g:ctrlp_alldirs = []
	com! -n=? -com=dir CtrlPDir cal ctrlp#init(ctrlp#dir#id(), <q-args>)
en

if index(s:ext, 'buffertag') >= 0
	let g:ctrlp_buftags = {}
	com! -n=? -com=buffer CtrlPBufTag
		\ cal ctrlp#init(ctrlp#buffertag#cmd(0, <q-args>))
	com! CtrlPBufTagAll cal ctrlp#init(ctrlp#buffertag#cmd(1))
en

if index(s:ext, 'rtscript') >= 0
	com! CtrlPRTS cal ctrlp#init(ctrlp#rtscript#id())
en

if index(s:ext, 'undo') >= 0
	com! CtrlPUndo cal ctrlp#init(ctrlp#undo#id())
en

if index(s:ext, 'line') >= 0
	com! CtrlPLine cal ctrlp#init(ctrlp#line#id())
en

if index(s:ext, 'changes') >= 0
	com! -n=? -com=buffer CtrlPChange
		\ cal ctrlp#init(ctrlp#changes#cmd(0, <q-args>))
	com! CtrlPChangeAll cal ctrlp#init(ctrlp#changes#cmd(1))
en

unl s:ext
