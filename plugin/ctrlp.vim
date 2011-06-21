" ============================================================
" File:          plugin/ctrlp.vim
" Description:   File finder, fuzzy style.
" Author:        Kien Nguyen <info@designtomarkup.com>
" License:       MIT
" ============================================================

if exists('g:loaded_ctrlp') && g:loaded_ctrlp
	finish
endif
let g:loaded_ctrlp = 1

if !exists('g:CtrlP_Key')
	let g:CtrlP_Key = '<leader>l'
endif

com! CtrlP cal ctrlp#init()

exe 'nn <silent>' g:CtrlP_Key ':<c-u>CtrlP<cr>'
