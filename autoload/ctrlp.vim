" =============================================================================
" File:          autoload/ctrlp.vim
" Description:   Full path fuzzy file, buffer and MRU file finder for Vim
" Author:        Kien Nguyen <github.com/kien>
" Version:       1.5.9
" =============================================================================

" Static variables {{{
fu! s:opts()
	let opts = {
		\ 'g:ctrlp_by_filename':           ['s:byfname', 0],
		\ 'g:ctrlp_clear_cache_on_exit':   ['s:cconex', 1],
		\ 'g:ctrlp_dotfiles':              ['s:dotfiles', 1],
		\ 'g:ctrlp_extensions':            ['s:extensions', []],
		\ 'g:ctrlp_highlight_match':       ['s:mathi', [1, 'Identifier']],
		\ 'g:ctrlp_jump_to_buffer':        ['s:jmptobuf', 1],
		\ 'g:ctrlp_match_window_bottom':   ['s:mwbottom', 1],
		\ 'g:ctrlp_match_window_reversed': ['s:mwreverse', 1],
		\ 'g:ctrlp_max_depth':             ['s:maxdepth', 40],
		\ 'g:ctrlp_max_files':             ['s:maxfiles', 20000],
		\ 'g:ctrlp_max_height':            ['s:mxheight', 10],
		\ 'g:ctrlp_open_multi':            ['s:opmul', 1],
		\ 'g:ctrlp_open_new_file':         ['s:newfop', 3],
		\ 'g:ctrlp_prompt_mappings':       ['s:urprtmaps', 0],
		\ 'g:ctrlp_regexp_search':         ['s:regexp', 0],
		\ 'g:ctrlp_root_markers':          ['s:rmarkers', []],
		\ 'g:ctrlp_split_window':          ['s:splitwin', 0],
		\ 'g:ctrlp_use_caching':           ['s:caching', 1],
		\ 'g:ctrlp_working_path_mode':     ['s:pathmode', 2],
		\ }
	for key in keys(opts)
		let def = string(exists(key) ? eval(key) : opts[key][1])
		exe 'let' opts[key][0] '=' def '|' 'unl!' key
	endfo
	if !exists('g:ctrlp_newcache')     | let g:ctrlp_newcache = 0      | en
	if !exists('g:ctrlp_user_command') | let g:ctrlp_user_command = '' | en
	let s:maxhst = exists('g:ctrlp_max_history') ? g:ctrlp_max_history
		\ : exists('+hi') ? &hi : 20
	unl! g:ctrlp_max_history
	" Note: wildignore is ignored when using **
	let s:glob      = s:dotfiles ? '.*\|*' : '*'
	let s:cache_dir = exists('g:ctrlp_cache_dir') ? g:ctrlp_cache_dir : $HOME
	let s:maxdepth  = min([s:maxdepth, 100])
	let s:mru       = g:ctrlp_mru_files
	let g:ctrlp_builtins = s:mru + 1
	if !empty(s:extensions) | for each in s:extensions
		exe 'ru autoload/ctrlp/'.each.'.vim'
	endfo | en
endf
cal s:opts()

let s:lash = ctrlp#utils#lash()

" Global options
let s:glbs = { 'magic': 1, 'to': 1, 'tm': 0, 'sb': 1, 'hls': 0,
	\ 'im': 0, 'report': 9999, 'sc': 0, 'ss': 0, 'siso': 0,
	\ 'mfd': 200, 'gcr': 'a:block-PmenuSel-blinkon0', 'mouse': 'n' }

" Limiters
let [s:compare_lim, s:nocache_lim, s:mltipats_lim] = [3000, 4000, 2000]
"}}}
" * Open & Close {{{
fu! s:Open()
	let s:winres = winrestcmd()
	sil! exe s:mwbottom ? 'bo' : 'to' '1new ControlP'
	let s:currwin = s:mwbottom ? winnr('#') : winnr('#') + 1
	let [s:winnr, s:bufnr, s:prompt] = [bufwinnr('%'), bufnr('%'), ['', '', '']]
	abc <buffer>
	if !exists('s:hstry')
		let hst = filereadable(s:gethistloc()[1]) ? s:gethistdata() : ['']
		let s:hstry = empty(hst) || !s:maxhst ? [''] : hst
	en
	for key in keys(s:glbs)
		sil! exe 'let s:glb_'.key.' = &'.key.' | let &'.key.' = '.string(s:glbs[key])
	endfo
	if s:opmul && has('signs')
		sign define ctrlpmark text=+> texthl=Search
	en
	cal s:setupblank()
endf

fu! s:Close()
	try | bun! | cat | clo! | endt
	cal s:unmarksigns()
	for key in keys(s:glbs)
		sil! exe 'let &'.key.' = s:glb_'.key
	endfo
	if exists('s:glb_acd') | let &acd = s:glb_acd | en
	let [g:ctrlp_lines, g:ctrlp_allfiles] = [[], []]
	sil! exe 'chd!' s:cwd
	exe s:winres
	unl! s:focus s:hisidx s:hstgot s:marked s:winnr s:statypes s:cline s:cwd
		\ s:init s:savestr s:winres
	cal s:recordhist(join(s:prompt, ''))
	ec
endf
"}}}
" * Clear caches {{{
fu! ctrlp#clearcache()
	let g:ctrlp_newcache = 1
endf

fu! ctrlp#clearallcaches()
	let cache_dir = ctrlp#utils#cachedir()
	if isdirectory(cache_dir) && match(cache_dir, '.ctrlp_cache') >= 0
		let cache_files = split(globpath(cache_dir, '*.txt'), '\n')
		cal filter(cache_files, '!isdirectory(v:val)')
		sil! cal map(cache_files, 'delete(v:val)')
	en
	cal ctrlp#clearcache()
endf

fu! ctrlp#reset()
	cal s:opts()
	cal ctrlp#utils#opts()
	if s:mru | cal ctrlp#mrufiles#opts() | en
	let s:prompt = ['', '', '']
	unl! s:cline
endf
"}}}
" * Files() {{{
fu! s:GlobPath(dirs, allfiles, depth)
	let entries = split(globpath(a:dirs, s:glob), '\n')
	let entries = filter(entries, 'getftype(v:val) != "link"')
	let g:ctrlp_allfiles = filter(copy(entries), '!isdirectory(v:val)')
	let ftrfunc = s:dotfiles ? 's:dirfilter(v:val)' : 'isdirectory(v:val)'
	let alldirs = filter(entries, ftrfunc)
	cal extend(g:ctrlp_allfiles, a:allfiles, 0)
	let depth = a:depth + 1
	if !empty(alldirs) && !s:maxfiles(len(g:ctrlp_allfiles)) && depth <= s:maxdepth
		sil! cal s:progress(len(g:ctrlp_allfiles))
		cal s:GlobPath(join(alldirs, ','), g:ctrlp_allfiles, depth)
	en
endf

fu! s:UserCommand(path, lscmd)
	let path = a:path
	if exists('+ssl') && &ssl
		let [ssl, &ssl, path] = [&ssl, 0, tr(path, '/', '\')]
	en
	let path = exists('*shellescape') ? shellescape(path) : path
	let g:ctrlp_allfiles = split(system(printf(a:lscmd, path)), '\n')
	if exists('+ssl') && exists('ssl')
		let &ssl = ssl
		cal map(g:ctrlp_allfiles, 'tr(v:val, "\\", "/")')
	en
	if exists('s:vcscmd') && s:vcscmd
		cal map(g:ctrlp_allfiles, 'tr(v:val, "/", "\\")')
	en
endf

fu! s:Files(path)
	let cache_file = ctrlp#utils#cachefile()
	if g:ctrlp_newcache || !filereadable(cache_file) || !s:caching
		let lscmd = s:lscommand()
		" Get the list of files
		if empty(lscmd)
			cal s:GlobPath(a:path, [], 0)
		el
			sil! cal s:progress('Waiting...')
			try | cal s:UserCommand(a:path, lscmd) | cat | retu [] | endt
		en
		" Remove base directory
		let path = &ssl || !exists('+ssl') ? getcwd().'/' :
			\ substitute(getcwd(), '\\', '\\\\', 'g').'\\'
		cal map(g:ctrlp_allfiles, 'substitute(v:val, path, "", "g")')
		let read_cache = 0
	el
		let g:ctrlp_allfiles = ctrlp#utils#readfile(cache_file)
		let read_cache = 1
	en
	if len(g:ctrlp_allfiles) <= s:compare_lim
		cal sort(g:ctrlp_allfiles, 's:complen')
	en
	cal s:writecache(read_cache, cache_file)
	retu g:ctrlp_allfiles
endf
"}}}
fu! s:Buffers() "{{{
	let allbufs = []
	for each in range(1, bufnr('$'))
		if getbufvar(each, '&bl')
			let bufname = bufname(each)
			if strlen(bufname) && getbufvar(each, '&ma') && bufname != 'ControlP'
				cal add(allbufs, fnamemodify(bufname, ':p'))
			en
		en
	endfo
	retu allbufs
endf "}}}
" * MatchedItems() {{{
fu! s:MatchIt(items, pat, limit)
	let [items, pat, limit, newitems] = [a:items, a:pat, a:limit, []]
	let mfunc = s:byfname ? 's:matchsubstr' : 'match'
	for item in items
		if call(mfunc, [item, pat]) >= 0 | cal add(newitems, item) | en
		if limit > 0 && len(newitems) >= limit | brea | en
	endfo
	retu newitems
endf

fu! s:MatchedItems(items, pats, limit)
	let [items, pats, limit] = [a:items, a:pats, a:limit]
	" If items is longer than s:mltipats_lim, use only the last pattern
	if len(items) >= s:mltipats_lim | let pats = [pats[-1]] | en
	cal map(pats, 'substitute(v:val, "\\\~", "\\\\\\~", "g")')
	" Loop through the patterns
	for each in pats
		" If newitems is small, set it as items to search in
		if exists('newitems') && len(newitems) < limit
			let items = copy(newitems)
		en
		if !s:regexp | let each = escape(each, '.') | en
		if empty(items) " End here
			retu exists('newitems') ? newitems : []
		el " Start here, go back up if have 2 or more in pats
			" Loop through the items
			let newitems = s:MatchIt(items, each, limit)
		en
	endfo
	let s:matches = len(newitems)
	retu newitems
endf
"}}}
fu! s:SplitPattern(str,...) "{{{
	let str = s:sanstail(a:str)
	let s:savestr = str
	if s:regexp || match(str, '\\\(zs\|ze\|<\|>\)\|[*|]') >= 0
		let array = [s:regexfilter(str)]
	el
		let array = split(str, '\zs')
		if exists('+ssl') && !&ssl
			cal map(array, 'substitute(v:val, "\\", "\\\\\\", "g")')
		en
		" Literal ^ and $
		for each in ['^', '$']
			cal map(array, 'substitute(v:val, "\\\'.each.'", "\\\\\\'.each.'", "g")')
		endfo
	en
	" Build the new pattern
	let nitem = !empty(array) ? array[0] : ''
	let newpats = [nitem]
	if len(array) > 1
		for i in range(1, len(array) - 1)
			" Separator
			let sep = exists('a:1') ? a:1 : '[^'.array[i-1].']\{-}'
			let nitem .= sep.array[i]
			cal add(newpats, nitem)
		endfo
	en
	retu newpats
endf "}}}
" * BuildPrompt() {{{
fu! s:Render(lines, pat)
	let lines = a:lines
	" Setup the match window
	sil! exe '%d _ | res' min([len(lines), s:mxheight])
	" Print the new items
	if empty(lines)
		setl nocul
		cal setline(1, ' == NO MATCHES ==')
		cal s:unmarksigns()
	el
		setl cul
		" Sort if not MRU
		if ( s:mru && s:itemtype != 2 ) || !s:mru
			let s:compat = a:pat
			cal sort(lines, 's:mixedsort')
			unl s:compat
		en
		if s:mwreverse | cal reverse(lines) | en
		let s:matched = copy(lines)
		cal map(lines, 'substitute(v:val, "^", "> ", "")')
		cal setline(1, lines)
		exe 'keepj norm!' s:mwreverse ? 'G' : 'gg'
		keepj norm! 1|
		cal s:unmarksigns()
		cal s:remarksigns()
	en
	if exists('s:cline') | cal cursor(s:cline, 1) | en
	" Highlighting
	if type(s:mathi) == 3 && len(s:mathi) == 2 && s:mathi[0]
		\ && exists('*clearmatches') && !empty(lines)
		let grp = empty(s:mathi[1]) ? 'Identifier' : s:mathi[1]
		cal s:highlight(a:pat, grp)
	en
endf

fu! s:Update(pat,...)
	let pat = a:pat
	" Get the previous string if existed
	let oldstr = exists('s:savestr') ? s:savestr : ''
	let pats = s:SplitPattern(pat)
	" Get the new string sans tail
	let notail = substitute(pat, ':\([^:]\|\\:\)*$', '', 'g')
	" Stop if the string's unchanged
	if notail == oldstr && !empty(notail) && !exists('a:1') && !exists('s:force')
		retu
	en
	let lines = s:MatchedItems(g:ctrlp_lines, pats, s:mxheight)
	let pat = pats[-1]
	cal s:Render(lines, pat)
endf

fu! s:BuildPrompt(upd,...)
	let base = ( s:regexp ? 'r' : '>' ).( s:byfname ? 'd' : '>' ).'> '
	let [estr, prt] = ['"\', copy(s:prompt)]
	cal map(prt, 'escape(v:val, estr)')
	let str = join(prt, '')
	if a:upd && ( s:matches || s:regexp || match(str, '[*|]') >= 0 )
		sil! cal call('s:Update', exists('a:2') ? [str, a:2] : [str])
	en
	sil! cal s:statusline()
	" Toggling
	let [hiactive, hicursor, base] = exists('a:1') && !a:1
		\ ? ['Comment', 'Comment', tr(base, '>', '-')]
		\ : ['Normal', 'Constant', base]
	let hibase = 'Comment'
	" Build it
	redr
	exe 'echoh' hibase '| echon "'.base.'"
		\ | echoh' hiactive '| echon "'.prt[0].'"
		\ | echoh' hicursor '| echon "'.prt[1].'"
		\ | echoh' hiactive '| echon "'.prt[2].'" | echoh None'
	" Append the cursor at the end
	if empty(prt[1]) && ( !exists('a:1') || ( exists('a:1') && a:1 ) )
		exe 'echoh' hibase '| echon "_" | echoh None'
	en
endf
"}}}
" ** Prt Actions {{{
" Editing {{{
fu! s:PrtClear()
	unl! s:hstgot
	let [s:prompt, s:matches] = [['', '', ''], 1]
	cal s:BuildPrompt(1)
endf

fu! s:PrtAdd(char)
	unl! s:hstgot
	let s:prompt[0] = s:prompt[0] . a:char
	cal s:BuildPrompt(1)
endf

fu! s:PrtBS()
	unl! s:hstgot
	let [prt, s:matches] = [s:prompt, 1]
	let prt[0] = strpart(prt[0], -1, strlen(prt[0]))
	cal s:BuildPrompt(1)
endf

fu! s:PrtDelete()
	unl! s:hstgot
	let [prt, s:matches] = [s:prompt, 1]
	let prt[1] = strpart(prt[2], 0, 1)
	let prt[2] = strpart(prt[2], 1)
	cal s:BuildPrompt(1)
endf

fu! s:PrtDeleteWord()
	unl! s:hstgot
	let [str, s:matches] = [s:prompt[0], 1]
	if match(str, '\W\w\+$') >= 0
		let str = matchstr(str, '^.\+\W\ze\w\+$')
	elsei match(str, '\w\W\+$') >= 0
		let str = matchstr(str, '^.\+\w\ze\W\+$')
	elsei match(str, '[ ]\+$') >= 0
		let str = matchstr(str, '^.*[^ ]\+\ze[ ]\+$')
	elsei match(str, ' ') <= 0
		let str = ''
	en
	let s:prompt[0] = str
	cal s:BuildPrompt(1)
endf
"}}}
" Movement {{{
fu! s:PrtCurLeft()
	if !empty(s:prompt[0])
		let prt = s:prompt
		let prt[2] = prt[1] . prt[2]
		let prt[1] = strpart(prt[0], strlen(prt[0]) - 1)
		let prt[0] = strpart(prt[0], -1, strlen(prt[0]))
	en
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurRight()
	let prt = s:prompt
	let prt[0] = prt[0] . prt[1]
	let prt[1] = strpart(prt[2], 0, 1)
	let prt[2] = strpart(prt[2], 1)
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurStart()
	let prt = s:prompt
	let str = join(prt, '')
	let [prt[0], prt[1], prt[2]] = ['', strpart(str, 0, 1), strpart(str, 1)]
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurEnd()
	let prt = s:prompt
	let str = join(prt, '')
	let [prt[0], prt[1], prt[2]] = [str, '', '']
	cal s:BuildPrompt(0)
endf

fu! s:PrtSelectMove(dir)
	exe 'norm!' a:dir
	let s:cline = line('.')
endf

fu! s:PrtSelectJump(char,...)
	let lines = copy(s:matched)
	if exists('a:1')
		cal map(lines, 'split(v:val, ''[\/]\ze[^\/]\+$'')[-1]')
	en
	" Cycle through matches, use s:jmpchr to store last jump
	let chr = escape(a:char, '.~')
	if match(lines, '\c^'.chr) >= 0
		" If not exists or does but not for the same char
		let pos = match(lines, '\c^'.chr)
		if !exists('s:jmpchr') || ( exists('s:jmpchr') && s:jmpchr[0] != chr )
			let [jmpln, s:jmpchr] = [pos, [chr, pos]]
		elsei exists('s:jmpchr') && s:jmpchr[0] == chr
			" Start of lines
			if s:jmpchr[1] == -1 | let s:jmpchr[1] = pos | en
			let npos = match(lines, '\c^'.chr, s:jmpchr[1] + 1)
			let [jmpln, s:jmpchr] = [npos == -1 ? pos : npos, [chr, npos]]
		en
		keepj exe jmpln + 1
		let s:cline = line('.')
	en
endf
"}}}
" Hooks {{{
fu! s:PrtClearCache()
	let s:force = 1
	if s:itemtype == 0
		cal ctrlp#clearcache()
		cal s:SetLines(s:itemtype)
		cal s:BuildPrompt(1)
	elsei s:mru && s:itemtype == 2
		let g:ctrlp_lines = ctrlp#mrufiles#list(-1, 1)
		cal s:BuildPrompt(1)
	en
	unl s:force
endf

fu! s:PrtExit()
	if !has('autocmd') | cal s:Close() | en
	exe s:currwin.'winc w'
endf

fu! s:PrtHistory(...)
	if !s:maxhst | retu | en
	let [str, hst, s:matches] = [join(s:prompt, ''), s:hstry, 1]
	" Save to history if not saved before
	let [hst[0], hslen] = [exists('s:hstgot') ? hst[0] : str, len(hst)]
	let idx = exists('s:hisidx') ? s:hisidx + a:1 : a:1
	" Limit idx within 0 and hslen
	let idx = idx < 0 ? 0 : idx >= hslen ? hslen > 1 ? hslen - 1 : 0 : idx
	let s:prompt = [hst[idx], '', '']
	let [s:hisidx, s:hstgot] = [idx, 1]
	cal s:BuildPrompt(1)
endf
"}}}
"}}}
" * MapKeys() {{{
fu! s:MapKeys(...)
	" Normal keys
	let pfunc = exists('a:1') && !a:1 ? 'PrtSelectJump' : 'PrtAdd'
	let dojmp = s:byfname && pfunc == 'PrtSelectJump' ? ', 1' : ''
	for each in range(32,126)
		let cmd = "nn \<buffer> \<silent> \<char-%d> :\<c-u>cal \<SID>%s(\"%s\"%s)\<cr>"
		exe printf(cmd, each, pfunc, escape(nr2char(each), '"|\'), dojmp)
	endfo
	if exists('a:2') | retu | en
	" Special keys
	cal call('s:MapSpecs', exists('a:1') && !a:1 ? [1] : [])
endf

fu! s:MapSpecs(...)
	let [lcmap, prtmaps] = ['nn <buffer> <silent>', {
		\ 'PrtBS()':              ['<bs>'],
		\ 'PrtDelete()':          ['<del>'],
		\ 'PrtDeleteWord()':      ['<c-w>'],
		\ 'PrtClear()':           ['<c-u>'],
		\ 'PrtSelectMove("j")':   ['<c-j>', '<down>'],
		\ 'PrtSelectMove("k")':   ['<c-k>', '<up>'],
		\ 'PrtHistory(-1)':       ['<c-n>'],
		\ 'PrtHistory(1)':        ['<c-p>'],
		\ 'AcceptSelection("e")': ['<cr>', '<2-LeftMouse>'],
		\ 'AcceptSelection("h")': ['<c-x>', '<c-cr>', '<c-s>'],
		\ 'AcceptSelection("t")': ['<c-t>', '<MiddleMouse>'],
		\ 'AcceptSelection("v")': ['<c-v>', '<c-q>', '<RightMouse>'],
		\ 'ToggleFocus()':        ['<tab>'],
		\ 'ToggleRegex()':        ['<c-r>'],
		\ 'ToggleByFname()':      ['<c-d>'],
		\ 'ToggleType(1)':        ['<c-f>', '<c-up'],
		\ 'ToggleType(-1)':       ['<c-b>', '<c-down>'],
		\ 'PrtCurStart()':        ['<c-a>'],
		\ 'PrtCurEnd()':          ['<c-e>'],
		\ 'PrtCurLeft()':         ['<c-h>', '<left>'],
		\ 'PrtCurRight()':        ['<c-l>', '<right>'],
		\ 'PrtClearCache()':      ['<F5>'],
		\ 'CreateNewFile()':      ['<c-y>'],
		\ 'MarkToOpen()':         ['<c-z>'],
		\ 'OpenMulti()':          ['<c-o>'],
		\ 'PrtExit()':            ['<esc>', '<c-c>', '<c-g>'],
		\ }]
	if type(s:urprtmaps) == 4 && !empty(s:urprtmaps)
		cal extend(prtmaps, s:urprtmaps)
	en
	" Correct arrow keys in terminal
	if ( has('termresponse') && !empty(v:termresponse) )
		\ || &term =~? 'xterm\|\<k\?vt\|gnome\|screen'
		for each in ['\A <up>','\B <down>','\C <right>','\D <left>']
			exe lcmap.' <esc>['.each
		endfo
	en
	if exists('a:1')
		let prtunmaps = [
			\ 'PrtBS()',
			\ 'PrtDelete()',
			\ 'PrtDeleteWord()',
			\ 'PrtClear()',
			\ 'PrtCurStart()',
			\ 'PrtCurEnd()',
			\ 'PrtCurLeft()',
			\ 'PrtCurRight()',
			\ 'PrtHistory(-1)',
			\ 'PrtHistory(1)',
			\ ]
		for each in prtunmaps | for kp in prtmaps[each]
			exe lcmap kp '<Nop>'
		endfo | endfo
	el
		for each in keys(prtmaps) | for kp in prtmaps[each]
			exe lcmap kp ':<c-u>cal <SID>'.each.'<cr>'
		endfo | endfo
	en
endf
"}}}
" * Toggling {{{
fu! s:Focus()
	retu !exists('s:focus') ? 1 : s:focus
endf

fu! s:ToggleFocus()
	let s:focus = !exists('s:focus') || s:focus ? 0 : 1
	cal s:MapKeys(s:focus)
	cal s:BuildPrompt(0, s:focus)
endf

fu! s:ToggleRegex()
	let s:regexp = s:regexp ? 0 : 1
	cal s:PrtSwitcher()
endf

fu! s:ToggleByFname()
	let s:byfname = s:byfname ? 0 : 1
	cal s:MapKeys(s:Focus(), 1)
	cal s:PrtSwitcher()
endf

fu! s:ToggleType(dir)
	let ext = exists('g:ctrlp_ext_vars') ? len(g:ctrlp_ext_vars) : 0
	let s:itemtype = s:walker(g:ctrlp_builtins + ext, s:itemtype, a:dir)
	cal s:Type(s:itemtype)
endf

fu! s:Type(type)
	let s:itemtype = a:type
	cal s:SetLines(s:itemtype)
	cal s:PrtSwitcher()
	cal s:syntax()
endf

fu! s:PrtSwitcher()
	let s:matches = 1
	cal s:BuildPrompt(1, s:Focus(), 1)
endf
"}}}
fu! ctrlp#SetWorkingPath(...) "{{{
	let [pathmode, s:cwd] = [s:pathmode, getcwd()]
	if exists('a:1') && len(a:1) == 1 && !type(a:1)
		let pathmode = a:1
	elsei exists('a:1') && len(a:1) > 1 && type(a:1)
		sil! exe 'chd!' a:1
		retu
	en
	if match(expand('%:p', 1), '^\<.\+\>://.*') >= 0 || !pathmode
		retu
	en
	if exists('+acd') | let [s:glb_acd, &acd] = [&acd, 0] | en
	let path = expand('%:p:h', 1)
	let path = exists('*fnameescape') ? fnameescape(path) : escape(path, '%#')
	sil! exe 'chd!' path
	if pathmode == 1 | retu | en
	let markers = ['root.dir','.git/','.hg/','.vimprojects','_darcs/','.bzr/']
	if type(s:rmarkers) == 3 && !empty(s:rmarkers)
		cal extend(markers, s:rmarkers, 0)
	en
	for marker in markers
		let found = s:findroot(getcwd(), marker, 0, 0)
		if getcwd() != expand('%:p:h', 1) || found | brea | en
	endfo
endf "}}}
" * AcceptSelection() {{{
fu! ctrlp#acceptfile(mode, matchstr)
	let [md, matchstr] = [a:mode, a:matchstr]
	" Get the full path
	let filpath = s:itemtype ? matchstr : getcwd().s:lash.matchstr
	cal s:PrtExit()
	let bufnum = bufnr(filpath)
	if s:jmptobuf && bufnum > 0 && md == 'e'
		let [jmpb, bufwinnr] = [1, bufwinnr(bufnum)]
		let buftab = s:jmptobuf > 1 ? s:buftab(bufnum) : [0, 0]
	en
	" Switch to existing buffer or open new one
	if exists('jmpb') && buftab[0]
		exe 'norm!' buftab[1].'gt'
		exe buftab[0].'winc w'
	elsei exists('jmpb') && bufwinnr > 0
		exe bufwinnr.'winc w'
	el
		" Determine the command to use
		if md == 't' || s:splitwin == 1
			tabnew
			let cmd = 'e'
		elsei md == 'h' || s:splitwin == 2
			let cmd = 'new'
		elsei md == 'v' || s:splitwin == 3
			let cmd = 'vne'
		el
			let cmd = s:normcmd('e')
		en
		" Open new window/buffer
		cal s:openfile(cmd, filpath)
	en
endf

fu! s:AcceptSelection(mode)
	if a:mode == 'e'
		let str = join(s:prompt, '')
		if str == '..' && !s:itemtype
			cal s:parentdir(getcwd())
			cal s:SetLines(s:itemtype)
			cal s:PrtClear()
			retu
		elsei str == '?'
			cal s:PrtExit()
			let hlpwin = &columns > 159 ? '| vert res 80' : ''
			sil! exe 'bo vert h ctrlp-mappings' hlpwin '| norm! 0'
			retu
		en
	en
	" Get the selected line
	let matchstr = matchstr(getline('.'), '^> \zs.\+\ze\t*$')
	if empty(matchstr) | retu | en
	" Do something with it
	let rhs = s:mru ? '0\|1\|2' : '0\|1'
	let actfunc = s:itemtype =~ rhs ? 'ctrlp#acceptfile'
		\ : g:ctrlp_ext_vars[s:itemtype - ( g:ctrlp_builtins + 1 )][1]
	cal call(actfunc, [a:mode, matchstr])
	ec
endf
"}}}
fu! s:CreateNewFile() "{{{
	let str = join(s:prompt, '')
	if empty(str) | retu | en
	let str = s:sanstail(str)
	let arr = split(str, '[\/]')
	let fname = remove(arr, -1)
	if len(arr) | if isdirectory(s:createparentdirs(arr))
		let optyp = str
	en | el
		let optyp = fname
	en
	if exists('optyp')
		cal s:insertcache(str)
		cal s:PrtExit()
		if s:newfop == 1
			tabnew
			let cmd = 'e'
		elsei s:newfop == 2
			let cmd = 'new'
		elsei s:newfop == 3
			let cmd = 'vne'
		el
			let cmd = s:normcmd('e')
		en
		cal s:openfile(cmd, getcwd().s:lash.optyp)
	en
endf "}}}
" * OpenMulti() {{{
fu! s:MarkToOpen()
	if s:bufnr <= 0 || !s:opmul || s:itemtype > g:ctrlp_builtins | retu | en
	let matchstr = matchstr(getline('.'), '^> \zs.\+\ze\t*$')
	if empty(matchstr) | retu | en
	let filpath = s:itemtype ? matchstr : getcwd().s:lash.matchstr
	if exists('s:marked') && s:dictindex(s:marked, filpath) > 0
		" Unmark and remove the file from s:marked
		let key = s:dictindex(s:marked, filpath)
		cal remove(s:marked, key)
		if empty(s:marked) | unl! s:marked | en
		if has('signs')
			exe 'sign unplace' key 'buffer='.s:bufnr
		en
	el
		" Add to s:marked and place a new sign
		if exists('s:marked')
			let vac = s:vacantdict(s:marked)
			let key = empty(vac) ? len(s:marked) + 1 : vac[0]
			let s:marked = extend(s:marked, { key : filpath })
		el
			let [key, s:marked] = [1, { 1 : filpath }]
		en
		if has('signs')
			exe 'sign place' key 'line='.line('.').' name=ctrlpmark buffer='.s:bufnr
		en
	en
	sil! cal s:statusline()
endf

fu! s:OpenMulti()
	if !exists('s:marked') || !s:opmul
		cal s:AcceptSelection('e')
		retu
	en
	let mkd = s:marked
	cal s:PrtExit()
	" Try not to open a new tab
	let [ntab, norwins] = [0, s:normbuf()]
	if empty(norwins) | let ntab = 1 | el
		for each in norwins
			let bufnr = winbufnr(each)
			if !empty(bufname(bufnr)) && !empty(getbufvar(bufnr, '&ft'))
				\ && bufname(bufnr) != 'ControlP'
				let ntab = 1
			en
		endfo
		if !ntab | let wnr = min(norwins) | en
	en
	if ntab | tabnew | en
	let [ic, wnr] = [1, exists('wnr') ? wnr : 1]
	exe wnr.'winc w'
	for key in keys(mkd)
		let cmd = ic == 1 ? 'e' : 'vne'
		cal s:openfile(cmd, mkd[key])
		if s:opmul > 1 && s:opmul < ic | clo!
		el | let ic += 1 | en
	endfo
	ec
endf
"}}}
" ** Helper functions {{{
" Sorting {{{
fu! s:complen(s1, s2)
	" By length
	let [len1, len2] = [strlen(a:s1), strlen(a:s2)]
	retu len1 == len2 ? 0 : len1 > len2 ? 1 : -1
endf

fu! s:compmatlen(s1, s2)
	" By match length
	let mln1 = s:shortest(s:matchlens(a:s1, s:compat))
	let mln2 = s:shortest(s:matchlens(a:s2, s:compat))
	retu mln1 == mln2 ? 0 : mln1 > mln2 ? 1 : -1
endf

fu! s:compword(s1, s2)
	" By word-only (no non-word in match)
	let wrd1 = s:wordonly(s:matchlens(a:s1, s:compat))
	let wrd2 = s:wordonly(s:matchlens(a:s2, s:compat))
	retu wrd1 == wrd2 ? 0 : wrd1 > wrd2 ? 1 : -1
endf

fu! s:comptime(s1, s2)
	" By last modified time
	let [time1, time2] = [getftime(a:s1), getftime(a:s2)]
	retu time1 == time2 ? 0 : time1 < time2 ? 1 : -1
endf

fu! s:matchlens(str, pat, ...)
	if empty(a:pat) || a:pat =~ '^\|$' | retu {} | en
	let st   = exists('a:1') ? a:1 : 0
	let lens = exists('a:2') ? a:2 : {}
	let nr   = exists('a:3') ? a:3 : 0
	if match(a:str, a:pat, st) != -1
		let [str, mend] = [matchstr(a:str, a:pat, st), matchend(a:str, a:pat, st)]
		let lens = extend(lens, { nr : [len(str), str] })
		let lens = s:matchlens(a:str, a:pat, mend, lens, nr + 1)
	en
	retu lens
endf

fu! s:shortest(lens)
	let lns = []
	for nr in keys(a:lens) | cal add(lns, a:lens[nr][0]) | endfo
	retu min(lns)
endf

fu! s:wordonly(lens)
	let [lens, minln] = [a:lens, s:shortest(lens)]
	cal filter(lens, 'minln == v:val[0]')
	for nr in keys(lens)
		if match(lens[nr][1], '\W') >= 0 | retu 1 | en
	endfo
	retu 0
endf

fu! s:mixedsort(s1, s2)
	let [cmatlen, clen] = [s:compmatlen(a:s1, a:s2), s:complen(a:s1, a:s2)]
	let rhs = s:mru ? '0\|1\|2' : '0\|1'
	if s:itemtype =~ rhs
		let [ctime, cword] = [s:comptime(a:s1, a:s2), s:compword(a:s1, a:s2)]
		retu 6 * cmatlen + 3 * ctime + 2 * clen + cword
	el
		retu 2 * cmatlen + clen
	en
endf
"}}}
" Statusline {{{
fu! s:statusline(...)
	if !exists('s:statypes')
		let s:statypes = [
			\ ['files', 'fil'],
			\ ['buffers', 'buf'],
			\ ['mru files', 'mru'],
			\ ]
		if !s:mru | cal remove(s:statypes, 2) | en
		if exists('g:ctrlp_ext_vars') | for each in g:ctrlp_ext_vars
			cal add(s:statypes, [ each[2], each[3] ])
		endfo | en
	en
	let tps = s:statypes
	let max = len(tps) - 1
	let nxt = tps[s:walker(max, s:itemtype,  1)][1]
	let prv = tps[s:walker(max, s:itemtype, -1)][1]
	let item = tps[s:itemtype][0]
	let focus   = s:Focus() ? 'prt'  : 'win'
	let byfname = s:byfname ? 'file' : 'path'
	let regex   = s:regexp  ? '%#LineNr# regex %*' : ''
	let focus   = '%#LineNr# '.focus.' %*'
	let byfname = '%#Character# '.byfname.' %*'
	let item    = '%#Character# '.item.' %*'
	let slider  = ' <'.prv.'>={'.item.'}=<'.nxt.'>'
	let dir     = ' %=%<%#LineNr# '.getcwd().' %*'
	let marked = s:opmul ? exists('s:marked') ? ' <'.s:dismrk().'>' : ' <+>' : ''
	let &l:stl = focus.byfname.regex.slider.marked.dir
endf

fu! s:dismrk()
	retu has('signs') ? '+'.len(s:marked) :
		\ '%<'.join(values(map(copy(s:marked), 'split(v:val, "[\\/]")[-1]')), ', ')
endf

fu! s:progress(len)
	if has('macunix') || has('mac') | sl 1m | en
	let &l:stl = '%#Function# '.a:len.' %* %=%<%#LineNr# '.getcwd().' %*'
	redr
endf
"}}}
" Paths {{{
fu! s:dirfilter(val)
	retu isdirectory(a:val) && match(a:val, '[\/]\.\{,2}$') < 0 ? 1 : 0
endf

fu! s:parentdir(curr)
	let parent = substitute(a:curr, '[\/]\zs[^\/]\+[\/]\?$', '', '')
	if parent != a:curr
		sil! exe 'lc!' parent
	en
endf

fu! s:createparentdirs(arr)
	for each in a:arr
		let curr = exists('curr') ? curr.s:lash.each : each
		cal ctrlp#utils#mkdir(curr)
	endfo
	retu curr
endf

fu! s:listdirs(path,parent)
	let str = ''
	for entry in filter(split(globpath(a:path, '*'), '\n'), 'isdirectory(v:val)')
		let str .= a:parent . split(entry, '[\/]')[-1] . "\n"
	endfo
	retu str
endf

fu! ctrlp#compl(A,L,P)
	let haslash = match(a:A, '[\/]')
	let parent = substitute(a:A, '[^\/]*$', '', 'g')
	let path = !haslash ? parent : haslash > 0 ? getcwd().s:lash.parent : getcwd()
	retu s:listdirs(path, parent)
endf

fu! s:findroot(curr, mark, depth, type)
	let [depth, notfound] = [a:depth + 1, empty(globpath(a:curr, a:mark))]
	if !notfound || depth > s:maxdepth
		if notfound
			if exists('s:cwd')
				sil! exe 'chd!' s:cwd
			en
			retu 0
		en
		if a:type
			let s:vcsroot = depth <= s:maxdepth ? a:curr : ''
		el
			sil! exe 'chd!' a:curr
			retu 1
		en
	el
		let parent = substitute(a:curr, '[\/]\zs[^\/]\+[\/]\?$', '', '')
		if parent != a:curr | cal s:findroot(parent, a:mark, depth, a:type) | en
	en
endf
"}}}
" Highlighting {{{
fu! s:syntax()
	sy match CtrlPNoEntries '^ == NO MATCHES ==$'
	sy match CtrlPLineMarker '^>'
	hi link CtrlPNoEntries Error
	hi CtrlPLineMarker guifg=bg
endf

fu! s:highlight(pat, grp)
	cal clearmatches()
	if !empty(a:pat) && a:pat != '..'
		let pat = substitute(a:pat, '\~', '\\~', 'g')
		if !s:regexp | let pat = escape(pat, '.') | en
		" Match only filename
		if s:byfname
			let pat = substitute(pat, '\[\^\(.\{-}\)\]\\{-}', '[^\\/\1]\\{-}', 'g')
			let pat = substitute(pat, '$', '\\ze[^\\/]*$', 'g')
		en
		cal matchadd(a:grp, '\c'.pat)
		cal matchadd('CtrlPLineMarker', '^>')
	en
endf
"}}}
" Prompt history {{{
fu! s:gethistloc()
	let cache_dir = ctrlp#utils#cachedir().s:lash.'hist'
	retu [cache_dir, cache_dir.s:lash.'cache.txt']
endf

fu! s:gethistdata()
	retu ctrlp#utils#readfile(s:gethistloc()[1])
endf

fu! s:recordhist(str)
	if empty(a:str) || !s:maxhst | retu | en
	let hst = s:hstry
	if len(hst) > 1 && hst[1] == a:str | retu | en
	cal extend(hst, [a:str], 1)
	if len(hst) > s:maxhst | cal remove(hst, s:maxhst, -1) | en
endf
"}}}
" Signs {{{
fu! s:unmarksigns()
	if !s:dosigns() | retu | en
	for key in keys(s:marked)
		exe 'sign unplace' key 'buffer='.s:bufnr
	endfo
endf

fu! s:remarksigns()
	if !s:dosigns() | retu | en
	let nls = s:matched
	for ic in range(1, len(nls))
		let filpath = s:itemtype ? nls[ic - 1] : getcwd().s:lash.nls[ic - 1]
		let key = s:dictindex(s:marked, filpath)
		if key > 0
			exe 'sign place' key 'line='.ic.' name=ctrlpmark buffer='.s:bufnr
		en
	endfo
endf

fu! s:dosigns()
	retu exists('s:marked') && s:bufnr > 0 && s:opmul && has('signs')
endf
"}}}
" Dictionaries {{{
fu! s:dictindex(dict, expr)
	for key in keys(a:dict)
		if a:dict[key] == a:expr | retu key | en
	endfo
	retu -1
endf

fu! s:vacantdict(dict)
	let vac = []
	for ic in range(1, max(keys(a:dict)))
		if !has_key(a:dict, ic) | cal add(vac, ic) | en
	endfo
	retu vac
endf
"}}}
" Buffers {{{
fu! s:buftab(bufnum)
	for nr in range(1, tabpagenr('$'))
		let buflist = tabpagebuflist(nr)
		if match(buflist, a:bufnum) >= 0
			let [buftabnr, tabwinnrs] = [nr, tabpagewinnr(nr, '$')]
			for ewin in range(1, tabwinnrs)
				if buflist[ewin - 1] == a:bufnum
					retu [ewin, buftabnr]
				en
			endfo
		en
	endfo
	retu [0, 0]
endf

fu! s:normbuf()
	let winnrs = []
	for each in range(1, winnr('$'))
		let bufnr = winbufnr(each)
		if getbufvar(bufnr, '&bl') && empty(getbufvar(bufnr, '&bt'))
			\ && getbufvar(bufnr, '&ma')
			cal add(winnrs, each)
		en
	endfo
	retu winnrs
endf

fu! s:normcmd(cmd)
	let norwins = s:normbuf()
	let norwin = empty(norwins) ? 0 : norwins[0]
	" If there's at least 1 normal buffer
	if norwin
		" But not the current one
		if index(norwins, winnr()) < 0
			exe norwin.'winc w'
		en
		retu a:cmd
	el
		retu 'bo vne'
	en
endf

fu! s:setupblank()
	setl noswf nobl nonu nowrap nolist nospell cul nocuc wfh fdc=0 tw=0 bt=nofile bh=unload
	if v:version >= 703
		setl nornu noudf cc=0
	en
endf

fu! s:leavepre()
	if s:cconex | cal ctrlp#clearallcaches() | en
	cal ctrlp#utils#writecache(s:hstry, s:gethistloc()[0], s:gethistloc()[1])
endf

fu! s:checkbuf()
	if exists('s:init') | retu | en
	if exists('s:bufnr') && s:bufnr > 0
		exe s:bufnr.'bw!'
	en
endf
"}}}
" Arguments {{{
fu! s:tail()
	if exists('s:optail') && !empty('s:optail')
		let tailpref = match(s:optail, '^\s*+') < 0 ? ' +' : ' '
		retu tailpref.s:optail
	en
	retu ''
endf

fu! s:sanstail(str)
	" Restore the number of backslashes
	let str = substitute(a:str, '\\\\', '\', 'g')
	unl! s:optail
	if match(str, ':\([^:]\|\\:\)*$') >= 0
		let s:optail = matchstr(str, ':\zs\([^:]\|\\:\)*$')
		retu substitute(str, ':\([^:]\|\\:\)*$', '', 'g')
	el
		retu str
	en
endf
"}}}
" Misc {{{
fu! s:openfile(cmd, filpath)
	let cmd = a:cmd == 'e' && &modified ? 'new' : a:cmd
	try
		exe cmd.s:tail().' '.escape(a:filpath, '%# ')
	cat
		echoh Identifier
		echon "CtrlP: Operation can't be completed. Make sure filename is valid."
		echoh None
	fina
		if !empty(s:tail())
			sil! norm! zOzz
		en
	endt
endf

fu! s:writecache(read_cache, cache_file)
	if !a:read_cache && ( ( g:ctrlp_newcache || !filereadable(a:cache_file) )
		\ && s:caching || len(g:ctrlp_allfiles) > s:nocache_lim )
		if len(g:ctrlp_allfiles) > s:nocache_lim | let s:caching = 1 | en
		cal ctrlp#utils#writecache(g:ctrlp_allfiles)
	en
endf

fu! s:regexfilter(str)
	let str = a:str
	let pats = {
		\ '^\(\\|\)\|\(\\|\)$': '\\|',
		\ '^\\\(zs\|ze\|<\|>\)': '^\\\(zs\|ze\|<\|>\)',
		\ '^\S\*$': '\*',
		\ '^\S\\?$': '\\?',
		\ }
	for key in keys(pats) | if match(str, key) >= 0
		let str = substitute(str, pats[key], '', 'g')
	en | endfo
	retu str
endf

fu! ctrlp#exit()
	cal s:PrtExit()
endf

fu! s:walker(max, pos, dir)
	retu a:dir > 0 ? a:pos < a:max ? a:pos + 1 : 0 : a:pos > 0 ? a:pos - 1 : a:max
endf

fu! s:matchsubstr(item, pat)
	retu match(split(a:item, '[\/]\ze[^\/]\+$')[-1], a:pat)
endf

fu! s:maxfiles(len)
	retu s:maxfiles && a:len > s:maxfiles ? 1 : 0
endf

fu! s:insertcache(str)
	if match(a:str, '|\|?\|:\|"\|\*\|<\|>') >= 0 | retu | en
	let [data, g:ctrlp_newcache, str] = [g:ctrlp_allfiles, 1, a:str]
	if strlen(str) <= strlen(data[0])
		let pos = 0
	elsei strlen(str) >= strlen(data[-1])
		let pos = len(data) - 1
	el
		let pos = 0
		for each in data
			if strlen(each) > strlen(str) | brea | en
			let pos += 1
		endfo
	en
	cal insert(data, str, pos)
	cal s:writecache(0, ctrlp#utils#cachefile())
endf

fu! s:lscommand()
	let usercmd = g:ctrlp_user_command
	if type(usercmd) == 1
		retu usercmd
	elsei type(usercmd) == 3 && len(usercmd) >= 2
		\ && !empty(usercmd[0]) && !empty(usercmd[1])
		let rmarker = usercmd[0]
		" Find a repo root
		cal s:findroot(getcwd(), rmarker, 0, 1)
		if !exists('s:vcsroot') || ( exists('s:vcsroot') && empty(s:vcsroot) )
			" Try the secondary_command
			retu len(usercmd) == 3 ? usercmd[2] : ''
		el
			let s:vcscmd = s:lash == '\' ? 1 : 0
			retu usercmd[1]
		en
	en
endf
"}}}
"}}}
" * Initialization {{{
fu! s:SetLines(type)
	let s:itemtype = a:type
	let types = [
		\ 's:Files(getcwd())',
		\ 's:Buffers()',
		\ 'ctrlp#mrufiles#list(-1)',
		\ ]
	if !s:mru | cal remove(types, 2) | en
	if exists('g:ctrlp_ext_vars') | for each in g:ctrlp_ext_vars
		cal add(types, each[0])
	endfo | en
	let g:ctrlp_lines = eval(types[a:type])
endf

fu! ctrlp#init(type, ...)
	if exists('s:init') | retu | en
	let [s:matches, s:init] = [1, 1]
	let path = exists('a:1') ? a:1 : ''
	cal ctrlp#SetWorkingPath(path)
	cal s:Open()
	cal s:MapKeys()
	cal s:SetLines(a:type)
	cal s:BuildPrompt(1)
	cal s:syntax()
endf
"}}}
if has('autocmd') "{{{
	aug CtrlPAug
		au!
		au BufEnter ControlP cal s:checkbuf()
		au BufLeave ControlP cal s:Close()
		au VimLeavePre * cal s:leavepre()
	aug END
en "}}}

" vim:fen:fdl=0:fdc=1:ts=2:sw=2:sts=2
