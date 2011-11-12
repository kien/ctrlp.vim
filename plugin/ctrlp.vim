" =============================================================================
" File:          plugin/ctrlp.vim
" Description:   Fuzzy file, buffer and MRU file finder.
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================
" GetLatestVimScripts: 3736 1 :AutoInstall: ctrlp.zip

if ( exists('g:loaded_ctrlp') && g:loaded_ctrlp ) || v:version < 700 || &cp
	fini
en
let g:loaded_ctrlp = 1

if !exists('g:ctrlp_map') | let g:ctrlp_map = '<c-p>' | en

com! -na=? -comp=custom,ctrlp#cpl CtrlP cal ctrlp#init(0, <q-args>)

com! CtrlPBuffer   cal ctrlp#init(1)
com! CtrlPMRUFiles cal ctrlp#init(2)

com! ClearCtrlPCache cal ctrlp#clr()
com! ClearAllCtrlPCaches cal ctrlp#clra()
com! ResetCtrlP cal ctrlp#reset()

com! CtrlPCurWD   cal ctrlp#init(0, 0)
com! CtrlPCurFile cal ctrlp#init(0, 1)
com! CtrlPRoot    cal ctrlp#init(0, 2)

exe 'nn <silent>' g:ctrlp_map ':<c-u>CtrlP<cr>'

cal ctrlp#mrufiles#init()

let [g:ctrlp_lines, g:ctrlp_allfiles] = [[], []]
