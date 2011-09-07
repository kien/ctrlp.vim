" =============================================================================
" File:          plugin/ctrlp.vim
" Description:   Full path fuzzy file and buffer finder for Vim.
" Author:        Kien Nguyen <github.com/kien>
" License:       MIT
" =============================================================================

if ( exists('g:loaded_ctrlp') && g:loaded_ctrlp ) || v:version < '700' || &cp
	fini
endif
let g:loaded_ctrlp = 1

if !exists('g:ctrlp_map')       | let g:ctrlp_map = '<c-p>' | endif
if !exists('g:ctrlp_mru_files') | let g:ctrlp_mru_files = 1 | endif

com! CtrlP               cal ctrlp#init(0)
com! CtrlPBuffer         cal ctrlp#init(1)
com! CtrlPMRUFiles       cal ctrlp#init(2)
com! ClearCtrlPCache     cal ctrlp#clearcache()
com! ClearAllCtrlPCaches cal ctrlp#clearallcaches()

exe 'nn <silent>' g:ctrlp_map ':<c-u>CtrlP<cr>'

if g:ctrlp_mru_files | cal ctrlp#mrufiles#init() | endif
