" =============================================================================
" File:          autoload/ctrlp/sample.vim
" Description:   Example extension for ctrlp.vim
" =============================================================================

" You can rename anything that has 'sample' in it.
" ctrlp.vim only looks for g:ctrlp_ext_vars
"
"
" To load this extension into CtrlP, add this to your vimrc:
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
"         \ 'someone_elses_extension',
"         \ ]


" Change the name of the g:loaded_ variable to make it unique
if ( exists('g:loaded_ctrlp_sample_extension') && g:loaded_ctrlp_sample_extension )
			\ || v:version < '700' || &cp
	fini
endif
let g:loaded_ctrlp_sample_extension = 1


" This is the main variable for this extension, the values are: the name of the
" input function (with the '()'), the name of the action function, and the
" long/short names to use for the statusline
let s:sample_var = [
			\ 'ctrlp#sample#init()',
			\ 'ctrlp#sample#accept',
			\ 'long statusline name',
			\ 'shortname',
			\ ]


" This append the s:sample_var to the global g:ctrlp_ext_vars which will be
" used by other extensions
if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:sample_var)
else
	let g:ctrlp_ext_vars = [s:sample_var]
endif


" Provide a list of strings to search in
"
" Return: a Vim's List
func! ctrlp#sample#init()
	let input = [
				\ 'Sed sodales fringilla magna, non egestas ante consequat nec.',
				\ 'Aenean vel enim quam, mattis ultricies erat.',
				\ 'Donec vel ipsum eget mauris euismod feugiat in ut augue.',
				\ 'Aenean porttitor tempus quam, id pellentesque diam adipiscing ut.',
				\ 'Maecenas luctus mollis ipsum, vitae accumsan magna adipiscing sit amet.',
				\ 'Nulla placerat varius ante, feugiat egestas ligula fringilla vel.',
				\ ]
	retu input
endfunc


" The action to perform on the selected string.
" Do anything you can like.
"
" Arguments:
"  a:mode   the mode that has been chosen by pressing <cr> <c-v> <c-t> or <c-x>
"  a:str    the selected string
func! ctrlp#sample#accept(mode, str)
	" For this example, just exit ctrlp and run help
	cal ctrlp#exit()
	help ctrlp
endfunc


" This gives the extension an ID
let s:id = g:ctrlp_mru_files + 1 + len(g:ctrlp_ext_vars)
func! ctrlp#sample#id()
	retu s:id
endfunc


" Create a command to directly call the new search type.
"
" Use something like this for your vimrc or plugin/sample.vim
" com! CtrlPSample cal ctrlp#init(ctrlp#sample#id())


" vim:fen:fdl=0:ts=2:sw=2:sts=2
