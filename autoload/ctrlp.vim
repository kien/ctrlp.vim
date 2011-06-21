" ============================================================
" File:          autoload/ctrlp.vim
" Description:   File finder, fuzzy style.
" Author:        Kien Nguyen <info@designtomarkup.com>
" License:       MIT
" ============================================================

let s:save_cpo = &cpo
set cpo&vim

" Requirements {{{
if v:version < '703'
	echoh Error
	ec 'CtrlP requires Vim 7.3+'
	echoh None
	fini
endif
"}}}

" Option variables {{{
if !exists('g:CtrlPMatchWindowReverse')
  let s:mwreverse = 1
else
  let s:mwreverse = g:CtrlPMatchWindowReverse
  unlet g:CtrlPMatchWindowReverse
endif

if !exists('g:CtrlPPersistenceInput')
  let s:pinput = 1
else
  let s:pinput = g:CtrlPPersistenceInput
  unlet g:CtrlPPersistenceInput
endif

if !exists('g:CtrlPSplitWindow')
  let s:splitwin = 3
else
  let s:splitwin = g:CtrlPSplitWindow
  unlet g:CtrlPSplitWindow
endif

if !exists('g:CtrlPUpdateDelay')
  let s:udelay = 500
else
  let s:udelay = g:CtrlPUpdateDelay
  unlet g:CtrlPUpdateDelay
endif

if !exists('g:CtrlPIgnoreSpace')
  let s:igspace = 1
else
  let s:igspace = g:CtrlPIgnoreSpace
  unlet g:CtrlPIgnoreSpace
endif

if !exists('g:CtrlPSetWorkingPathMode')
  let s:pathmode = 1
else
  let s:pathmode = g:CtrlPSetWorkingPathMode
  unlet g:CtrlPSetWorkingPathMode
endif

if !exists('g:CtrlP_max_height')
  let s:mxheight = 10
else
  let s:mxheight = g:CtrlP_max_height
  unlet g:CtrlP_max_height
endif
"}}}

" s:SplitPattern() {{{
func! s:SplitPattern(str,...)
	let str = a:str
	" Split into a list, ignoring spaces
	if s:igspace
		let str = substitute(a:str, ' ', '', 'g')
	endif
	if match(str, '[*?^]') >= 0 " If pattern contains * or ?
		let array = [str]
	elseif match(str, ':\d*$') >= 0 " If pattern contains :\d (e.g. abc:25)
		let tmp = split(str, ':\ze\d*$')
		let array = split(tmp[0], '\zs')
		if len(tmp) >= 2
			cal add(array, ':'.tmp[1])
		endif
	else
		let array = split(str, '\zs')
	endif
	" Build the new pattern
	if !empty(array)
		let nitem = array[0]
	else
		let nitem = ''
	endif
	let newpats = [nitem]
	if len(array) > 1
		for i in range(1, len(array) - 1)
			" Separator
			if !exists('a:1')
				let sp = '.*'
				"exe "let sp = '[^".array[i - 1].array[i]."]*'"
			else
				let sp = a:1
			endif
			let nitem .= sp.array[i]
			let newpats = add(newpats, nitem)
		endfor
	endif
	retu newpats
endfunc
"}}}

" s:GetDataFile() {{{
func! s:GetDataFile(file)
	if filereadable(a:file)
		let lines = readfile(a:file)
		retu lines
	else
		retu 0
	endif
endfunc
"}}}

" s:ListAllFiles() {{{
func! s:ListAllFiles(path)
	let allfiles = split(globpath(a:path, '**', 1))
	sil! cal filter(allfiles, '!isdirectory(v:val)')
	if &ssl || !exists('+shellslash')
		let path = getcwd().'/'
	else
		let path = substitute(getcwd(), '\', '\\\\\\\\', 'g').'\\\\'
	endif
	sil! cal map(allfiles, 'substitute(v:val, "'.path.'", "", "g")')
	retu allfiles
endfunc
"}}}

"TODO: try to make this run faster
" s:GetMatchedItems() {{{
func! s:GetMatchedItems(items, pats, limit)
	let items = a:items
	let pats = a:pats
	if exists('s:line')
		unlet s:line
	endif
	if match(pats[-1], ':\d*$') >= 0
		let s:line = substitute(pats[-1], '.*\ze:\d*$', '', 'g')
		cal remove(pats, -1)
	endif
	if len(items) >= 2000
		let pats = [pats[-1]]
	endif
	for each in pats
		if exists('newitems') && len(newitems) < a:limit
			let items = newitems
		endif
		if empty(items)
			retu newitems
		else
			let newitems = []
			for item in items
				if match(item, each) >= 0
					let newitems = add(newitems, item)
				endif
				if a:limit != 0 && len(newitems) == a:limit
					break
				endif
			endfor
		endif
	endfor
	retu newitems
endfunc
"}}}

" s:SetupBlank() && s:BufOpen() {{{
func! s:SetupBlank(name)
	exe 'setl ft='.a:name
	setl bt=nofile
	setl bh=delete
	setl noswf
	setl noudf
	setl nobl
	setl ts=4
	setl sw=4
	setl sts=4
	setl nonu
	setl nornu
	setl nowrap
	setl nolist
	setl nospell
	setl cul
	setl nocuc
	setl tw=0
	setl cc=0
	setl wfw
endfunc

" Open new buffer, store global options
func! s:BufOpen(...)
	" a:1 bufname; a:2 delete
	let buf = a:1
	let bufnum = bufnr(buf)
	" Closing
	if bufnum > 0 && bufwinnr(bufnum) > 0
		exe bufwinnr(bufnum).'winc w' | exe 'winc c'
	endif
	if exists('a:2')
		" Restore the changed global options
		exe 'let &magic=' . s:CtrlP_magic
		exe 'let &to='    . s:CtrlP_to
		exe 'se tm='      . s:CtrlP_tm
		exe 'let &sb='    . s:CtrlP_sb
		exe 'let &hls='   . s:CtrlP_hls
		exe 'let &im='    . s:CtrlP_im
		exe 'se report='  . s:CtrlP_report
		exe 'let &sc='    . s:CtrlP_sc
		exe 'se ss='      . s:CtrlP_ss
		exe 'se siso='    . s:CtrlP_siso
		exe 'let &ea='    . s:CtrlP_ea
		exe 'let &ut='    . s:CtrlP_ut
		exe 'se gcr='     . s:CtrlP_gcr
		echo
	else
		" Opening
		exe 'sil! botright 1new '.buf
		" Store global options
		let s:CtrlP_magic  = &magic
		let s:CtrlP_to     = &to
		let s:CtrlP_tm     = &tm
		let s:CtrlP_sb     = &sb
		let s:CtrlP_hls    = &hls
		let s:CtrlP_im     = &im
		let s:CtrlP_report = &report
		let s:CtrlP_sc     = &sc
		let s:CtrlP_ss     = &ss
		let s:CtrlP_siso   = &siso
		let s:CtrlP_ea     = &ea
		let s:CtrlP_ut     = &ut
		let s:CtrlP_gcr    = &gcr
		if !exists('g:CtrlP_prompt') || s:pinput == 0
			let g:CtrlP_prompt = ['', '', '']
		endif
		let s:CtrlP_win = 0
		se magic
		se to
		se tm=0
		se sb
		se nohls
		se noim
		se report=9999
		se nosc
		se ss=0
		se siso=0
		se noea
		exe 'se ut='.s:udelay
		se gcr=a:block-PmenuSel-blinkon0
	endif
endfunc
"}}}

" s:Renderer() {{{
func! s:Renderer(lines)
	let nls = []
	for i in range(0, len(a:lines) - 1)
		let nls = add(nls, '> '.a:lines[i])
	endfor
	" Detemine/set max height
	let height = s:mxheight
	if len(nls) < height
		let max = len(nls)
	else
		let max = height
	endif
	exe 'res '.max
	" Output to buffer
	if len(nls) >= 1
		setl cul
		cal sort(nls)
		if s:mwreverse
			cal reverse(nls)
		endif
		cal setline('1', nls[0])
		cal append('1', nls[1:max-1])
		if s:mwreverse
			keepj norm! G
		else
			keepj norm! gg
		endif
		keepj norm! 1|
	else
		" If empty
		setl nocul
		cal setline('1', '== NO MATCHES ==')
	endif
	" Remember selected line
	if exists('g:CtrlP_cline')
		cal setpos('.', [0, g:CtrlP_cline, 1, 0])
	endif
endfunc
"}}}

" s:UpdateMatches() {{{
func! s:UpdateMatches(pat)
	" Delete the buffer's content
	sil! %d _
	let limit = s:mxheight
	let newpat = s:SplitPattern(a:pat)
	let lines = s:GetMatchedItems(s:lines, newpat, limit)
	cal s:Renderer(lines)
	cal s:Highlight(newpat)
endfunc
"}}}

" s:BuildPrompt() {{{
func! s:BuildPrompt(...)
	let base = '>> '
	let cur = '_'
	let start = escape(g:CtrlP_prompt[0], '\')
	let mid = escape(g:CtrlP_prompt[1], '\')
	let end = escape(g:CtrlP_prompt[2], '\')
	" Toggling
	if !exists('a:1') || a:1 == 1
		let hiactive = 'Normal'
		let hibase = 'Comment'
	elseif exists('a:1') || a:1 == 0
		let hiactive = 'Comment'
		let hibase = 'Comment'
	endif
	" Build it
	redraw
	exe 'echohl '.hibase.' | echon "'.base.'"
				\ | echohl '.hiactive.' | echon "'.start.'"
				\ | echohl '.hibase.' | echon "'.mid.'"
				\ | echohl '.hiactive.' | echon "'.end.'"
				\ | echohl None'
	" Append the cursor _ at the end
	if empty(mid) && ( !exists('a:1') || ( exists('a:1') && a:1 == 1 ) )
		exe 'echohl '.hibase.' | echon "'.cur.'" | echohl None'
	endif
	sil! cal s:UpdateMatches(start.mid.end)
endfunc
"}}}

" Actions {{{
func! s:PrtClear()
	let g:CtrlP_prompt = ['','','']
	cal s:BuildPrompt()
endfunc

func! s:PrtAdd(char)
	let g:CtrlP_prompt[0] = g:CtrlP_prompt[0] . a:char
	cal s:BuildPrompt()
endfunc

func! s:PrtBS()
	let str = g:CtrlP_prompt[0]
	let g:CtrlP_prompt[0] = strpart(str, -1, strlen(str))
	cal s:BuildPrompt()
endfunc

func! s:PrtDelete()
	let g:CtrlP_prompt[1] = strpart(g:CtrlP_prompt[2], 0, 1)
	let g:CtrlP_prompt[2] = strpart(g:CtrlP_prompt[2], 1)
	cal s:BuildPrompt()
endfunc

func! s:PrtCurLeft()
	if !empty(g:CtrlP_prompt[0])
		let g:CtrlP_prompt[2] = g:CtrlP_prompt[1] . g:CtrlP_prompt[2]
		let g:CtrlP_prompt[1] = strpart(g:CtrlP_prompt[0], strlen(g:CtrlP_prompt[0]) - 1)
		let g:CtrlP_prompt[0] = strpart(g:CtrlP_prompt[0], -1, strlen(g:CtrlP_prompt[0]))
	endif
	cal s:BuildPrompt()
endfunc

func! s:PrtCurRight()
	let g:CtrlP_prompt[0] = g:CtrlP_prompt[0] . g:CtrlP_prompt[1]
	cal s:PrtDelete()
endfunc

func! s:PrtCurStart()
	let str = g:CtrlP_prompt[0] . g:CtrlP_prompt[1] . g:CtrlP_prompt[2]
	let g:CtrlP_prompt[2] = strpart(str, 1)
	let g:CtrlP_prompt[1] = strpart(str, 0, 1)
	let g:CtrlP_prompt[0] = ''
	cal s:BuildPrompt()
endfunc

func! s:PrtCurEnd()
	let str = g:CtrlP_prompt[0] . g:CtrlP_prompt[1] . g:CtrlP_prompt[2]
	let g:CtrlP_prompt[2] = ''
	let g:CtrlP_prompt[1] = ''
	let g:CtrlP_prompt[0] = str
	cal s:BuildPrompt()
endfunc

func! s:PrtDeleteWord()
	let str = g:CtrlP_prompt[0]
	if match(str, ' [^ ]\+$') >= 0
		let str = matchstr(str, '^.\+ \ze[^ ]\+$')
	elseif match(str, '[ ]\+$') >= 0
		let str = matchstr(str, '^.*[^ ]\+\ze[ ]\+$')
	elseif match(str, ' ') <= 0
		let str = ''
	endif
	let g:CtrlP_prompt[0] = str
	cal s:BuildPrompt()
endfunc

func! s:PrtSelectMove(dir)
	exe 'norm! '.a:dir
	let g:CtrlP_cline = line('.')
endfunc
"}}}

" s:MapKeys() {{{
func! s:MapKeys(...)
	" Normal keystrokes
	let allkeys = range(32,123)
	let allkeys = extend(allkeys, [125,126])
	for each in allkeys
		exe "nn \<buffer> \<silent> \<char-".each."> :cal \<SID>PrtAdd('".nr2char(each)."')\<cr>"
	endfor
	
	" Special keystrokes
	let prtmaps = {
				\ 'PrtBS()': ['<bs>'],
				\ 'PrtDelete()': ['<del>'],
				\ 'PrtDeleteWord()': ['<c-w>'],
				\ 'PrtClear()': ['<c-u>'],
				\ 'PrtSelectMove("j")': ['s', '<c-n>', '<c-j>', '<down>'],
				\ 'PrtSelectMove("k")': ['s', '<c-p>', '<c-k>', '<up>'],
				\ 'AcceptSelection("e")': ['<cr>'],
				\ 'AcceptSelection("h")': ['<c-cr>', '<c-s>'],
				\ 'AcceptSelection("t")': ['<c-t>'],
				\ 'AcceptSelection("v")': ['<c-v>'],
				\ 'ToggleFocus()': ['<tab>'],
				\ 'PrtCurStart()': ['<c-a>'],
				\ 'PrtCurEnd()': ['<c-e>'],
				\ 'PrtCurLeft()': ['<c-h>', '<left>'],
				\ 'PrtCurRight()': ['<c-l>', '<right>'],
				\ 'BufOpen("CtrlP", "del")': ['<esc>', '<c-c>', '<c-g>'],
				\ }
	let maps = prtmaps
	for each in keys(maps)
		for kp in maps[each]
			let sl = ''
			if maps[each][0] == 's'
				let sl = '<silent> '
			endif
			if kp != 's'
				exe 'nn <buffer> '.sl.kp.' :cal <SID>'.each.'<cr>'
			endif
		endfor
	endfor
endfunc
"}}}

"TODO: normal keystrokes jump to first chars
" s:ToggleFocus() {{{
func! s:ToggleFocus()
	if !exists('b:CtrlP_focus') || b:CtrlP_focus == 1
		let b:CtrlP_focus = 0
	elseif !exists('b:CtrlP_focus') || b:CtrlP_focus == 0
		let b:CtrlP_focus = 1
	endif
	cal s:BuildPrompt(b:CtrlP_focus)
endfunc
"}}}

" s:ToggleWin() {{{
func! s:ToggleWin()
	if s:CtrlP_win == 0
		let s:CtrlP_win = 1
	else
		let s:CtrlP_win = 0
	endif
endfunc
"}}}

" s:Highlight() {{{
func! s:Highlight(pat)
	hi link CtrlPKeywords Normal
	if !empty(a:pat)
		exe 'syn match CtrlPKeywords /\c'.a:pat.'/'
		hi link CtrlPKeywords Constant
	endif
endfunc
"}}}

" ctrlp#SetWorkingPath() {{{
func! s:FindRoot(curr, mark)
	if !empty(globpath(a:curr, a:mark))
		sil! exe 'chdir '.a:curr
	else
		let parent = substitute(a:curr, '[\/]\zs[^\/]\+[\/]*$', '', '')
		if parent != a:curr
			sil! cal s:FindRoot(parent, a:mark)
		endif
	endif
endfunc

func! ctrlp#SetWorkingPath()
	if match(expand('%:p'), '^\<.\+\>://.*') >= 0 || s:pathmode == 0 | retu | endif
	if exists('+autochdir')
		set noautochdir
	endif
	sil! exe 'chdir '.fnameescape(expand('%:p:h'))
	if s:pathmode == 1 | retu | endif
	let markers = [
				\ 'root.dir',
				\ '.vimprojects',
				\ '.git/',
				\ '_darcs/',
				\ '.hg/',
				\ '.bzr/',
				\ ]
	for marker in markers
		sil! cal s:FindRoot(getcwd(), marker)
		if getcwd() != expand('%:p:h') | break | endif
	endfor
endfunc
"}}}

" s:AcceptSelection() {{{
func! s:AcceptSelection(mode)
	let md = a:mode
	let line = getline('.')
	let filepath = getcwd().s:lash().matchstr(line, '^> \zs.\+\ze\t*$')
	let filename = split(filepath, s:lash())[-1]
	" Remove the prompt and match window
	sil! cal s:BufOpen('CtrlP', 'del')
	" Setup a new window for the selected entry
	if md == 't' || s:splitwin == 1 " in new tab
		tabnew
		let cmd = 'e'
	elseif md == 'h' || s:splitwin == 2 " in new hor split
		let cmd = 'new'
	elseif md == 'v' || s:splitwin == 3 " in new ver split
		let cmd = 'vne'
	elseif md = 'e' || s:splitwin == 0 " in current window
		let cmd = 'e'
	endif
	let bufnum = bufnr(filename)
	if bufnum > 0 && bufwinnr(bufnum) > 0
		exe bufwinnr(bufnum).'winc w' | exe 'winc c'
	endif
	exe 'bo '.cmd.' '.filepath
	if exists('s:line')
		exe s:line
		norm! 0zz
	endif
endfunc
"}}}

" Helper functions {{{
func! s:lash()
	if &ssl || !exists('+shellslash')
		let slash = '/'
	else
		let slash = '\'
	endif
	retu slash
endfunc

func! s:Syntax()
	syn match CtrlPNoEntries '^== NO MATCHES ==$'
	syn match CtrlPLineMarker '^>'
	hi link CtrlPNoEntries Error
	hi CtrlPLineMarker guifg=bg
endfunc
"}}}

" ctrlp#init() {{{
func! ctrlp#init()
	cal ctrlp#SetWorkingPath()
	let s:lines = s:ListAllFiles(getcwd())
	cal s:BufOpen('CtrlP')
	cal s:SetupBlank('ctrlp')
	cal s:MapKeys()
	cal s:Renderer(s:lines)
	cal s:BuildPrompt()
	cal s:Syntax()
endfunc
"}}}

au BufLeave,WinLeave CtrlP cal s:BufOpen('CtrlP', 'del')

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:fen:fdl=0:ts=2:sw=2:sts=2
