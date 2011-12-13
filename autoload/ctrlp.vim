" =============================================================================
" File:          autoload/ctrlp.vim
" Description:   Fuzzy file, buffer, mru and tag finder.
" Author:        Kien Nguyen <github.com/kien>
" Version:       1.6.4
" =============================================================================

" Static variables {{{1
fu! s:opts()
	let hst = exists('+hi') ? &hi : 20
	let opts = {
		\ 'g:ctrlp_by_filename':           ['s:byfname', 0],
		\ 'g:ctrlp_clear_cache_on_exit':   ['s:clrex', 1],
		\ 'g:ctrlp_dont_split':            ['s:nosplit', ''],
		\ 'g:ctrlp_dotfiles':              ['s:dotfiles', 1],
		\ 'g:ctrlp_extensions':            ['s:extensions', []],
		\ 'g:ctrlp_follow_symlinks':       ['s:folsym', 0],
		\ 'g:ctrlp_highlight_match':       ['s:mathi', [1, 'Identifier']],
		\ 'g:ctrlp_lazy_update':           ['s:lazy', 0],
		\ 'g:ctrlp_jump_to_buffer':        ['s:jmptobuf', 1],
		\ 'g:ctrlp_match_window_bottom':   ['s:mwbottom', 1],
		\ 'g:ctrlp_match_window_reversed': ['s:mwreverse', 1],
		\ 'g:ctrlp_max_depth':             ['s:maxdepth', 40],
		\ 'g:ctrlp_max_files':             ['s:maxfiles', 20000],
		\ 'g:ctrlp_max_height':            ['s:mxheight', 10],
		\ 'g:ctrlp_max_history':           ['s:maxhst', hst],
		\ 'g:ctrlp_open_multi':            ['s:opmul', '1v'],
		\ 'g:ctrlp_open_new_file':         ['s:newfop', 3],
		\ 'g:ctrlp_prompt_mappings':       ['s:urprtmaps', 0],
		\ 'g:ctrlp_regexp_search':         ['s:regexp', 0],
		\ 'g:ctrlp_root_markers':          ['s:rmarkers', []],
		\ 'g:ctrlp_split_window':          ['s:splitwin', 0],
		\ 'g:ctrlp_use_caching':           ['s:caching', 1],
		\ 'g:ctrlp_use_migemo':            ['s:migemo', 0],
		\ 'g:ctrlp_user_command':          ['s:usrcmd', ''],
		\ 'g:ctrlp_working_path_mode':     ['s:pathmode', 2],
		\ }
	for [ke, va] in items(opts)
		exe 'let' va[0] '=' string(exists(ke) ? eval(ke) : va[1])
	endfo
	if !exists('g:ctrlp_newcache') | let g:ctrlp_newcache = 0 | en
	let s:glob = s:dotfiles ? '.*\|*' : '*'
	let s:maxdepth = min([s:maxdepth, 100])
	let g:ctrlp_builtins = 2
	if !empty(s:extensions) | for each in s:extensions
		exe 'ru autoload/ctrlp/'.each.'.vim'
	endfo | en
endf
cal s:opts()

let s:lash = ctrlp#utils#lash()

" Global options
let s:glbs = { 'magic': 1, 'to': 1, 'tm': 0, 'sb': 1, 'hls': 0, 'im': 0,
	\ 'report': 9999, 'sc': 0, 'ss': 0, 'siso': 0, 'mfd': 200, 'mouse': 'n',
	\ 'gcr': 'a:block-PmenuSel-blinkon0' }

if s:lazy
	cal extend(s:glbs, { 'ut': ( s:lazy > 1 ? s:lazy : 250 ) })
en

" Limiters
let [s:compare_lim, s:nocache_lim, s:mltipats_lim] = [3000, 4000, 2000]
" * Open & Close {{{1
fu! s:Open()
	let [s:cwd, s:winres] = [getcwd(), winrestcmd()]
	let [s:crfile, s:crfpath] = [expand('%:p', 1), expand('%:p:h', 1)]
	let [s:crword, s:crline] = [expand('<cword>'), getline('.')]
	let [s:tagfiles, s:crcursor] = [s:tagfiles(), getpos('.')]
	let [s:crbufnr, s:crvisual] = [bufnr('%'), s:lastvisual()]
	let s:currwin = s:mwbottom ? winnr() : winnr() + has('autocmd')
	sil! exe s:mwbottom ? 'bo' : 'to' '1new ControlP'
	let [s:bufnr, s:prompt] = [bufnr('%'), ['', '', '']]
	abc <buffer>
	if !exists('s:hstry')
		let hst = filereadable(s:gethistloc()[1]) ? s:gethistdata() : ['']
		let s:hstry = empty(hst) || !s:maxhst ? [''] : hst
	en
	for [ke, va] in items(s:glbs)
		sil! exe 'let s:glb_'.ke.' = &'.ke.' | let &'.ke.' = '.string(va)
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
	exe s:winres
	unl! s:focus s:hisidx s:hstgot s:marked s:statypes s:cline s:init s:savestr
		\ s:crfile s:crfpath s:crword s:crvisual s:tagfiles s:crline s:crcursor
		\ g:ctrlp_nolimit s:crbufnr
	cal ctrlp#recordhist()
	ec
endf
" * Clear caches {{{1
fu! ctrlp#clr(...)
	exe 'let g:ctrlp_new'.( exists('a:1') ? a:1 : 'cache' ).' = 1'
endf

fu! ctrlp#clra(...)
	if !exists('a:1') && ( has('dialog_gui') || has('dialog_con') ) &&
		\ confirm("Delete all cache files?", "&OK\n&Cancel") != 1 | retu | en
	let cache_dir = ctrlp#utils#cachedir()
	if isdirectory(cache_dir)
		let cache_files = split(s:glbpath(cache_dir, '**', 1), "\n")
		cal filter(cache_files, '!isdirectory(v:val) && v:val !~ ''\<cache\.txt$''')
		sil! cal map(cache_files, 'delete(v:val)')
	en
	cal ctrlp#clr()
endf

fu! ctrlp#reset()
	if ( has('dialog_gui') || has('dialog_con') ) &&
		\ confirm("Reset and apply new options?", "&OK\n&Cancel") != 1 | retu | en
	cal s:opts()
	cal ctrlp#utils#opts()
	cal ctrlp#mrufiles#opts()
	unl! s:cline
endf
" * Files() {{{1
fu! s:GlobPath(dirs, allfiles, depth)
	let entries = split(globpath(a:dirs, s:glob), "\n")
	if !s:folsym
		let entries = filter(entries, 'getftype(v:val) != "link"')
	en
	let g:ctrlp_allfiles = filter(copy(entries), '!isdirectory(v:val)')
	let ftrfunc = s:dotfiles ? 'ctrlp#dirfilter(v:val)' : 'isdirectory(v:val)'
	let alldirs = filter(entries, ftrfunc)
	cal extend(g:ctrlp_allfiles, a:allfiles, 0)
	let depth = a:depth + 1
	if !empty(alldirs) && !s:maxfiles(len(g:ctrlp_allfiles)) && depth <= s:maxdepth
		sil! cal ctrlp#progress(len(g:ctrlp_allfiles))
		cal s:GlobPath(join(alldirs, ','), g:ctrlp_allfiles, depth)
	en
endf

fu! s:UserCommand(path, lscmd)
	let path = a:path
	if exists('+ssl') && &ssl
		let [ssl, &ssl, path] = [&ssl, 0, tr(path, '/', '\')]
	en
	let path = exists('*shellescape') ? shellescape(path) : path
	let g:ctrlp_allfiles = split(system(printf(a:lscmd, path)), "\n")
	if exists('+ssl') && exists('ssl')
		let &ssl = ssl
		cal map(g:ctrlp_allfiles, 'tr(v:val, "\\", "/")')
	en
	if exists('s:vcscmd') && s:vcscmd
		cal map(g:ctrlp_allfiles, 'tr(v:val, "/", "\\")')
	en
endf

fu! s:Files()
	let [cwd, cache_file] = [getcwd(), ctrlp#utils#cachefile()]
	if g:ctrlp_newcache || !filereadable(cache_file) || !s:caching
		let lscmd = s:lscommand()
		" Get the list of files
		if empty(lscmd)
			cal s:GlobPath(cwd, [], 0)
		el
			sil! cal ctrlp#progress('Waiting...')
			try | cal s:UserCommand(cwd, lscmd) | cat | retu [] | endt
		en
		" Remove base directory
		cal ctrlp#rmbasedir(g:ctrlp_allfiles)
		let read_cache = 0
	el
		let g:ctrlp_allfiles = ctrlp#utils#readfile(cache_file)
		let read_cache = 1
	en
	if len(g:ctrlp_allfiles) <= s:compare_lim
		cal sort(g:ctrlp_allfiles, 'ctrlp#complen')
	en
	cal s:writecache(read_cache, cache_file)
	retu g:ctrlp_allfiles
endf
fu! s:Buffers() "{{{1
	let allbufs = []
	for each in range(1, bufnr('$'))
		if getbufvar(each, '&bl') && each != bufnr('#')
			let bufname = bufname(each)
			if strlen(bufname) && getbufvar(each, '&ma') && bufname != 'ControlP'
				cal add(allbufs, fnamemodify(bufname, ':p'))
			en
		en
	endfo
	retu allbufs
endf
" * MatchedItems() {{{1
fu! s:MatchIt(items, pat, limit, ispathitem)
	let [items, pat, limit, newitems] = [a:items, a:pat, a:limit, []]
	let mfunc = s:byfname && a:ispathitem ? 's:matchfname'
		\ : s:itemtype > 2 && len(items) < 30000 && !a:ispathitem ? 's:matchtab'
		\ : 'match'
	for item in items
		if call(mfunc, [item, pat]) >= 0 | cal add(newitems, item) | en
		if limit > 0 && len(newitems) >= limit | brea | en
	endfo
	retu newitems
endf

fu! s:MatchedItems(items, pats, limit)
	let [items, pats, limit, ipt] = [a:items, a:pats, a:limit, s:ispathitem()]
	" If items is longer than s:mltipats_lim, use only the last pattern
	if len(items) >= s:mltipats_lim | let pats = [pats[-1]] | en
	cal map(pats, 'substitute(v:val, "\\\~", "\\\\\\~", "g")')
	if !s:regexp | cal map(pats, 'escape(v:val, ".")') | en
	" Loop through the patterns
	for each in pats
		" If newitems is small, set it as items to search in
		if exists('newitems') && len(newitems) < limit
			let items = copy(newitems)
		en
		if empty(items) " End here
			retu exists('newitems') ? newitems : []
		el " Start here, go back up if have 2 or more in pats
			" Loop through the items
			let newitems = s:MatchIt(items, each, limit, ipt)
		en
	endfo
	let s:matches = len(newitems)
	retu newitems
endf
fu! s:SplitPattern(str, ...) "{{{1
	let str = s:sanstail(a:str)
	if s:migemo && s:regexp && len(str) > 0 && executable('cmigemo')
		let dict = s:glbpath(&rtp, printf("dict/%s/migemo-dict", &encoding), 1)
		if !len(dict)
			let dict = s:glbpath(&rtp, "dict/migemo-dict", 1)
		en
		if len(dict)
			let [tokens, str, cmd] = [split(str, '\s'), '', 'cmigemo -v -w %s -d %s']
			for token in tokens
				let rtn = system(printf(cmd, shellescape(token), shellescape(dict)))
				let str .= !v:shell_error && len(rtn) > 0 ? '.*'.rtn : token
			endfo
		en
	en
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
		for item in range(1, len(array) - 1)
			" Separator
			let sep = exists('a:1') ? a:1 : '[^'.array[item-1].']\{-}'
			let nitem .= sep.array[item]
			cal add(newpats, nitem)
		endfo
	en
	retu newpats
endf
" * BuildPrompt() {{{1
fu! s:Render(lines, pat)
	let lines = a:lines
	" Setup the match window
	let s:height = min([len(lines), s:mxheight])
	sil! exe '%d _ | res' s:height
	" Print the new items
	if empty(lines)
		setl nocul
		cal setline(1, ' == NO ENTRIES ==')
		cal s:unmarksigns()
		if s:dohighlight() | cal clearmatches() | en
		retu
	en
	setl cul
	" Sort if not MRU
	if ( s:itemtype != 2 && !exists('g:ctrlp_nolimit') )
		\ || !empty(join(s:prompt, ''))
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
	if exists('s:cline') | cal cursor(s:cline, 1) | en
	" Highlighting
	if s:dohighlight()
		cal s:highlight(a:pat, empty(s:mathi[1]) ? 'Identifier' : s:mathi[1])
	en
endf

fu! s:Update(str)
	" Get the previous string if existed
	let oldstr = exists('s:savestr') ? s:savestr : ''
	let pats = s:SplitPattern(a:str)
	" Get the new string sans tail
	let notail = substitute(a:str, ':\([^:]\|\\:\)*$', '', 'g')
	" Stop if the string's unchanged
	if notail == oldstr && !empty(notail) && !exists('s:force')
		retu
	en
	let lines = exists('g:ctrlp_nolimit') && empty(notail) ? copy(g:ctrlp_lines)
		\ : s:MatchedItems(g:ctrlp_lines, pats, s:mxheight)
	cal s:Render(lines, pats[-1])
endf

fu! s:ForceUpdate()
	let [estr, prt] = ['"\', copy(s:prompt)]
	cal map(prt, 'escape(v:val, estr)')
	cal s:Update(join(prt, ''))
endf

fu! s:BuildPrompt(upd, ...)
	let base = ( s:regexp ? 'r' : '>' ).( s:byfname ? 'd' : '>' ).'> '
	let [estr, prt] = ['"\', copy(s:prompt)]
	cal map(prt, 'escape(v:val, estr)')
	let str = join(prt, '')
	let lazy = empty(str) || exists('s:force') || !has('autocmd') ? 0 : s:lazy
	if a:upd && ( s:matches || s:regexp || match(str, '[*|]') >= 0 ) && !lazy
		sil! cal s:Update(str)
	en
	sil! cal ctrlp#statusline()
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
" ** Prt Actions {{{1
" Editing {{{2
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
	let str = match(str, '\W\w\+$') >= 0 ? matchstr(str, '^.\+\W\ze\w\+$')
		\ : match(str, '\w\W\+$') >= 0 ? matchstr(str, '^.\+\w\ze\W\+$')
		\ : match(str, '\s\+$') >= 0 ? matchstr(str, '^.*[^ \t]\+\ze\s\+$')
		\ : match(str, ' ') <= 0 ? '' : str
	let s:prompt[0] = str
	cal s:BuildPrompt(1)
endf

fu! s:PrtInsert(type)
	unl! s:hstgot
	" Insert current word, search register, last visual and clipboard
	let s:prompt[0] .= a:type == 'w' ? s:crword
		\ : a:type == 's' ? getreg('/')
		\ : a:type == 'v' ? s:crvisual
		\ : a:type == '+' ? substitute(getreg('+'), '\n', '\\n', 'g') : s:prompt[0]
	cal s:BuildPrompt(1)
endf
" Movement {{{2
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
	let [prt[0], prt[1], prt[2]] = [join(prt, ''), '', '']
	cal s:BuildPrompt(0)
endf

fu! s:PrtSelectMove(dir)
	exe 'norm!' a:dir
	let s:cline = line('.')
	if line('$') > winheight(0) | cal s:BuildPrompt(0, s:Focus()) | en
endf

fu! s:PrtSelectJump(char, ...)
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
		if line('$') > winheight(0) | cal s:BuildPrompt(0, s:Focus()) | en
	en
endf
" Misc {{{2
fu! s:PrtClearCache()
	if s:itemtype == 1 | retu | en
	if s:itemtype == 0
		cal ctrlp#clr()
	elsei s:itemtype > 2
		cal ctrlp#clr(s:statypes[s:itemtype][1])
	en
	if s:itemtype == 2
		let g:ctrlp_lines = ctrlp#mrufiles#list(-1, 1)
	el
		cal s:SetLines(s:itemtype)
	en
	let s:force = 1
	cal s:BuildPrompt(1)
	unl s:force
endf

fu! s:PrtDeleteMRU()
	if s:itemtype == 2
		let s:force = 1
		let g:ctrlp_lines = ctrlp#mrufiles#list(-1, 2)
		cal s:BuildPrompt(1)
		unl s:force
	en
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
	let [s:hisidx, s:hstgot, s:force] = [idx, 1, 1]
	cal s:BuildPrompt(1)
	unl s:force
endf
"}}}1
" * MapKeys() {{{1
fu! s:MapKeys(...)
	" Normal keys
	let pfunc = exists('a:1') && !a:1 ? 'PrtSelectJump' : 'PrtAdd'
	let dojmp = s:byfname && pfunc == 'PrtSelectJump' ? ', 1' : ''
	for each in range(32, 126)
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
		\ 'PrtInsert("w")':       ['<F2>'],
		\ 'PrtInsert("s")':       ['<F3>'],
		\ 'PrtInsert("v")':       ['<F4>'],
		\ 'PrtInsert("+")':       ['<F6>'],
		\ 'PrtCurStart()':        ['<c-a>'],
		\ 'PrtCurEnd()':          ['<c-e>'],
		\ 'PrtCurLeft()':         ['<c-h>', '<left>'],
		\ 'PrtCurRight()':        ['<c-l>', '<right>'],
		\ 'PrtClearCache()':      ['<F5>'],
		\ 'PrtDeleteMRU()':       ['<F7>'],
		\ 'CreateNewFile()':      ['<c-y>'],
		\ 'MarkToOpen()':         ['<c-z>'],
		\ 'OpenMulti()':          ['<c-o>'],
		\ 'PrtExit()':            ['<esc>', '<c-c>', '<c-g>'],
		\ }]
	if type(s:urprtmaps) == 4
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
			\ 'PrtInsert("w")',
			\ 'PrtInsert("s")',
			\ 'PrtInsert("v")',
			\ 'PrtInsert("+")',
			\ ]
		for ke in prtunmaps | for kp in prtmaps[ke]
			exe lcmap kp '<Nop>'
		endfo | endfo
	el
		for [ke, va] in items(prtmaps) | for kp in va
			exe lcmap kp ':<c-u>cal <SID>'.ke.'<cr>'
		endfo | endfo
	en
endf
" * Toggling {{{1
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
	if s:ispathitem()
		let s:byfname = s:byfname ? 0 : 1
		cal s:MapKeys(s:Focus(), 1)
		cal s:PrtSwitcher()
	en
endf

fu! s:ToggleType(dir)
	let ext = exists('g:ctrlp_ext_vars') ? len(g:ctrlp_ext_vars) : 0
	let s:itemtype = s:walker(g:ctrlp_builtins + ext, s:itemtype, a:dir)
	let s:extid = s:itemtype - ( g:ctrlp_builtins + 1 )
	unl! g:ctrlp_nolimit
	cal s:SetLines(s:itemtype)
	cal s:PrtSwitcher()
	if s:itemtype > 2
		if exists('g:ctrlp_ext_vars['.s:extid.'][4][0]')
			let g:ctrlp_nolimit = g:ctrlp_ext_vars[s:extid][4][0]
		en
	el
		cal s:syntax()
	en
endf

fu! s:PrtSwitcher()
	let [s:force, s:matches] = [1, 1]
	cal s:BuildPrompt(1, s:Focus())
	unl s:force
endf
fu! s:SetWD(...) "{{{1
	let pathmode = s:pathmode
	if exists('a:1') && len(a:1) | if type(a:1)
		cal ctrlp#setdir(a:1) | retu
	el
		let pathmode = a:1
	en | en
	if !exists('a:2')
		if match(s:crfile, '^\<.\+\>://.*') >= 0 || !pathmode | retu | en
		if exists('+acd') | let [s:glb_acd, &acd] = [&acd, 0] | en
		cal ctrlp#setdir(s:crfpath)
	en
	if pathmode == 1 | retu | en
	let markers = ['root.dir','.git/','.hg/','.vimprojects','_darcs/','.bzr/']
	if type(s:rmarkers) == 3 && !empty(s:rmarkers)
		cal extend(markers, s:rmarkers, 0)
	en
	for marker in markers
		cal s:findroot(getcwd(), marker, 0, 0)
		if exists('s:foundroot') | brea | en
	endfo
	unl! s:foundroot
endf
" * AcceptSelection() {{{1
fu! ctrlp#acceptfile(mode, matchstr, ...)
	let [md, matchstr] = [a:mode, a:matchstr]
	" Get the full path
	let filpath = s:itemtype ? matchstr : getcwd().s:lash.matchstr
	cal s:PrtExit()
	let bufnum = bufnr(filpath)
	if s:jmptobuf && bufnum > 0 && md == 'e'
		let [jmpb, bufwinnr] = [1, bufwinnr(bufnum)]
		let buftab = s:jmptobuf > 1 ? s:buftab(bufnum) : [0, 0]
		let j2l = a:0 ? a:1 : str2nr(matchstr(s:tail(), '^ +\zs\d\+$'))
	en
	" Switch to existing buffer or open new one
	if exists('jmpb') && buftab[0]
		exe 'tabn' buftab[1]
		exe buftab[0].'winc w'
		if j2l | cal s:j2l(j2l) | en
	elsei exists('jmpb') && bufwinnr > 0
		exe bufwinnr.'winc w'
		if j2l | cal s:j2l(j2l) | en
	el
		" Determine the command to use
		let cmd = md == 't' || s:splitwin == 1 ? 'tabe'
			\ : md == 'h' || s:splitwin == 2 ? 'new'
			\ : md == 'v' || s:splitwin == 3 ? 'vne' : ctrlp#normcmd('e')
		" Open new window/buffer
		cal call('s:openfile', a:0 ? [cmd, filpath, ' +'.a:1] : [cmd, filpath])
	en
endf

fu! s:AcceptSelection(mode)
	if a:mode == 'e' | if s:specinputs() | retu | en | en
	" Get the selected line
	let matchstr = matchstr(getline('.'), '^> \zs.\+\ze\t*$')
	if empty(matchstr) | retu | en
	" Do something with it
	let actfunc = s:itemtype =~ '0\|1\|2' ? 'ctrlp#acceptfile'
		\ : g:ctrlp_ext_vars[s:itemtype - ( g:ctrlp_builtins + 1 )][1]
	cal call(actfunc, [a:mode, matchstr])
endf
fu! s:CreateNewFile() "{{{1
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
		let filpath = getcwd().s:lash.optyp
		cal s:insertcache(str)
		cal s:PrtExit()
		let cmd = s:newfop == 1 ? 'tabe'
			\ : s:newfop == 2 ? 'new'
			\ : s:newfop == 3 ? 'vne' : ctrlp#normcmd('e')
		cal s:openfile(cmd, filpath)
	en
endf
" * OpenMulti() {{{1
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
	sil! cal ctrlp#statusline()
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
	let cmds = { 'v': 'vne', 'h': 'new', 't': 'tabe' }
	let spt = len(s:opmul) > 1 ? cmds[matchstr(s:opmul, '\w$')] : 'vne'
	let nr = matchstr(s:opmul, '^\d\+')
	exe wnr.'winc w'
	for [ke, va] in items(mkd)
		let cmd = ic == 1 ? 'e' : spt
		cal s:openfile(cmd, va)
		if nr > 1 && nr < ic | clo! | el | let ic += 1 | en
	endfo
endf
" ** Helper functions {{{1
" Sorting {{{2
fu! ctrlp#complen(s1, s2)
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

fu! s:comptime(s1, s2)
	" By last modified time
	let [time1, time2] = [getftime(a:s1), getftime(a:s2)]
	retu time1 == time2 ? 0 : time1 < time2 ? 1 : -1
endf

fu! s:comparent(s1, s2)
	" By same parent dir
	if match(s:crfpath, escape(getcwd(), '.^$*\')) >= 0
		let [as1, as2] = [getcwd().s:lash.a:s1, getcwd().s:lash.a:s2]
		let [loc1, loc2] = [s:getparent(as1), s:getparent(as2)]
		if loc1 == s:crfpath && loc2 != s:crfpath | retu -1 | en
		if loc2 == s:crfpath && loc1 != s:crfpath | retu 1  | en
		retu 0
	en
	retu 0
endf

fu! s:matchlens(str, pat, ...)
	if empty(a:pat) || index(['^','$'], a:pat) >= 0 | retu {} | en
	let st   = exists('a:1') ? a:1 : 0
	let lens = exists('a:2') ? a:2 : {}
	let nr   = exists('a:3') ? a:3 : 0
	if match(a:str, a:pat, st) != -1
		let [mst, mnd] = [matchstr(a:str, a:pat, st), matchend(a:str, a:pat, st)]
		let lens = extend(lens, { nr : [len(mst), mst] })
		let lens = s:matchlens(a:str, a:pat, mnd, lens, nr + 1)
	en
	retu lens
endf

fu! s:shortest(lens)
	retu min(map(values(a:lens), 'v:val[0]'))
endf

fu! s:mixedsort(s1, s2)
	let [cml, cln] = [s:compmatlen(a:s1, a:s2), ctrlp#complen(a:s1, a:s2)]
	if s:itemtype < 3 && s:height < 51
		let par = s:comparent(a:s1, a:s2)
		if s:height < 21
			retu 6 * cml + 3 * par + 2 * s:comptime(a:s1, a:s2) + cln
		en
		retu 3 * cml + 2 * par + cln
	en
	retu 2 * cml + cln
endf
" Statusline {{{2
fu! ctrlp#statusline(...)
	if !exists('s:statypes')
		let s:statypes = [
			\ ['files', 'fil'],
			\ ['buffers', 'buf'],
			\ ['mru files', 'mru'],
			\ ]
		if exists('g:ctrlp_ext_vars')
			cal map(copy(g:ctrlp_ext_vars), 'add(s:statypes, [ v:val[2], v:val[3] ])')
		en
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

fu! ctrlp#progress(len)
	if has('macunix') || has('mac') | sl 1m | en
	let &l:stl = '%#Function# '.a:len.' %* %=%<%#LineNr# '.getcwd().' %*'
	redr
endf
" Paths {{{2
fu! ctrlp#dirfilter(val)
	retu isdirectory(a:val) && match(a:val, '[\/]\.\{,2}$') < 0 ? 1 : 0
endf

fu! s:ispathitem()
	let ext = s:itemtype - ( g:ctrlp_builtins + 1 )
	if s:itemtype < 3 || ( s:itemtype > 2 && g:ctrlp_ext_vars[ext][3] == 'dir' )
		retu 1
	en
	retu 0
endf

fu! ctrlp#rmbasedir(items)
	let path = &ssl || !exists('+ssl') ? getcwd().'/' :
		\ substitute(getcwd(), '\\', '\\\\', 'g').'\\'
	retu map(a:items, 'substitute(v:val, path, "", "g")')
endf

fu! s:parentdir(curr)
	let parent = s:getparent(a:curr)
	if parent != a:curr | cal ctrlp#setdir(parent) | en
endf

fu! s:getparent(item)
	retu split(a:item, '[\/]\ze[^\/]\+[\/:]\?$')[0]
endf

fu! s:getgrand(item)
	retu split(a:item, '[\/]\ze[^\/]\+[\/][^\/]\+[\/:]\?$')[0]
endf

fu! s:createparentdirs(arr)
	for each in a:arr
		let curr = exists('curr') ? curr.s:lash.each : each
		cal ctrlp#utils#mkdir(curr)
	endfo
	retu curr
endf

fu! s:listdirs(path, parent)
	let [str, dirs] = ['', split(s:glbpath(a:path, '*', 1), "\n")]
	for entry in filter(dirs, 'isdirectory(v:val)')
		let str .= a:parent . split(entry, '[\/]')[-1] . "\n"
	endfo
	retu str
endf

fu! ctrlp#cpl(A, L, P)
	let haslash = match(a:A, '[\/]')
	let parent = substitute(a:A, '[^\/]*$', '', 'g')
	let path = !haslash ? parent : haslash > 0 ? getcwd().s:lash.parent : getcwd()
	retu s:listdirs(path, parent)
endf

fu! s:findroot(curr, mark, depth, type)
	let [depth, notfound] = [a:depth + 1, empty(s:glbpath(a:curr, a:mark, 1))]
	if !notfound || depth > s:maxdepth
		if notfound | cal ctrlp#setdir(s:cwd) | en
		if a:type
			let s:vcsroot = depth <= s:maxdepth ? a:curr : ''
		el
			cal ctrlp#setdir(a:curr)
			let s:foundroot = 1
		en
	el
		let parent = s:getparent(a:curr)
		if parent != a:curr | cal s:findroot(parent, a:mark, depth, a:type) | en
	en
endf

fu! s:glbpath(...)
	retu call('globpath',  v:version > 701 ? a:000 : a:000[:1])
endf

fu! ctrlp#fnesc(path)
	retu exists('*fnameescape') ? fnameescape(a:path) : escape(a:path, " %#*?|<\"\n")
endf

fu! ctrlp#setdir(path, ...)
	let cmd = exists('a:1') ? a:1 : 'lc!'
	try
		exe cmd.' '.ctrlp#fnesc(a:path)
	cat
		cal ctrlp#msg("Can't change working dir. Directory not exists.")
	endt
endf
" Highlighting {{{2
fu! s:syntax()
	sy match CtrlPNoEntries '^ == NO ENTRIES ==$'
	sy match CtrlPLineMarker '^>'
	hi link CtrlPNoEntries Error
	hi CtrlPLineMarker guifg=bg
endf

fu! s:highlight(pat, grp)
	cal clearmatches()
	if !empty(a:pat) && a:pat != '..' && s:itemtype < 3
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

fu! s:dohighlight()
	retu type(s:mathi) == 3 && len(s:mathi) == 2 && s:mathi[0]
		\ && exists('*clearmatches')
endf
" Prompt history {{{2
fu! s:gethistloc()
	let cache_dir = ctrlp#utils#cachedir().s:lash.'hist'
	retu [cache_dir, cache_dir.s:lash.'cache.txt']
endf

fu! s:gethistdata()
	retu ctrlp#utils#readfile(s:gethistloc()[1])
endf

fu! ctrlp#recordhist()
	let str = join(s:prompt, '')
	if empty(str) || !s:maxhst | retu | en
	let hst = s:hstry
	if len(hst) > 1 && hst[1] == str | retu | en
	cal extend(hst, [str], 1)
	if len(hst) > s:maxhst | cal remove(hst, s:maxhst, -1) | en
endf
" Signs {{{2
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
" Dictionaries {{{2
fu! s:dictindex(dict, expr)
	for key in keys(a:dict)
		if a:dict[key] == a:expr | retu key | en
	endfo
	retu -1
endf

fu! s:vacantdict(dict)
	retu filter(range(1, max(keys(a:dict))), '!has_key(a:dict, v:val)')
endf
" Buffers {{{2
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

fu! ctrlp#normcmd(cmd)
	if !empty(s:nosplit) && match([bufname('%'), &l:ft], s:nosplit) >= 0
		retu a:cmd
	en
	" Find a regular buffer
	let norwins = s:normbuf()
	let norwin = empty(norwins) ? 0 : norwins[0]
	if norwin
		if index(norwins, winnr()) < 0
			exe norwin.'winc w'
		en
		retu a:cmd
	en
	retu 'bo vne'
endf

fu! s:setupblank()
	setl noswf nobl nonu nowrap nolist nospell nocuc wfh
	setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
	if v:version >= 703
		setl nornu noudf cc=0
	en
endf

fu! s:leavepre()
	if s:clrex && ( !has('clientserver') ||
		\ ( has('clientserver') && len(split(serverlist(), "\n")) == 1 ) )
		cal ctrlp#clra(1)
	en
	cal ctrlp#utils#writecache(s:hstry, s:gethistloc()[0], s:gethistloc()[1])
endf

fu! s:checkbuf()
	if exists('s:init') | retu | en
	if exists('s:bufnr') && s:bufnr > 0
		exe s:bufnr.'bw!'
	en
endf
" Arguments {{{2
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
	en
	retu str
endf
" Misc {{{2
fu! s:specinputs()
	let str = join(s:prompt, '')
	let type = s:itemtype > 2 ?
		\ g:ctrlp_ext_vars[s:itemtype - ( g:ctrlp_builtins + 1 )][3] : s:itemtype
	if str == '..' && type =~ '0\|dir'
		cal s:parentdir(getcwd())
		cal s:SetLines(s:itemtype)
		cal s:PrtClear()
		retu 1
	elsei ( str == '/' || str == '\' ) && type =~ '0\|dir'
		cal s:SetWD(2, 0)
		cal s:SetLines(s:itemtype)
		cal s:PrtClear()
		retu 1
	elsei str == '?'
		cal s:PrtExit()
		let hlpwin = &columns > 159 ? '| vert res 80' : ''
		sil! exe 'bo vert h ctrlp-mappings' hlpwin '| norm! 0'
		retu 1
	en
	retu 0
endf

fu! s:lastvisual()
	let cview = winsaveview()
	let [ovreg, ovtype] = [getreg('v'), getregtype('v')]
	let [oureg, outype] = [getreg('"'), getregtype('"')]
	sil! norm! gv"vy
	let selected = substitute(getreg('v'), '\n', '\\n', 'g')
	cal setreg('v', ovreg, ovtype)
	cal setreg('"', oureg, outype)
	cal winrestview(cview)
	retu selected
endf

fu! ctrlp#msg(msg)
	echoh Identifier | echon "CtrlP: ".a:msg | echoh None
endf

fu! s:openfile(cmd, filpath, ...)
	let cmd = a:cmd == 'e' && &modified ? 'hid e' : a:cmd
	let tail = a:0 ? a:1 : s:tail()
	try
		exe cmd.tail.' '.ctrlp#fnesc(a:filpath)
	cat
		cal ctrlp#msg("Operation can't be completed. Make sure filename is valid.")
	fina
		if !empty(tail)
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

fu! s:j2l(nr)
	exe a:nr
	sil! norm! zOzz
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

fu! s:walker(max, pos, dir)
	retu a:dir > 0 ? a:pos < a:max ? a:pos + 1 : 0 : a:pos > 0 ? a:pos - 1 : a:max
endf

fu! s:matchfname(item, pat)
	retu match(split(a:item, '[\/]\ze[^\/]\+$')[-1], a:pat)
endf

fu! s:matchtab(item, pat)
	retu match(split(a:item, '\t\+[^\t]\+$')[0], a:pat)
endf

fu! s:maxfiles(len)
	retu s:maxfiles && a:len > s:maxfiles ? 1 : 0
endf

fu! s:insertcache(str)
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
	let cmd = s:usrcmd
	if type(cmd) == 1
		retu cmd
	elsei type(cmd) == 3 && len(cmd) >= 2 && !empty(cmd[0]) && !empty(cmd[1])
		let rmarker = cmd[0]
		" Find a repo root
		cal s:findroot(getcwd(), rmarker, 0, 1)
		if !exists('s:vcsroot') || ( exists('s:vcsroot') && empty(s:vcsroot) )
			" Try the secondary_command
			retu len(cmd) == 3 ? cmd[2] : ''
		en
		let s:vcscmd = s:lash == '\' ? 1 : 0
		retu cmd[1]
	en
endf
" Extensions {{{2
fu! s:tagfiles()
	retu filter(map(tagfiles(), 'fnamemodify(v:val, ":p")'), 'filereadable(v:val)')
endf

fu! ctrlp#exit()
	cal s:PrtExit()
endf

fu! ctrlp#prtclear()
	cal s:PrtClear()
endf

fu! ctrlp#setlines(type)
	cal s:SetLines(a:type)
endf
"}}}1
" * Initialization {{{1
fu! s:SetLines(type)
	let s:itemtype = a:type
	let types = [
		\ 's:Files()',
		\ 's:Buffers()',
		\ 'ctrlp#mrufiles#list(-1)',
		\ ]
	if exists('g:ctrlp_ext_vars')
		cal map(copy(g:ctrlp_ext_vars), 'add(types, v:val[0])')
	en
	let g:ctrlp_lines = eval(types[a:type])
endf

fu! ctrlp#init(type, ...)
	if exists('s:init') | retu | en
	let [s:matches, s:init] = [1, 1]
	cal s:Open()
	cal s:SetWD(exists('a:1') ? a:1 : '')
	cal s:MapKeys()
	cal s:SetLines(a:type)
	cal s:BuildPrompt(1)
	if has('syntax') && exists('g:syntax_on')
		cal s:syntax()
	en
endf
if has('autocmd') "{{{1
	aug CtrlPAug
		au!
		au BufEnter ControlP cal s:checkbuf()
		au BufLeave ControlP cal s:Close()
		au VimLeavePre * cal s:leavepre()
		if s:lazy
			au CursorHold ControlP cal s:ForceUpdate()
		en
	aug END
en "}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
