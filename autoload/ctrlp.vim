" =============================================================================
" File:          autoload/ctrlp.vim
" Description:   Full path fuzzy file and buffer finder for Vim.
" Author:        Kien Nguyen <github.com/kien>
" License:       MIT
" =============================================================================

let s:save_cpo = &cpo "{{{
set cpo&vim "}}}

if v:version < '700' "{{{
	func! ctrlp#init(...)
		echoh Error | ec 'CtrlP requires Vim 7.0+' | echoh None
	endfunc
	fini
endif "}}}

" Option variables {{{
if !exists('g:ctrlp_match_window_reversed')
	let s:mwreverse = 1
else
	let s:mwreverse = g:ctrlp_match_window_reversed
	unl g:ctrlp_match_window_reversed
endif

if !exists('g:ctrlp_persistence_input')
	let s:pinput = 1
else
	let s:pinput = g:ctrlp_persistence_input
	unl g:ctrlp_persistence_input
endif

if !exists('g:ctrlp_split_window')
	let s:splitwin = 0
else
	let s:splitwin = g:ctrlp_split_window
	unl g:ctrlp_split_window
endif

if !exists('g:ctrlp_update_delay')
	let s:udelay = 500
else
	let s:udelay = g:ctrlp_update_delay
	unl g:ctrlp_update_delay
endif

if !exists('g:ctrlp_ignore_space')
	let s:igspace = 1
else
	let s:igspace = g:ctrlp_ignore_space
	unl g:ctrlp_ignore_space
endif

if !exists('g:ctrlp_working_path_mode')
	let s:pathmode = 1
else
	let s:pathmode = g:ctrlp_working_path_mode
	unl g:ctrlp_working_path_mode
endif

if !exists('g:ctrlp_max_height')
	let s:mxheight = 10
else
	let s:mxheight = g:ctrlp_max_height
	unl g:ctrlp_max_height
endif

if !exists('g:ctrlp_regexp_search')
	let s:regexp = 0
else
	let s:regexp = g:ctrlp_regexp_search
	unl g:ctrlp_regexp_search
endif

if !exists('g:ctrlp_use_caching')
	let s:caching = 0
else
	let s:caching = g:ctrlp_use_caching
	unl g:ctrlp_use_caching
endif

if !exists('g:ctrlp_cache_dir')
	let s:cache_dir = $HOME
else
	let s:cache_dir = g:ctrlp_cache_dir
	unl g:ctrlp_cache_dir
endif

if !exists('g:ctrlp_newcache')
	let g:ctrlp_newcache = 0
endif

if !exists('g:ctrlp_by_filename')
	let s:byfname = 0
else
	let s:byfname = g:ctrlp_by_filename
	unl g:ctrlp_by_filename
endif
"}}}

" Caching {{{
func! s:GetDataFile(file)
	if filereadable(a:file) | retu readfile(a:file) | endif
endfunc

func! s:CacheDir()
	retu exists('*mkdir') ? s:cache_dir.s:lash().'.ctrlp_cache' : s:cache_dir
endfunc

func! s:CacheFile()
	retu s:CacheDir().s:lash().substitute(getcwd(), '\([\/]\|^\a\zs:\)', '%', 'g').'.txt'
endfunc

func! s:WriteCache(lines)
	let cache_dir = s:CacheDir()
	" create directory if not existed
	if exists('*mkdir') && !isdirectory(cache_dir)
		sil! cal mkdir(cache_dir)
	endif
	" write cache
	if isdirectory(cache_dir)
		sil! cal writefile(a:lines, s:CacheFile())
		let g:ctrlp_newcache = 0
	endif
endfunc

func! ctrlp#clearcache()
	let g:ctrlp_newcache = 1
endfunc

func! ctrlp#clearallcaches()
	let cache_dir = s:CacheDir()
	if isdirectory(cache_dir) && match(cache_dir, '.ctrlp_cache') >= 0
		let cache_files = split(globpath(cache_dir, '*.txt'), '\n')
		try
			for each in cache_files | cal delete(each) | endfor
		catch
			echoh Error | ec 'Can''t delete cache files' | echoh None
		endtry
	else
		echoh Error | ec 'Caching directory not found. Nothing to delete.' | echoh None
	endif
	cal ctrlp#clearcache()
endfunc
"}}}

func! s:ListAllFiles(path) "{{{
	let cache_file = s:CacheFile()
	if g:ctrlp_newcache || !filereadable(cache_file) || s:caching == 0
		let allfiles = split(globpath(a:path, '**'), '\n')
		cal filter(allfiles, '!isdirectory(v:val)')
		" filter all entries matched wildignore's patterns (in addition to globpath's)
		if exists('+wig') && !empty(&wig)
			let ignores = map(split(&wig, ','), 'substitute(v:val, "\\W\\+", ".*", "g")')
			cal filter(allfiles, 's:matchlists(v:val, "'.string(ignores).'")')
		endif
		" remove base directory
		let path = &ssl || !exists('+ssl') ? getcwd().'/' : substitute(getcwd(), '\', '\\\\\\\\', 'g').'\\\\'
		cal map(allfiles, 'substitute(v:val, "'.path.'", "", "g")')
	else
		let allfiles = s:GetDataFile(cache_file)
	endif
	if len(allfiles) <= 3000 | cal sort(allfiles, 's:compare') | endif
	" write cache
	if ( g:ctrlp_newcache || !filereadable(cache_file) ) && s:caching
				\ || len(allfiles) > 4000
		if len(allfiles) > 4000 | let s:caching = 1 | endif
		cal s:WriteCache(allfiles)
	endif
	retu allfiles
endfunc "}}}

func! s:ListAllBuffers() "{{{
	let nbufs = bufnr('$')
	let allbufs = []
	for each in range(1, nbufs)
		if getbufvar(each, '&bl')
			let bufname = bufname(each)
			if strlen(bufname) && getbufvar(each, '&ma') && bufname != 'ControlP'
				cal add(allbufs, fnamemodify(bufname, ':p'))
			endif
		endif
	endfor
	retu allbufs
endfunc "}}}

func! s:SplitPattern(str,...) "{{{
	" Split into a list, ignoring spaces
	if s:igspace
		let str = substitute(a:str, ' ', '', 'g')
	endif
	if s:regexp || match(str, '[*^$+|]') >= 0
				\ || match(str, '\\\(zs\|ze\|<\|>\)') >= 0
		let str = substitute(str, '\\\\', '\', 'g')
		let array = [str]
		if match(str, ':\d*$') >= 0 " If pattern contains :\d (e.g. abc:25)
			let s:line = matchstr(str, ':\d*$')
			let array[0] = substitute(array[0], ':\d*$', '', 'g')
		endif
	elseif match(str, ':\d*$') >= 0 " If string contains :\d
		let tmp = split(str, ':\ze\d*$')
		let array = split(tmp[0], '\zs')
		if len(tmp) >= 2
			cal add(array, ':'.tmp[1])
		endif
	else
		let array = split(str, '\zs')
	endif
	" Build the new pattern
	let nitem = !empty(array) ? array[0] : ''
	let newpats = [nitem]
	if len(array) > 1
		for i in range(1, len(array) - 1)
			" Separator
			let sp = exists('a:1') ? a:1 : '.*'
			let nitem .= sp.array[i]
			cal add(newpats, nitem)
		endfor
	endif
	retu newpats
endfunc "}}}

func! s:GetMatchedItems(items, pats, limit) "{{{
	let items = a:items
	let pats = a:pats
	let limit = a:limit
	" if pattern contains line number
	if match(pats[-1], ':\d*$') >= 0
		if exists('s:line') | unl s:line | endif
		let s:line = substitute(pats[-1], '.*\ze:\d*$', '', 'g')
		cal remove(pats, -1)
	endif
	" if items is longer than 2000, use only the last pattern
	if len(items) >= 2000
		let pats = [pats[-1]]
	endif
	" loop through the patterns
	for each in pats
		if exists('newitems') && len(newitems) < limit
			let items = newitems
		endif
		if empty(items)
			retu newitems
		else
			let newitems = []
			" loop through the items
			for item in items
				if s:byfname
					if s:matchsubstr(item, each) >= 0 | cal add(newitems, item) | endif
				else
					if match(item, each) >= 0 | cal add(newitems, item) | endif
				endif
				" stop if reached the limit
				if a:limit > 0 && len(newitems) == limit | break | endif
			endfor
		endif
	endfor
	retu newitems
endfunc "}}}

func! s:SetupBlank(name) "{{{
	exe 'setl ft='.a:name
	setl bt=nofile
	setl bh=delete
	setl noswf
	setl nobl
	setl ts=4
	setl sw=4
	setl sts=4
	setl nonu
	setl nowrap
	setl nolist
	setl nospell
	setl cul
	setl nocuc
	setl tw=0
	setl wfw
	if v:version >= '703'
		setl nornu
		setl noudf
		setl cc=0
	endif
endfunc "}}}

func! s:BufOpen(...) "{{{
	" a:1 bufname; a:2 delete
	let buf = a:1
	let bufnum = bufnr(buf)
	" Closing
	if bufnum > 0 && bufwinnr(bufnum) > 0
		exe bufwinnr(bufnum).'winc w'
		exe 'winc c'
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
		exe s:currwin.'winc w'
		ec
	else
		let s:currwin = winnr()
		" Open new buffer
		exe 'sil! botright 1new' buf
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
endfunc "}}}

func! s:Renderer(lines) "{{{
	let nls = []
	for i in range(0, len(a:lines) - 1)
		let nls = add(nls, '> '.a:lines[i])
	endfor
	" Detemine/set max height
	let height = s:mxheight
	let max = len(nls) < height ? len(nls) : height
	exe 'res' max
	" Output to buffer
	if len(nls) >= 1
		setl cul
		cal sort(nls, 's:compare')
		if s:mwreverse
			cal reverse(nls)
		endif
		cal setline('1', nls)
		if s:mwreverse
			keepj norm! G
		else
			keepj norm! gg
		endif
		keepj norm! 1|
		let b:matched = nls
	else
		" If empty
		setl nocul
		cal setline('1', '== NO MATCHES ==')
	endif
	" Remember selected line
	if exists('g:CtrlP_cline')
		cal setpos('.', [0, g:CtrlP_cline, 1, 0])
	endif
endfunc "}}}

func! s:UpdateMatches(pat) "{{{
	" Delete the buffer's content
	sil! %d _
	let newpat = s:SplitPattern(a:pat)
	let lines = s:GetMatchedItems(s:lines, newpat, s:mxheight)
	cal s:Renderer(lines)
	cal s:Highlight(newpat)
endfunc "}}}

func! s:BuildPrompt(...) "{{{
	let base1 = s:regexp ? 'r' : '>'
	let base2 = s:byfname ? 'd' : '>'
	let base  = base1.base2.'> '
	let cur   = '_'
	let estr  = '"\'
	let start = escape(g:CtrlP_prompt[0], estr)
	let mid   = escape(g:CtrlP_prompt[1], estr)
	let end   = escape(g:CtrlP_prompt[2], estr)
	" Toggling
	if !exists('a:1') || a:1
		let hiactive = 'Normal'
	elseif exists('a:1') || a:1 == 0
		let hiactive = 'Comment'
		let base = substitute(base, '>', '-', 'g')
	endif
	let hibase = 'Comment'
	" Build it
	redr
	exe 'echohl' hibase '| echon "'.base.'"
				\ | echohl' hiactive '| echon "'.start.'"
				\ | echohl' hibase '| echon "'.mid.'"
				\ | echohl' hiactive '| echon "'.end.'"
				\ | echohl None'
	" Append the cursor _ at the end
	if empty(mid) && ( !exists('a:1') || ( exists('a:1') && a:1 ) )
		exe 'echohl' hibase '| echon "'.cur.'" | echohl None'
	endif
	sil! cal s:UpdateMatches(start.mid.end)
endfunc "}}}

" Prt Actions {{{
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
	exe 'keepj norm!' a:dir
	let g:CtrlP_cline = line('.')
endfunc
"}}}

" s:MapKeys() && s:MapSpecs() {{{
func! s:MapKeys(...)
	" Normal keystrokes
	let func = !exists('a:1') || ( exists('a:1') && a:1 ) ? 'PrtAdd' : 'SelectJump'
	let sjbyfname = s:byfname && func == 'SelectJump' ? ', 1' : ''
	for each in range(32,126)
		sil! exe "nn \<buffer> \<silent> \<char-".each."> :cal \<SID>".func."(\"".escape(nr2char(each), '"|\')."\"".sjbyfname.")\<cr>"
	endfor
	if exists('a:2') | retu | endif
	" Special keystrokes
	if exists('a:1') && a:1 == 0
		sil! cal s:MapSpecs('unmap')
	else
		sil! cal s:MapSpecs()
	endif
endfunc

func! s:MapSpecs(...)
	let prtmaps = {
				\ 'PrtBS()':                    ['<bs>'],
				\ 'PrtDelete()':                ['<del>'],
				\ 'PrtDeleteWord()':            ['<c-w>'],
				\ 'PrtClear()':                 ['<c-u>'],
				\ 'PrtSelectMove("j")':         ['<c-n>', '<c-j>', '<down>'],
				\ 'PrtSelectMove("k")':         ['<c-p>', '<c-k>', '<up>'],
				\ 'AcceptSelection("e")':       ['<cr>'],
				\ 'AcceptSelection("h")':       ['<c-cr>', '<c-s>'],
				\ 'AcceptSelection("t")':       ['<c-t>'],
				\ 'AcceptSelection("v")':       ['<c-v>'],
				\ 'ToggleFocus()':              ['<tab>'],
				\ 'ToggleRegex()':              ['<c-r>'],
				\ 'ToggleByFname()':            ['<c-d>'],
				\ 'ToggleType()':               ['<c-f>'],
				\ 'PrtCurStart()':              ['<c-a>'],
				\ 'PrtCurEnd()':                ['<c-e>'],
				\ 'PrtCurLeft()':               ['<c-h>', '<left>'],
				\ 'PrtCurRight()':              ['<c-l>', '<right>'],
				\ 'BufOpen("ControlP", "del")': ['<esc>', '<c-c>', '<c-g>'],
				\ }
	if exists('g:ctrlp_prompt_mappings') && type(g:ctrlp_prompt_mappings) == 4
		sil! cal extend(prtmaps, g:ctrlp_prompt_mappings)
	endif
	if exists('a:1') && a:1 == 'unmap'
		let prtunmaps = [
					\ 'PrtBS()',
					\ 'PrtDelete()',
					\ 'PrtDeleteWord()',
					\ 'PrtClear()',
					\ 'PrtCurStart()',
					\ 'PrtCurEnd()',
					\ 'PrtCurLeft()',
					\ 'PrtCurRight()',
					\ ]
		for each in prtunmaps | for kp in prtmaps[each]
			sil! exe 'nn <buffer> <silent>' kp '<Nop>'
		endfor | endfor
	else
		for each in keys(prtmaps) | for kp in prtmaps[each]
			sil! exe 'nn <buffer> <silent>' kp ':cal <SID>'.each.'<cr>'
		endfor | endfor
	endif
endfunc
"}}}

" s:ToggleFocus() && s:Focus() {{{
func! s:Focus()
	retu !exists('b:focus') ? 1 : b:focus
endfunc

func! s:ToggleFocus()
	let b:focus = !exists('b:focus') || b:focus ? 0 : 1
	cal s:MapKeys(b:focus)
	cal s:BuildPrompt(b:focus)
endfunc
"}}}

"Mightdo: Cycle through matches. /medium
func! s:SelectJump(char,...) "{{{
	let lines = map(b:matched, 'substitute(v:val, "^> ", "", "g")')
	if exists('a:1')
		let lines = map(lines, 'split(v:val, ''[\/]\ze[^\/]\+$'')[-1]')
	endif
	if match(lines, '\c^'.a:char) >= 0
		exe match(lines, '\c^'.a:char) + 1
		let g:CtrlP_cline = line('.')
	endif
endfunc "}}}

func! s:ToggleRegex() "{{{
	let s:regexp = s:regexp ? 0 : 1
	cal s:BuildPrompt(s:Focus())
endfunc "}}}

func! s:ToggleByFname() "{{{
	let s:byfname = s:byfname ? 0 : 1
	cal s:MapKeys(s:Focus(), 1)
	cal s:BuildPrompt(s:Focus())
endfunc "}}}

func! s:ToggleType() "{{{
	let s:itemtype = s:itemtype ? 0 : 1
	cal s:SetLines(s:itemtype)
	cal s:BuildPrompt(s:Focus())
endfunc "}}}

"Mightdo: Highlight matched characters/strings. /low
func! s:Highlight(pat) "{{{
	hi link CtrlPKeywords Normal
	if !empty(a:pat)
		exe 'syn match CtrlPKeywords /\c'.a:pat.'/'
		hi link CtrlPKeywords Constant
	endif
endfunc "}}}

" ctrlp#SetWorkingPath(...) {{{
func! s:FindRoot(curr, mark)
	if !empty(globpath(a:curr, a:mark))
		sil! exe 'chdir' a:curr
	else
		let parent = substitute(a:curr, '[\/]\zs[^\/]\+[\/]*$', '', '')
		if parent != a:curr
			sil! cal s:FindRoot(parent, a:mark)
		endif
	endif
endfunc

func! ctrlp#SetWorkingPath(...)
	let l:pathmode = 2
	if exists('a:1')
		let l:pathmode = a:1
	endif
	if match(expand('%:p'), '^\<.\+\>://.*') >= 0
				\ || s:pathmode == 0 || l:pathmode == 0
		retu
	endif
	if exists('+acd')
		se noacd
	endif
	sil! exe 'chdir' fnameescape(expand('%:p:h'))
	if s:pathmode || l:pathmode | retu | endif
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

func! s:AcceptSelection(mode) "{{{
	let md = a:mode
	let matchstr = matchstr(getline('.'), '^> \zs.\+\ze\t*$')
	let filepath = s:itemtype ? matchstr : getcwd().s:lash().matchstr
	let filename = split(filepath, s:lash())[-1]
	" Remove the prompt and match window
	sil! cal s:BufOpen('ControlP', 'del')
	" Setup a new window for the selected entry
	if md == 't' || s:splitwin == 1 " in new tab
		tabnew
		let cmd = 'e'
	elseif md == 'h' || s:splitwin == 2 " in new hor split
		let cmd = 'new'
	elseif md == 'v' || s:splitwin == 3 " in new ver split
		let cmd = 'vne'
	elseif md == 'e' || s:splitwin == 0 " in current window
		let cmd = 'e'
	endif
	let bufnum = bufnr(filename)
	if bufnum > 0 && bufwinnr(bufnum) > 0
		exe 'b' bufnum
	else
		exe 'bo '.cmd.' '.filepath
	endif
	if exists('s:line')
		exe s:line
		keepj norm! 0zz
	endif
	ec
endfunc "}}}

"Mightdo: Further customizing s:compare(). Sort by file type. /low
" Helper functions {{{
func! s:compare(s1, s2)
	" by length
	let str1 = strlen(a:s1)
	let str2 = strlen(a:s2)
	retu str1 == str2 ? 0 : str1 > str2 ? 1 : -1
endfunc

func! s:matchsubstr(item, pat)
	retu match(split(a:item, '[\/]\ze[^\/]\+$')[-1], a:pat)
endfunc

func! s:matchlists(item, lst)
	for each in eval(a:lst)
		if match(a:item, each) >= 0 | retu 0 | endif
	endfor
	retu 1
endfunc

func! s:lash()
	retu &ssl || !exists('+ssl') ? '/' : '\'
endfunc

func! s:Syntax()
	syn match CtrlPNoEntries '^== NO MATCHES ==$'
	syn match CtrlPLineMarker '^>'
	hi link CtrlPNoEntries Error
	hi CtrlPLineMarker guifg=bg
endfunc
"}}}

" Initialization {{{
func! s:SetLines(type)
	let s:itemtype = a:type
	let s:lines = s:itemtype ? s:ListAllBuffers() : s:ListAllFiles(getcwd())
endfunc

func! ctrlp#init(type)
	cal ctrlp#SetWorkingPath()
	cal s:SetLines(a:type)
	cal s:BufOpen('ControlP')
	cal s:SetupBlank('ctrlp')
	cal s:MapKeys()
	cal s:Renderer(s:lines)
	cal s:BuildPrompt()
	cal s:Syntax()
endfunc
"}}}

aug CtrlPAug "{{{
	au!
	au BufLeave,WinLeave ControlP cal s:BufOpen('ControlP', 'del')
aug END "}}}

let &cpo = s:save_cpo "{{{
unl s:save_cpo "}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
