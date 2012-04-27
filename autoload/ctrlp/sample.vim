" =============================================================================
" File:          autoload/ctrlp/sample.vim
" Description:   Example extension for ctrlp.vim
" =============================================================================

" To load this extension into ctrlp, add this to your vimrc:
"
"     let g:ctrlp_extensions = ['sample']
"
" Where 'sample' is the name of the file 'sample.vim'
"
" For multiple extensions:
"
"     let g:ctrlp_extensions = [
"         \ 'my_extension',
"         \ 'my_other_extension',
"         \ ]

" Get the script's filename, in this example s:n is 'sample'
let s:n = exists('s:n') ? s:n : fnamemodify(expand('<sfile>', 1), ':t:r')

" Load guard
if ( exists('g:loaded_ctrlp_'.s:n) && g:loaded_ctrlp_{s:n} )
	\ || v:version < 700 || &cp
	finish
endif
let g:loaded_ctrlp_{s:n} = 1


" Add this extension's settings to g:ctrlp_ext_vars
"
" Required:
"
" + init: the name of the input function including the brackets and any
"         arguments
"
" + accept: the name of the action function (only the name)
"
" + lname & sname: the long and short names to use for the statusline
"
" + type: the matching type
"   - line : match full line
"   - path : match full line like a file or a directory path
"   - tabs : match until first tab character
"   - tabe : match until last tab character
"
" Optional:
"
" + enter: the name of the function to be called before starting ctrlp
"
" + exit: the name of the function to be called after closing ctrlp
"
" + opts: the name of the option handling function called when initialize
"
" + sort: disable sorting (enabled by default when omitted)
"
call add(g:ctrlp_ext_vars, {
	\ 'init': 'ctrlp#'.s:n.'#init()',
	\ 'accept': 'ctrlp#'.s:n.'#accept',
	\ 'lname': 'long statusline name',
	\ 'sname': 'shortname',
	\ 'type': 'line',
	\ 'enter': 'ctrlp#'.s:n.'#enter()',
	\ 'exit': 'ctrlp#'.s:n.'#exit()',
	\ 'opts': 'ctrlp#'.s:n.'#opts()',
	\ 'sort': 0,
	\ })


" Provide a list of strings to search in
"
" Return: a Vim's List
"
function! ctrlp#{s:n}#init()
	let input = [
		\ 'Sed sodales fri magna, non egestas ante consequat nec.',
		\ 'Aenean vel enim mattis ultricies erat.',
		\ 'Donec vel ipsummauris euismod feugiat in ut augue.',
		\ 'Aenean porttitous quam, id pellentesque diam adipiscing ut.',
		\ 'Maecenas luctuss ipsum, vitae accumsan magna adipiscing sit amet.',
		\ 'Nulla placerat  ante, feugiat egestas ligula fringilla vel.',
		\ ]
	return input
endfunction


" The action to perform on the selected string
"
" Arguments:
"  a:mode   the mode that has been chosen by pressing <cr> <c-v> <c-t> or <c-x>
"           the values are 'e', 'v', 't' and 'h', respectively
"  a:str    the selected string
"
function! ctrlp#{s:n}#accept(mode, str)
	" For this example, just exit ctrlp and run help
	call ctrlp#exit()
	help ctrlp-extensions
endfunction


" Do something before enterting ctrlp
function! ctrlp#{s:n}#enter()
endfunction


" Do something after exiting ctrlp
function! ctrlp#{s:n}#exit()
endfunction


" Give the extension an ID
let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

" Allow it to be called later
function! ctrlp#{s:n}#id()
	return s:id
endfunction


" Create a command to directly call the new search type
"
" Put this in vimrc or plugin/sample.vim
" command! CtrlPSample call ctrlp#init(ctrlp#sample#id())


" vim:fen:fdl=0:ts=2:sw=2:sts=2
