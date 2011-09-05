" ============================================================
" File:          plugin/ctrlp.vim
" Description:   Full path fuzzy file finder for Vim.
" Author:        Kien Nguyen <info@designtomarkup.com>
" License:       MIT
" ============================================================

if ( exists('g:loaded_ctrlp') && g:loaded_ctrlp )
			\ || v:version < '700'
	fini
endif
let g:loaded_ctrlp = 1

if !exists('g:ctrlp_map')
	let g:ctrlp_map = '<c-p>'
endif

com! CtrlP               cal ctrlp#init(0)
com! CtrlPBuffer         cal ctrlp#init(1)
com! ClearCtrlPCache     cal ctrlp#clearcache()
com! ClearAllCtrlPCaches cal ctrlp#clearallcaches()

exe 'nn <silent>' g:ctrlp_map ':<c-u>CtrlP<cr>'
