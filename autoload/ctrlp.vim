" =============================================================================
" File:          autoload/ctrlp.vim
" Description:   Fuzzy file, buffer, mru and tag finder.
" Author:        Kien Nguyen <github.com/kien>
" Version:       1.7.4
" =============================================================================

" * Static variables {{{1
fu! s:opts()
	" Options
	let hst = exists('+hi') ? &hi : 20
	let opts = {
		\ 'g:ctrlp_arg_map':               ['s:argmap', 0],
		\ 'g:ctrlp_by_filename':           ['s:byfname', 0],
		\ 'g:ctrlp_clear_cache_on_exit':   ['s:clrex', 1],
		\ 'g:ctrlp_custom_ignore':         ['s:usrign', ''],
		\ 'g:ctrlp_default_input':         ['s:deftxt', 0],
		\ 'g:ctrlp_dont_split':            ['s:nosplit', 'netrw'],
		\ 'g:ctrlp_dotfiles':              ['s:dotfiles', 1],
		\ 'g:ctrlp_extensions':            ['s:extensions', []],
		\ 'g:ctrlp_follow_symlinks':       ['s:folsym', 0],
		\ 'g:ctrlp_highlight_match':       ['s:mathi', [1, 'CtrlPMatch']],
		\ 'g:ctrlp_jump_to_buffer':        ['s:jmptobuf', 2],
		\ 'g:ctrlp_lazy_update':           ['s:lazy', 0],
		\ 'g:ctrlp_match_func':            ['s:matcher', {}],
		\ 'g:ctrlp_match_window_bottom':   ['s:mwbottom', 1],
		\ 'g:ctrlp_match_window_reversed': ['s:mwreverse', 1],
		\ 'g:ctrlp_max_depth':             ['s:maxdepth', 40],
		\ 'g:ctrlp_max_files':             ['s:maxfiles', 10000],
		\ 'g:ctrlp_max_height':            ['s:mxheight', 10],
		\ 'g:ctrlp_max_history':           ['s:maxhst', hst],
		\ 'g:ctrlp_open_multi':            ['s:opmul', '1v'],
		\ 'g:ctrlp_open_new_file':         ['s:newfop', 'v'],
		\ 'g:ctrlp_prompt_mappings':       ['s:urprtmaps', 0],
		\ 'g:ctrlp_regexp_search':         ['s:regexp', 0],
		\ 'g:ctrlp_root_markers':          ['s:rmarkers', []],
		\ 'g:ctrlp_split_window':          ['s:splitwin', 0],
		\ 'g:ctrlp_status_func':           ['s:status', {}],
		\ 'g:ctrlp_use_caching':           ['s:caching', 1],
		\ 'g:ctrlp_use_migemo':            ['s:migemo', 0],
		\ 'g:ctrlp_user_command':          ['s:usrcmd', ''],
		\ 'g:ctrlp_working_path_mode':     ['s:pathmode', 2],
		\ }
	for [ke, va] in items(opts)
		exe 'let' va[0] '=' string(exists(ke) ? eval(ke) : va[1])
	endfo
	let new_opts = {
		\ 'g:ctrlp_open_multiple_files': 's:opmul',
		\ 'g:ctrlp_regexp': 's:regexp',
		\ 'g:ctrlp_reuse_window': 's:nosplit',
		\ 'g:ctrlp_switch_buffer': 's:jmptobuf',
		\ }
	for [key, val] in items(new_opts)
		exe 'let' val '=' string(eval(exists(key) ? key : val))
	endfo
	if !exists('g:ctrlp_newcache') | let g:ctrlp_newcache = 0 | en
	let s:maxdepth = min([s:maxdepth, 100])
	let s:mxheight = max([s:mxheight, 1])
	let s:glob = s:dotfiles ? '.*\|*' : '*'
	let s:igntype = empty(s:usrign) ? -1 : type(s:usrign)
	" Extensions
	for each in s:extensions
		exe 'ru autoload/ctrlp/'.each.'.vim'
	endfo
	" Keymaps
	let [s:lcmap, s:prtmaps] = ['nn <buffer> <silent>', {
		\ 'PrtBS()':              ['<bs>', '<c-]>'],
		\ 'PrtDelete()':          ['<del>'],
		\ 'PrtDeleteWord()':      ['<c-w>'],
		\ 'PrtClear()':           ['<c-u>'],
		\ 'PrtSelectMove("j")':   ['<c-j>', '<down>'],
		\ 'PrtSelectMove("k")':   ['<c-k>', '<up>'],
		\ 'PrtSelectMove("t")':   ['<Home>', '<kHome>'],
		\ 'PrtSelectMove("b")':   ['<End>', '<kEnd>'],
		\ 'PrtSelectMove("u")':   ['<PageUp>', '<kPageUp>'],
		\ 'PrtSelectMove("d")':   ['<PageDown>', '<kPageDown>'],
		\ 'PrtHistory(-1)':       ['<c-n>'],
		\ 'PrtHistory(1)':        ['<c-p>'],
		\ 'AcceptSelection("e")': ['<cr>', '<2-LeftMouse>'],
		\ 'AcceptSelection("h")': ['<c-x>', '<c-cr>', '<c-s>'],
		\ 'AcceptSelection("t")': ['<c-t>', '<MiddleMouse>'],
		\ 'AcceptSelection("v")': ['<c-v>', '<RightMouse>'],
		\ 'ToggleFocus()':        ['<s-tab>'],
		\ 'ToggleRegex()':        ['<c-r>'],
		\ 'ToggleByFname()':      ['<c-d>'],
		\ 'ToggleType(1)':        ['<c-f>', '<c-up>'],
		\ 'ToggleType(-1)':       ['<c-b>', '<c-down>'],
		\ 'PrtExpandDir()':       ['<tab>'],
		\ 'PrtInsert("w")':       ['<F2>', '<insert>'],
		\ 'PrtInsert("s")':       ['<F3>'],
		\ 'PrtInsert("v")':       ['<F4>'],
		\ 'PrtInsert("+")':       ['<F6>'],
		\ 'PrtCurStart()':        ['<c-a>'],
		\ 'PrtCurEnd()':          ['<c-e>'],
		\ 'PrtCurLeft()':         ['<c-h>', '<left>', '<c-^>'],
		\ 'PrtCurRight()':        ['<c-l>', '<right>'],
		\ 'PrtClearCache()':      ['<F5>'],
		\ 'PrtDeleteMRU()':       ['<F7>'],
		\ 'CreateNewFile()':      ['<c-y>'],
		\ 'MarkToOpen()':         ['<c-z>'],
		\ 'OpenMulti()':          ['<c-o>'],
		\ 'PrtExit()':            ['<esc>', '<c-c>', '<c-g>'],
		\ }]
	if !has('gui_running') && ( has('win32') || has('win64') )
		cal add(s:prtmaps['PrtBS()'], remove(s:prtmaps['PrtCurLeft()'], 0))
	en
	if type(s:urprtmaps) == 4
		cal extend(s:prtmaps, s:urprtmaps)
	en
	" Global options
	let s:glbs = { 'magic': 1, 'to': 1, 'tm': 0, 'sb': 1, 'hls': 0, 'im': 0,
		\ 'report': 9999, 'sc': 0, 'ss': 0, 'siso': 0, 'mfd': 200, 'mouse': 'n',
		\ 'gcr': 'a:blinkon0', 'ic': 1, 'scs': 1, 'lmap': '', 'mousef': 0,
		\ 'imd': 1 }
	if s:lazy
		cal extend(s:glbs, { 'ut': ( s:lazy > 1 ? s:lazy : 250 ) })
	en
endf
cal s:opts()

let s:lash = ctrlp#utils#lash()

" Limiters
let [s:compare_lim, s:nocache_lim] = [3000, 4000]

" Regexp
let s:fpats = {
	\ '^\(\\|\)\|\(\\|\)$': '\\|',
	\ '^\\\(zs\|ze\|<\|>\)': '^\\\(zs\|ze\|<\|>\)',
	\ '^\S\*$': '\*',
	\ '^\S\\?$': '\\?',
	\ }

" Mappings
let s:prtunmaps = [
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

" Keypad
let s:kprange = {
	\ 'Plus': '+',
	\ 'Minus': '-',
	\ 'Divide': '/',
	\ 'Multiply': '*',
	\ 'Point': '.',
	\ }

" Highlight groups
let s:hlgrps = {
	\ 'NoEntries': 'Error',
	\ 'Mode1': 'Character',
	\ 'Mode2': 'LineNr',
	\ 'Stats': 'Function',
	\ 'Match': 'Identifier',
	\ 'PrtBase': 'Comment',
	\ 'PrtText': 'Normal',
	\ 'PrtCursor': 'Constant',
	\ }
" * Open & Close {{{1
fu! s:Open()
	cal s:log(1)
	cal s:getenv()
	cal s:execextvar('enter')
	sil! exe 'noa keepa' ( s:mwbottom ? 'bo' : 'to' ) '1new ControlP'
	let [s:bufnr, s:prompt, s:winw] = [bufnr('%'), ['', '', ''], winwidth(0)]
	abc <buffer>
	if !exists('s:hstry')
		let hst = filereadable(s:gethistloc()[1]) ? s:gethistdata() : ['']
		let s:hstry = empty(hst) || !s:maxhst ? [''] : hst
	en
	for [ke, va] in items(s:glbs) | if exists('+'.ke)
		sil! exe 'let s:glb_'.ke.' = &'.ke.' | let &'.ke.' = '.string(va)
	en | endfo
	if s:opmul != '0' && has('signs')
		sign define ctrlpmark text=+> texthl=Search
	en
	cal s:setupblank()
endf

fu! s:Close()
	try | noa bun!
	cat | noa clo! | endt
	cal s:unmarksigns()
	for key in keys(s:glbs) | if exists('+'.key)
		sil! exe 'let &'.key.' = s:glb_'.key
	en | endfo
	if exists('s:glb_acd') | let &acd = s:glb_acd | en
	let [g:ctrlp_lines, g:ctrlp_allfiles] = [[], []]
	if s:winres[1] >= &lines && s:winres[2] == winnr('$')
		exe s:winres[0]
	en
	unl! s:focus s:hisidx s:hstgot s:marked s:statypes s:cline s:init s:savestr
		\ g:ctrlp_nolimit
	cal ctrlp#recordhist()
	cal s:execextvar('exit')
	cal s:log(0)
	ec
endf
" * Clear caches {{{1
fu! ctrlp#clr(...)
	exe 'let g:ctrlp_new'.( a:0 ? a:1 : 'cache' ).' = 1'
endf

fu! ctrlp#clra()
	let cache_dir = ctrlp#utils#cachedir()
	if isdirectory(cache_dir)
		let cache_files = split(s:glbpath(cache_dir, '**', 1), "\n")
		let eval = '!isdirectory(v:val) && v:val !~ ''\<cache\.txt$\|\.log$'''
		sil! cal map(filter(cache_files, eval), 'delete(v:val)')
	en
	cal ctrlp#clr()
endf

fu! ctrlp#reset()
	cal s:opts()
	cal s:autocmds()
	cal ctrlp#utils#opts()
	cal ctrlp#mrufiles#opts()
	cal s:execextvar('opts')
endf
" * Files {{{1
fu! ctrlp#files()
	let [cwd, cafile, g:ctrlp_allfiles] = [getcwd(), ctrlp#utils#cachefile(), []]
	if g:ctrlp_newcache || !filereadable(cafile) || !s:caching
		let lscmd = s:lsCmd()
		" Get the list of files
		if empty(lscmd)
			cal s:GlobPath(cwd, 0)
		el
			sil! cal ctrlp#progress('Indexing...')
			try | cal s:UserCmd(cwd, lscmd)
			cat | retu [] | endt
		en
		" Remove base directory
		cal ctrlp#rmbasedir(g:ctrlp_allfiles)
		let read_cache = 0
		if len(g:ctrlp_allfiles) <= s:compare_lim
			cal sort(g:ctrlp_allfiles, 'ctrlp#complen')
		en
	el
		let g:ctrlp_allfiles = ctrlp#utils#readfile(cafile)
		let read_cache = 1
	en
	cal s:writecache(read_cache, cafile)
	retu g:ctrlp_allfiles
endf

fu! s:GlobPath(dirs, depth)
	let entries = split(globpath(a:dirs, s:glob), "\n")
	let [dnf, depth] = [ctrlp#dirnfile(entries), a:depth + 1]
	cal extend(g:ctrlp_allfiles, dnf[1])
	if !empty(dnf[0]) && !s:maxf(len(g:ctrlp_allfiles)) && depth <= s:maxdepth
		sil! cal ctrlp#progress(len(g:ctrlp_allfiles))
		cal s:GlobPath(join(dnf[0], ','), depth)
	en
endf

fu! s:UserCmd(path, lscmd)
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

fu! s:lsCmd()
	let cmd = s:usrcmd
	if type(cmd) == 1
		retu cmd
	elsei type(cmd) == 3 && len(cmd) >= 2 && cmd[:1] != ['', '']
		" Find a repo root
		cal s:findroot(getcwd(), cmd[0], 0, 1)
		if !exists('s:vcsroot')
			" Try the secondary_command
			retu len(cmd) == 3 ? cmd[2] : ''
		en
		unl s:vcsroot
		let s:vcscmd = s:lash == '\' ? 1 : 0
		retu cmd[1]
	elsei type(cmd) == 4 && has_key(cmd, 'types')
		for key in sort(keys(cmd['types']), 's:compval')
			cal s:findroot(getcwd(), cmd['types'][key][0], 0, 1)
			if exists('s:vcsroot') | brea | en
		endfo
		if !exists('s:vcsroot')
			retu has_key(cmd, 'fallback') ? cmd['fallback'] : ''
		en
		unl s:vcsroot
		let s:vcscmd = s:lash == '\' ? 1 : 0
		retu cmd['types'][key][1]
	en
endf
" - Buffers {{{1
fu! ctrlp#buffers()
	retu map(filter(range(1, bufnr('$')), 'empty(getbufvar(v:val, "&bt"))'
		\ .' && getbufvar(v:val, "&bl") && strlen(bufname(v:val))'),
		\ 'fnamemodify(bufname(v:val), ":.")')
endf
" * MatchedItems() {{{1
fu! s:MatchIt(items, pat, limit, mfunc, ipt, exc)
	let [newitems, id] = [[], 0]
	for item in a:items
		let id += 1
		try | if !( a:ipt && item == a:exc ) && call(a:mfunc, [item, a:pat]) >= 0
			cal add(newitems, item)
		en | cat | brea | endt
		if a:limit > 0 && len(newitems) >= a:limit | brea | en
	endfo
	let s:mdata = [s:dyncwd, s:itemtype, s:regexp, s:sublist(a:items, id, -1)]
	retu newitems
endf

fu! s:MatchedItems(items, str, pat, limit, ipt)
	let [type, mfunc] = [s:type(1), 'match']
	if s:byfname && a:ipt
		let mfunc = 's:matchfname'
	elsei s:itemtype > 2
		let types = { 'tabs': 's:matchtabs', 'tabe': 's:matchtabe' }
		if has_key(types, type) | let mfunc = types[type] | en
	en
	let exc = exists('s:crfilerel') ? s:crfilerel : ''
	let matfunc = 's:MatchIt'
	let items = s:narrowable() ? s:matched + s:mdata[3] : a:items
	let argms = [items, a:pat, a:limit, mfunc, a:ipt, exc]
	if s:matcher != {} && has_key(s:matcher, 'match')
		let [matfunc, argms[1], argms[3]] = s:matargs(mfunc, a:str)
		let argms += [s:regexp]
	en
	let newitems = call(matfunc, argms)
	let s:matches = len(newitems)
	retu newitems
endf

fu! s:SplitPattern(str)
	let str = a:str
	if s:migemo && s:regexp && len(str) > 0 && executable('cmigemo')
		let str = s:migemo(str)
	en
	let s:savestr = str
	if s:regexp || match(str, '\\\(<\|>\)\|[*|]') >= 0
		let pat = s:regexfilter(str)
	el
		let lst = split(str, '\zs')
		if exists('+ssl') && !&ssl
			cal map(lst, 'escape(v:val, ''\'')')
		en
		for each in ['^', '$', '.']
			cal map(lst, 'escape(v:val, each)')
		endfo
	en
	if exists('lst')
		let pat = ''
		if !empty(lst)
			let pat = lst[0]
			for item in range(1, len(lst) - 1)
				let pat .= '[^'.lst[item - 1].']\{-}'.lst[item]
			endfo
		en
	en
	retu escape(pat, '~')
endf
" * BuildPrompt() {{{1
fu! s:Render(lines, pat, ipt)
	let [&ma, lines, s:height] = [1, a:lines, min([len(a:lines), s:winh])]
	" Setup the match window
	sil! exe '%d _ | res' s:height
	" Print the new items
	if empty(lines)
		let [s:matched, s:lines] = [[], []]
		cal setline(1, ' == NO ENTRIES ==')
		setl noma nocul
		cal s:unmarksigns()
		if s:dohighlight() | cal clearmatches() | en
		retu
	en
	" Sorting
	if s:dosort()
		let s:compat = a:pat
		cal sort(lines, 's:mixedsort')
		unl s:compat
	en
	let s:matched = copy(lines)
	if s:mwreverse | cal reverse(lines) | en
	let s:lines = copy(lines)
	cal map(lines, 's:formatline(v:val, a:ipt)')
	cal setline(1, lines)
	setl noma cul
	exe 'keepj norm!' ( s:mwreverse ? 'G' : 'gg' ).'1|'
	cal s:unmarksigns()
	cal s:remarksigns()
	if exists('s:cline') && !exists('g:ctrlp_nolimit')
		cal cursor(s:cline, 1)
	en
	" Highlighting
	if s:dohighlight()
		cal s:highlight(a:pat, s:mathi[1], a:ipt)
	en
endf

fu! s:Update(str)
	" Get the previous string if existed
	let oldstr = exists('s:savestr') ? s:savestr : ''
	" Get the new string sans tail
	let str = s:sanstail(a:str)
	" Stop if the string's unchanged
	if str == oldstr && !empty(str) && !exists('s:force') | retu | en
	let [pat, ipt] = [s:SplitPattern(str), s:ispathitem()]
	let lines = exists('g:ctrlp_nolimit') && empty(str) ? copy(g:ctrlp_lines)
		\ : s:MatchedItems(g:ctrlp_lines, str, pat, s:winh, ipt)
	cal s:Render(lines, pat, ipt)
endf

fu! s:ForceUpdate()
	let [estr, prt] = ['"\', copy(s:prompt)]
	cal map(prt, 'escape(v:val, estr)')
	sil! cal s:Update(join(prt, ''))
endf

fu! s:BuildPrompt(upd, ...)
	let base = ( s:regexp ? 'r' : '>' ).( s:byfname ? 'd' : '>' ).'> '
	let [estr, prt] = ['"\', copy(s:prompt)]
	cal map(prt, 'escape(v:val, estr)')
	let str = join(prt, '')
	let lazy = empty(str) || exists('s:force') || !has('autocmd') ? 0 : s:lazy
	if a:upd && !lazy && ( s:matches || s:regexp
		\ || match(str, '\(\\\(<\|>\)\|[*|]\)\|\(\\\:\([^:]\|\\:\)*$\)') >= 0 )
		sil! cal s:Update(str)
	en
	sil! cal ctrlp#statusline()
	" Toggling
	let [hiactive, hicursor, base] = a:0 && !a:1
		\ ? ['CtrlPPrtBase', 'CtrlPPrtBase', tr(base, '>', '-')]
		\ : ['CtrlPPrtText', 'CtrlPPrtCursor', base]
	let hibase = 'CtrlPPrtBase'
	" Build it
	redr
	exe 'echoh' hibase '| echon "'.base.'"
		\ | echoh' hiactive '| echon "'.prt[0].'"
		\ | echoh' hicursor '| echon "'.prt[1].'"
		\ | echoh' hiactive '| echon "'.prt[2].'" | echoh None'
	" Append the cursor at the end
	if empty(prt[1]) && !( a:0 && !a:1 )
		exe 'echoh' hibase '| echon "_" | echoh None'
	en
endf
" - SetDefTxt() {{{1
fu! s:SetDefTxt()
	if s:deftxt == '0' || s:pathmode == 1 | retu | en
	let txt = s:deftxt
	if !type(txt)
		let txt = txt && !stridx(s:crfpath, s:dyncwd)
			\ ? ctrlp#rmbasedir([s:crfpath])[0] : ''
		let txt = txt != '' ? txt.s:lash(s:crfpath) : ''
	en
	let s:prompt[0] = txt
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
	let s:act_add = 1
	let s:prompt[0] .= a:char
	cal s:BuildPrompt(1)
	unl s:act_add
endf

fu! s:PrtBS()
	unl! s:hstgot
	let [s:prompt[0], s:matches] = [substitute(s:prompt[0], '.$', '', ''), 1]
	cal s:BuildPrompt(1)
endf

fu! s:PrtDelete()
	unl! s:hstgot
	let [prt, s:matches] = [s:prompt, 1]
	let prt[1] = matchstr(prt[2], '^.')
	let prt[2] = substitute(prt[2], '^.', '', '')
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
	let s:act_add = 1
	let s:prompt[0] .= a:type == 'w' ? s:crword
		\ : a:type == 's' ? getreg('/')
		\ : a:type == 'v' ? s:crvisual
		\ : a:type == '+' ? substitute(getreg('+'), '\n', '\\n', 'g') : s:prompt[0]
	cal s:BuildPrompt(1)
	unl s:act_add
endf

fu! s:PrtExpandDir()
	let prt = s:prompt
	if prt[0] == '' | retu | en
	unl! s:hstgot
	let s:act_add = 1
	let [base, seed] = s:headntail(prt[0])
	let dirs = s:dircompl(base, seed)
	if len(dirs) == 1
		let prt[0] = dirs[0]
	elsei len(dirs) > 1
		let prt[0] .= s:findcommon(dirs, prt[0])
	en
	cal s:BuildPrompt(1)
	unl s:act_add
endf
" Movement {{{2
fu! s:PrtCurLeft()
	let prt = s:prompt
	if !empty(prt[0])
		let s:prompt = [substitute(prt[0], '.$', '', ''), matchstr(prt[0], '.$'),
			\ prt[1] . prt[2]]
	en
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurRight()
	let prt = s:prompt
	let s:prompt = [prt[0] . prt[1], matchstr(prt[2], '^.'),
		\ substitute(prt[2], '^.', '', '')]
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurStart()
	let str = join(s:prompt, '')
	let s:prompt = ['', matchstr(str, '^.'), substitute(str, '^.', '', '')]
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurEnd()
	let s:prompt = [join(s:prompt, ''), '', '']
	cal s:BuildPrompt(0)
endf

fu! s:PrtSelectMove(dir)
	let wht = winheight(0)
	let dirs = {'t': 'gg','b': 'G','j': 'j','k': 'k','u': wht.'k','d': wht.'j'}
	exe 'keepj norm!' dirs[a:dir]
	if !exists('g:ctrlp_nolimit') | let s:cline = line('.') | en
	if line('$') > winheight(0) | cal s:BuildPrompt(0, s:Focus()) | en
endf

fu! s:PrtSelectJump(char, ...)
	let lines = copy(s:lines)
	if a:0
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
		if !exists('g:ctrlp_nolimit') | let s:cline = line('.') | en
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
		let g:ctrlp_lines = ctrlp#mrufiles#refresh()
	el
		cal ctrlp#setlines(s:itemtype)
	en
	let s:force = 1
	cal s:BuildPrompt(1)
	unl s:force
endf

fu! s:PrtDeleteMRU()
	if s:itemtype != 2 | retu | en
	let [s:force, tbrem] = [1, []]
	if exists('s:marked')
		let tbrem = values(s:marked)
		cal s:unmarksigns()
		unl s:marked
	en
	let g:ctrlp_lines = ctrlp#mrufiles#remove(tbrem)
	cal s:BuildPrompt(1)
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
	let [s:hisidx, s:hstgot, s:force] = [idx, 1, 1]
	cal s:BuildPrompt(1)
	unl s:force
endf
"}}}1
" * MapKeys() {{{1
fu! s:MapKeys(...)
	" Normal keys
	let pfunc = a:0 && !a:1 ? 'PrtSelectJump' : 'PrtAdd'
	let dojmp = s:byfname && a:0 && !a:1 ? ', 1' : ''
	let pcmd = "nn \<buffer> \<silent> \<k%s> :\<c-u>cal \<SID>%s(\"%s\"%s)\<cr>"
	let cmd = substitute(pcmd, 'k%s', 'char-%d', '')
	for each in range(32, 126)
		exe printf(cmd, each, pfunc, escape(nr2char(each), '"|\'), dojmp)
	endfo
	for each in range(0, 9)
		exe printf(pcmd, each, pfunc, each, dojmp)
	endfo
	for [ke, va] in items(s:kprange)
		exe printf(pcmd, ke, pfunc, va, dojmp)
	endfo
	" Special keys
	if a:0 < 2
		cal call('s:MapSpecs', a:0 && !a:1 ? [1] : [])
	en
endf

fu! s:MapSpecs(...)
	" Correct arrow keys in terminal
	if ( has('termresponse') && match(v:termresponse, "\<ESC>") >= 0 )
		\ || &term =~? 'xterm\|\<k\?vt\|gnome\|screen\|linux'
		for each in ['\A <up>','\B <down>','\C <right>','\D <left>']
			exe s:lcmap.' <esc>['.each
		endfo
	en
	if a:0
		for ke in s:prtunmaps | for kp in s:prtmaps[ke]
			exe s:lcmap kp '<Nop>'
		endfo | endfo
	el
		for [ke, va] in items(s:prtmaps) | for kp in va
			exe s:lcmap kp ':<c-u>cal <SID>'.ke.'<cr>'
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
	let s:itemtype = s:walker(2 + ext, s:itemtype, a:dir)
	if s:byfname && !s:ispathitem() | let s:byfname = 0 | en
	unl! g:ctrlp_nolimit
	if has('syntax') && exists('g:syntax_on')
		cal ctrlp#syntax()
	en
	cal ctrlp#setlines(s:itemtype)
	cal s:PrtSwitcher()
endf

fu! s:PrtSwitcher()
	let [s:force, s:matches] = [1, 1]
	cal s:BuildPrompt(1, s:Focus())
	unl s:force
endf
" - SetWD() {{{1
fu! s:SetWD(...)
	let pathmode = s:wpmode
	let [s:crfilerel, s:dyncwd] = [fnamemodify(s:crfile, ':.'), getcwd()]
	if a:0 && strlen(a:1) | if type(a:1)
		cal ctrlp#setdir(a:1) | retu
	el
		let pathmode = a:1
	en | en
	if a:0 < 2
		if match(s:crfile, '^\<.\+\>://.*') >= 0 || !pathmode | retu | en
		if exists('+acd') | let [s:glb_acd, &acd] = [&acd, 0] | en
		cal ctrlp#setdir(s:crfpath)
	en
	if pathmode == 1 | retu | en
	let markers = ['root.dir', '.git/', '.hg/', '.svn/', '.bzr/', '_darcs/']
	if type(s:rmarkers) == 3 && !empty(s:rmarkers)
		cal extend(markers, s:rmarkers, 0)
	en
	for marker in markers
		cal s:findroot(s:dyncwd, marker, 0, 0)
		if exists('s:foundroot') | brea | en
	endfo
	unl! s:foundroot
endf
" * AcceptSelection() {{{1
fu! ctrlp#acceptfile(mode, line, ...)
	let [md, filpath] = [a:mode, fnamemodify(a:line, ':p')]
	cal s:PrtExit()
	let [bufnr, tail] = [bufnr('^'.filpath.'$'), s:tail()]
	let j2l = a:0 ? a:1 : str2nr(matchstr(tail, '^ +\D*\zs\d\+\ze\D*'))
	if s:jmptobuf && bufnr > 0 && md =~ 'e\|t'
		let [jmpb, bufwinnr] = [1, bufwinnr(bufnr)]
		let buftab = s:jmptobuf > 1 ? s:buftab(bufnr, md) : [0, 0]
	en
	" Switch to existing buffer or open new one
	if exists('jmpb') && bufwinnr > 0 && md != 't'
		exe bufwinnr.'winc w'
		if j2l | cal ctrlp#j2l(j2l) | en
	elsei exists('jmpb') && buftab[0]
		exe 'tabn' buftab[0]
		exe buftab[1].'winc w'
		if j2l | cal ctrlp#j2l(j2l) | en
	el
		" Determine the command to use
		let useb = bufnr > 0 && getbufvar(bufnr, '&bl') && empty(tail)
		let cmd =
			\ md == 't' || s:splitwin == 1 ? ( useb ? 'tab sb' : 'tabe' ) :
			\ md == 'h' || s:splitwin == 2 ? ( useb ? 'sb' : 'new' ) :
			\ md == 'v' || s:splitwin == 3 ? ( useb ? 'vert sb' : 'vne' ) :
			\ call('ctrlp#normcmd', useb ? ['b', 'bo vert sb'] : ['e'])
		" Reset &switchbuf option
		if useb
			let [swb, &swb] = [&swb, '']
		en
		" Open new window/buffer
		let args = [cmd, useb ? bufnr : filpath, a:0 ? ' +'.a:1 : tail, useb, j2l]
		cal call('s:openfile', args)
		if useb
			let &swb = swb
		en
	en
endf

fu! s:SpecInputs(str)
	let [str, type] = [a:str, s:type()]
	if str == '..' && type =~ '\v^(0|dir)$'
		cal s:parentdir(getcwd())
		cal ctrlp#setlines(s:itemtype)
		cal s:PrtClear()
		retu 1
	elsei str =~ '^[\/]$' && type =~ '\v^(0|dir)$'
		cal s:SetWD(2, 0)
		cal ctrlp#setlines(s:itemtype)
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

fu! s:AcceptSelection(mode)
	let str = join(s:prompt, '')
	if a:mode == 'e' | if s:SpecInputs(str) | retu | en | en
	" Get the selected line
	let line = !empty(s:lines) ? s:lines[line('.') - 1] : ''
	if a:mode != 'e' && s:itemtype < 3 && line == ''
		\ && str !~ '\v^(\.\.|/|\\|\?)$'
		cal s:CreateNewFile(a:mode) | retu
	en
	if empty(line) | retu | en
	" Do something with it
	let actfunc = s:itemtype < 3 ? 'ctrlp#acceptfile'
		\ : g:ctrlp_ext_vars[s:itemtype - 3]['accept']
	cal call(actfunc, [a:mode, line])
endf
" - CreateNewFile() {{{1
fu! s:CreateNewFile(...)
	let [md, str] = ['', join(s:prompt, '')]
	if empty(str) | retu | en
	if s:argmap && !a:0
		" Get the extra argument
		let md = s:argmaps(md, 1)
		if md == 'cancel' | retu | en
	en
	let str = s:sanstail(str)
	let [base, fname] = s:headntail(str)
	if fname =~ '^[\/]$' | retu | en
	if exists('s:marked') && len(s:marked)
		" Use the first marked file's path
		let path = fnamemodify(values(s:marked)[0], ':p:h')
		let base = path.s:lash(path).base
		let str = fnamemodify(base.s:lash.fname, ':.')
	en
	if base != '' | if isdirectory(ctrlp#utils#mkdir(base))
		let optyp = str | en | el | let optyp = fname
	en
	if !exists('optyp') | retu | en
	let [filpath, tail] = [fnamemodify(optyp, ':p'), s:tail()]
	if !stridx(filpath, getcwd()) | cal s:insertcache(str) | en
	cal s:PrtExit()
	let cmd = md == 'r' ? ctrlp#normcmd('e') :
		\ s:newfop =~ '1\|t' || ( a:0 && a:1 == 't' ) || md == 't' ? 'tabe' :
		\ s:newfop =~ '2\|h' || ( a:0 && a:1 == 'h' ) || md == 'h' ? 'new' :
		\ s:newfop =~ '3\|v' || ( a:0 && a:1 == 'v' ) || md == 'v' ? 'vne' :
		\ ctrlp#normcmd('e')
	cal s:openfile(cmd, filpath, tail)
endf
" * OpenMulti() {{{1
fu! s:MarkToOpen()
	if s:bufnr <= 0 || s:opmul == '0' || ( s:itemtype > 2 && s:type() !~ 'rts' )
		retu
	en
	let line = !empty(s:lines) ? s:lines[line('.') - 1] : ''
	if empty(line) | retu | en
	let filpath = fnamemodify(line, ':p')
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
	if !exists('s:marked') || s:opmul == '0' | retu | en
	" Get the options
	let [nr, md, ucr] = matchlist(s:opmul, '\v^(\d+)=(\w)=(\w)=$')[1:3]
	if s:argmap
		let md = s:argmaps(md)
		if md == 'cancel' | retu | en
	en
	let mkd = values(s:marked)
	cal s:sanstail(join(s:prompt, ''))
	cal s:PrtExit()
	" Move the cursor to a reusable window
	let [tail, fnesc] = [s:tail(), exists('*fnameescape') && v:version > 701]
	let [emptytail, nwpt] = [empty(tail), exists('g:ctrlp_open_multiple_files')]
	let bufnr = bufnr('^'.mkd[0].'$')
	let useb = bufnr > 0 && getbufvar(bufnr, '&bl') && emptytail
	let fst = call('ctrlp#normcmd', useb ? ['b', 'bo vert sb'] : ['e'])
	" Check if it's a replaceable buffer
	let repabl = ( empty(bufname('%')) && empty(&l:ft) ) || s:nosplit()
	" Commands for the rest of the files
	let [ic, cmds] = [1, { 'v': ['vert sb', 'vne'], 'h': ['sb', 'new'],
		\ 't': ['tab sb', 'tabe'] }]
	let [swb, &swb] = [&swb, '']
	" Open the files
	for va in mkd
		let bufnr = bufnr('^'.va.'$')
		let useb = bufnr > 0 && getbufvar(bufnr, '&bl') && emptytail
		let snd = md != '' && has_key(cmds, md) ?
			\ ( useb ? cmds[md][0] : cmds[md][1] ) : ( useb ? 'vert sb' : 'vne' )
		let cmd = ic == 1 && ( ucr == 'r' || repabl ) ? fst : snd
		let conds = [( nr != '' && nr > 1 && nr < ic ) || ( nr == '' && ic > 1 ),
			\ nr != '' && nr < ic]
		if conds[nwpt]
			if bufnr <= 0 | if fnesc
				cal s:openfile('bad', fnamemodify(va, ':.'), '')
			el
				cal s:openfile(cmd, va, tail) | sil! hid clo!
			en | en
		el
			cal s:openfile(cmd, useb ? bufnr : va, tail) | let ic += 1
		en
	endfo
	let &swb = swb
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

fu! s:compmre(...)
	" By last entered time (buffer only)
	if !exists('s:mrbs')
		let s:mrbs = ctrlp#mrufiles#bufs()
	en
	let cwd = getcwd()
	retu index(s:mrbs, cwd.s:lash().a:1) - index(s:mrbs, cwd.s:lash().a:2)
endf

fu! s:comparent(s1, s2)
	" By same parent dir
	let cwd = getcwd()
	if match(s:crfpath, escape(cwd, '.^$*\')) >= 0
		let [as1, as2] = [cwd.s:lash().a:s1, cwd.s:lash().a:s2]
		let [loc1, loc2] = [s:getparent(as1), s:getparent(as2)]
		if loc1 == s:crfpath && loc2 != s:crfpath | retu -1 | en
		if loc2 == s:crfpath && loc1 != s:crfpath | retu 1  | en
		retu 0
	en
	retu 0
endf

fu! s:compfnlen(s1, s2)
	" By filename length
	let len1 = strlen(split(a:s1, s:lash)[-1])
	let len2 = strlen(split(a:s2, s:lash)[-1])
	retu len1 == len2 ? 0 : len1 > len2 ? 1 : -1
endf

fu! s:matchlens(str, pat, ...)
	if empty(a:pat) || index(['^', '$'], a:pat) >= 0 | retu {} | en
	let st   = a:0 ? a:1 : 0
	let lens = a:0 >= 2 ? a:2 : {}
	let nr   = a:0 >= 3 ? a:3 : 0
	if nr > 20 | retu {} | en
	if match(a:str, a:pat, st) >= 0
		let [mst, mnd] = [matchstr(a:str, a:pat, st), matchend(a:str, a:pat, st)]
		let lens = extend(lens, { nr : [strlen(mst), mst] })
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
		let [par, cfn] = [s:comparent(a:s1, a:s2), s:compfnlen(a:s1, a:s2)]
		if s:height < 21
			let [muls, ctm] = s:itemtype == 1
				\ ? [[6, 3, 2, 12], s:compmre(a:s1, a:s2)]
				\ : [[12, 6, 3, 2], s:comptime(a:s1, a:s2)]
			unl! s:mrbs
			retu muls[0] * cml + muls[1] * par + muls[2] * cfn + muls[3] * ctm + cln
		en
		retu 6 * cml + 3 * par + 2 * cfn + cln
	en
	retu 2 * cml + cln
endf

fu! s:compval(...)
	retu a:1 - a:2
endf
" Statusline {{{2
fu! ctrlp#statusline()
	if !exists('s:statypes')
		let s:statypes = [
			\ ['files', 'fil'],
			\ ['buffers', 'buf'],
			\ ['mru files', 'mru'],
			\ ]
		if exists('g:ctrlp_ext_vars')
			cal map(copy(g:ctrlp_ext_vars),
				\ 'add(s:statypes, [ v:val["lname"], v:val["sname"] ])')
		en
	en
	let tps = s:statypes
	let max = len(tps) - 1
	let nxt = tps[s:walker(max, s:itemtype,  1)][1]
	let prv = tps[s:walker(max, s:itemtype, -1)][1]
	let item = tps[s:itemtype][0]
	let focus   = s:Focus() ? 'prt'  : 'win'
	let byfname = s:byfname ? 'file' : 'path'
	let marked  = s:opmul != '0' ?
		\ exists('s:marked') ? ' <'.s:dismrk().'>' : ' <->' : ''
	if s:status != {} && has_key(s:status, 'main')
		let args = [focus, byfname, s:regexp, prv, item, nxt, marked]
		let &l:stl = call(s:status['main'], args)
	el
		let item    = '%#CtrlPMode1# '.item.' %*'
		let focus   = '%#CtrlPMode2# '.focus.' %*'
		let byfname = '%#CtrlPMode1# '.byfname.' %*'
		let regex   = s:regexp  ? '%#CtrlPMode2# regex %*' : ''
		let slider  = ' <'.prv.'>={'.item.'}=<'.nxt.'>'
		let dir     = ' %=%<%#CtrlPMode2# '.getcwd().' %*'
		let &l:stl  = focus.byfname.regex.slider.marked.dir
	en
endf

fu! s:dismrk()
	retu has('signs') ? len(s:marked) :
		\ '%<'.join(values(map(copy(s:marked), 'split(v:val, "[\\/]")[-1]')), ', ')
endf

fu! ctrlp#progress(enum)
	if has('macunix') || has('mac') | sl 1m | en
	let &l:stl = s:status != {} && has_key(s:status, 'prog')
		\ ? call(s:status['prog'], [a:enum])
		\ : '%#CtrlPStats# '.a:enum.' %* %=%<%#CtrlPMode2# '.getcwd().' %*'
	redraws
endf
" Paths {{{2
fu! s:formatline(str, ipt)
	let cond = a:ipt && ( s:winw - 4 ) < s:strwidth(a:str)
	retu '> '.( cond ? pathshorten(a:str) : a:str )
endf

fu! s:dircompl(be, sd)
	if a:sd == '' | retu [] | en
	let [be, sd] = a:be == '' ? [getcwd(), a:sd] : [a:be, a:be.s:lash(a:be).a:sd]
	let dirs = ctrlp#rmbasedir(split(globpath(be, a:sd.'*/'), "\n"))
	cal filter(dirs, '!match(v:val, escape(sd, ''~$.\''))'
		\ . ' && match(v:val, ''\v(^|[\/])\.{1,2}[\/]$'') < 0')
	retu dirs
endf

fu! s:findcommon(items, seed)
	let [items, id, cmn, ic] = [copy(a:items), strlen(a:seed), '', 0]
	cal map(items, 'strpart(v:val, id)')
	for char in split(items[0], '\zs')
		for item in items[1:]
			if item[ic] != char | let brk = 1 | brea | en
		endfo
		if exists('brk') | brea | en
		let cmn .= char
		let ic += 1
	endfo
	retu cmn
endf

fu! s:headntail(str)
	let parts = split(a:str, '[\/]\ze[^\/]\+[\/:]\?$')
	retu len(parts) == 1 ? ['', parts[0]] : len(parts) == 2 ? parts : []
endf

fu! s:lash(...)
	retu match(a:0 ? a:1 : getcwd(), '[\/]$') < 0 ? s:lash : ''
endf

fu! s:ispathitem()
	retu s:itemtype < 3 ||
		\ ( s:itemtype > 2 && g:ctrlp_ext_vars[s:itemtype - 3]['type'] == 'path' )
endf

fu! ctrlp#dirnfile(entries)
	let [items, cwd] = [[[], []], getcwd().s:lash()]
	for each in a:entries
		let etype = getftype(each)
		if s:igntype >= 0 && s:usrign(each, etype) | con | en
		if etype == 'dir'
			if s:dotfiles | if match(each, '[\/]\.\{1,2}$') < 0
				cal add(items[0], each)
			en | el
				cal add(items[0], each)
			en
		elsei etype == 'link'
			if s:folsym
				let isfile = !isdirectory(each)
				if !s:samerootsyml(each, isfile, cwd)
					cal add(items[isfile], each)
				en
			en
		elsei etype == 'file'
			cal add(items[1], each)
		en
	endfo
	retu items
endf

fu! s:usrign(item, type)
	retu s:igntype == 1 ? a:item =~ s:usrign
		\ : s:igntype == 4 && has_key(s:usrign, a:type) && s:usrign[a:type] != ''
		\ ? a:item =~ s:usrign[a:type] : 0
endf

fu! s:samerootsyml(each, isfile, cwd)
	let resolve = fnamemodify(resolve(a:each), ':p:h')
	let resolve .= s:lash(resolve)
	retu !( stridx(resolve, a:cwd) && ( stridx(a:cwd, resolve) || a:isfile ) )
endf

fu! ctrlp#rmbasedir(items)
	let cwd = getcwd()
	if a:items != [] && !stridx(a:items[0], cwd)
		let idx = strlen(cwd) + ( match(cwd, '[\/]$') < 0 )
		retu map(a:items, 'strpart(v:val, idx)')
	en
	retu a:items
endf

fu! s:parentdir(curr)
	let parent = s:getparent(a:curr)
	if parent != a:curr | cal ctrlp#setdir(parent) | en
endf

fu! s:getparent(item)
	let parent = substitute(a:item, '[\/][^\/]\+[\/:]\?$', '', '')
	if parent == '' || match(parent, '[\/]') < 0
		let parent .= s:lash
	en
	retu parent
endf

fu! s:findroot(curr, mark, depth, type)
	let [depth, notfound] = [a:depth + 1, empty(s:glbpath(a:curr, a:mark, 1))]
	if !notfound || depth > s:maxdepth
		if notfound | cal ctrlp#setdir(s:cwd) | en
		if a:type && depth <= s:maxdepth
			let s:vcsroot = a:curr
		elsei !a:type && !notfound
			cal ctrlp#setdir(a:curr) | let s:foundroot = 1
		en
	el
		let parent = s:getparent(a:curr)
		if parent != a:curr | cal s:findroot(parent, a:mark, depth, a:type) | en
	en
endf

fu! s:glbpath(...)
	let cond = v:version > 702 || ( v:version == 702 && has('patch051') )
	retu call('globpath', cond ? a:000 : a:000[:1])
endf

fu! ctrlp#fnesc(path)
	retu exists('*fnameescape') ? fnameescape(a:path) : escape(a:path, " %#*?|<\"\n")
endf

fu! ctrlp#setdir(path, ...)
	let cmd = a:0 ? a:1 : 'lc!'
	sil! exe cmd ctrlp#fnesc(a:path)
	let [s:crfilerel, s:dyncwd] = [fnamemodify(s:crfile, ':.'), getcwd()]
endf

fu! ctrlp#setlcdir()
	if exists('*haslocaldir')
		cal ctrlp#setdir(getcwd(), haslocaldir() ? 'lc!' : 'cd!')
	en
endf
" Highlighting {{{2
fu! ctrlp#syntax()
	for [ke, va] in items(s:hlgrps) | if !hlexists('CtrlP'.ke)
		exe 'hi link CtrlP'.ke va
	en | endfo
	if !hlexists('CtrlPLinePre')
		\ && synIDattr(synIDtrans(hlID('Normal')), 'bg') !~ '^-1$\|^$'
		sil! exe 'hi CtrlPLinePre '.( has("gui_running") ? 'gui' : 'cterm' ).'fg=bg'
	en
	sy match CtrlPNoEntries '^ == NO ENTRIES ==$'
	if hlexists('CtrlPLinePre')
		sy match CtrlPLinePre '^>'
	en
endf

fu! s:highlight(pat, grp, ipt)
	if s:matcher != {} | retu | en
	cal clearmatches()
	if !empty(a:pat) && a:ipt
		let pat = s:regexp ? substitute(a:pat, '\\\@<!\^', '^> \\zs', 'g') : a:pat
		if s:byfname
			" Match only filename
			let pat = substitute(pat, '\[\^\(.\{-}\)\]\\{-}', '[^\\/\1]\\{-}', 'g')
			let pat = substitute(pat, '\$\@<!$', '\\ze[^\\/]*$', 'g')
		en
		cal matchadd(a:grp, '\c'.pat)
		if hlexists('CtrlPLinePre')
			cal matchadd('CtrlPLinePre', '^>')
		en
	en
endf

fu! s:dohighlight()
	retu s:mathi[0] && exists('*clearmatches')
endf
" Prompt history {{{2
fu! s:gethistloc()
	let utilcadir = ctrlp#utils#cachedir()
	let cache_dir = utilcadir.s:lash(utilcadir).'hist'
	retu [cache_dir, cache_dir.s:lash(cache_dir).'cache.txt']
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
	cal ctrlp#utils#writecache(hst, s:gethistloc()[0], s:gethistloc()[1])
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
	for ic in range(1, len(s:lines))
		let key = s:dictindex(s:marked, fnamemodify(s:lines[ic - 1], ':p'))
		if key > 0
			exe 'sign place' key 'line='.ic.' name=ctrlpmark buffer='.s:bufnr
		en
	endfo
endf

fu! s:dosigns()
	retu exists('s:marked') && s:bufnr > 0 && s:opmul != '0' && has('signs')
endf
" Lists & Dictionaries {{{2
fu! s:dictindex(dict, expr)
	for key in keys(a:dict)
		if a:dict[key] == a:expr | retu key | en
	endfo
	retu -1
endf

fu! s:vacantdict(dict)
	retu filter(range(1, max(keys(a:dict))), '!has_key(a:dict, v:val)')
endf

fu! s:sublist(l, s, e)
	retu v:version > 701 ? a:l[(a:s):(a:e)] : remove(copy(a:l), a:s, a:e)
endf
" Buffers {{{2
fu! s:buftab(bufnr, md)
	for tabnr in range(1, tabpagenr('$'))
		if tabpagenr() == tabnr && a:md == 't' | con | en
		let buflist = tabpagebuflist(tabnr)
		if index(buflist, a:bufnr) >= 0
			for winnr in range(1, tabpagewinnr(tabnr, '$'))
				if buflist[winnr - 1] == a:bufnr | retu [tabnr, winnr] | en
			endfo
		en
	endfo
	retu [0, 0]
endf

fu! ctrlp#normcmd(cmd, ...)
	if s:nosplit() | retu a:cmd | en
	let norwins = filter(range(1, winnr('$')),
		\ 'empty(getbufvar(winbufnr(v:val), "&bt"))')
	for each in norwins
		let bufnr = winbufnr(each)
		if empty(bufname(bufnr)) && empty(getbufvar(bufnr, '&ft'))
			let fstemp = each | brea
		en
	endfo
	let norwin = empty(norwins) ? 0 : norwins[0]
	if norwin
		if index(norwins, winnr()) < 0
			exe ( exists('fstemp') ? fstemp : norwin ).'winc w'
		en
		retu a:cmd
	en
	retu a:0 ? a:1 : 'bo vne'
endf

fu! s:nosplit()
	retu !empty(s:nosplit) && match([bufname('%'), &l:ft, &l:bt], s:nosplit) >= 0
endf

fu! s:setupblank()
	setl noswf nobl nonu nowrap nolist nospell nocuc wfh
	setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
	if v:version > 702
		setl nornu noudf cc=0
	en
endf

fu! s:leavepre()
	if s:clrex && !( has('clientserver') && len(split(serverlist(), "\n")) > 1 )
		cal ctrlp#clra()
	en
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
	let [str, pat] = [substitute(a:str, '\\\\', '\', 'g'), '\([^:]\|\\:\)*$']
	unl! s:optail
	if match(str, '\\\@<!:'.pat) >= 0
		let s:optail = matchstr(str, '\\\@<!:\zs'.pat)
		let str = substitute(str, '\\\@<!:'.pat, '', '')
	en
	retu substitute(str, '\\\ze:', '', 'g')
endf

fu! s:argmaps(md, ...)
	redr
	echoh MoreMsg
	echon '[t]ab/[v]ertical/[h]orizontal'.( a:0 ? '/[r]eplace' : '' ).'? '
	echoh None
	let char = nr2char(getchar())
	if index(['r', 'h', 't', 'v'], char) >= 0
		retu char
	elsei char =~# "\\v\<Esc>|\<C-c>|\<C-[>"
		cal s:BuildPrompt(0)
		retu 'cancel'
	en
	retu a:md
endf
" Misc {{{2
fu! s:dosort()
	retu s:matcher == {} && ( ( s:itemtype != 2 && !exists('g:ctrlp_nolimit') )
		\ || s:prompt != ['', '', ''] ) && s:getextvar('sort')
endf

fu! s:narrowable()
	retu exists('s:act_add') && exists('s:matched') && s:matched != []
		\ && exists('s:mdata') && s:mdata[:2] == [s:dyncwd, s:itemtype, s:regexp]
		\ && s:matcher == {}
endf

fu! s:migemo(str)
	let str = a:str
	let dict = s:glbpath(&rtp, printf("dict/%s/migemo-dict", &enc), 1)
	if !len(dict)
		let dict = s:glbpath(&rtp, "dict/migemo-dict", 1)
	en
	if len(dict)
		let [tokens, str, cmd] = [split(str, '\s'), '', 'cmigemo -v -w %s -d %s']
		for token in tokens
			let rtn = system(printf(cmd, shellescape(token), shellescape(dict)))
			let str .= !v:shell_error && strlen(rtn) > 0 ? '.*'.rtn : token
		endfo
	en
	retu str
endf

fu! s:strwidth(str)
	retu exists('*strdisplaywidth') ? strdisplaywidth(a:str) : strlen(a:str)
endf

fu! ctrlp#j2l(nr)
	exe a:nr
	sil! norm! zvzz
endf

fu! s:maxf(len)
	retu s:maxfiles && a:len > s:maxfiles ? 1 : 0
endf

fu! s:regexfilter(str)
	let str = a:str
	for key in keys(s:fpats) | if match(str, key) >= 0
		let str = substitute(str, s:fpats[key], '', 'g')
	en | endfo
	retu str
endf

fu! s:walker(m, p, d)
	retu a:d > 0 ? a:p < a:m ? a:p + a:d : 0 : a:p > 0 ? a:p + a:d : a:m
endf

fu! s:matargs(mfunc, str)
	let match_type = {
		\ 'match': 'full-line',
		\ 's:matchfname': 'filename-only',
		\ 's:matchtabs': 'first-non-tab',
		\ 's:matchtabe': 'until-last-tab',
		\ }
	retu [s:matcher['match'], a:str, match_type[a:mfunc]]
endf
" Entering & Exiting {{{2
fu! s:getenv()
	let [s:cwd, s:winres] = [getcwd(), [winrestcmd(), &lines, winnr('$')]]
	let [s:crfile, s:crfpath] = [expand('%:p', 1), expand('%:p:h', 1)]
	let [s:crword, s:crline] = [expand('<cword>'), getline('.')]
	let [s:winh, s:crcursor] = [min([s:mxheight, &lines]), getpos('.')]
	let [s:crbufnr, s:crvisual] = [bufnr('%'), s:lastvisual()]
	let s:currwin = s:mwbottom ? winnr() : winnr() + has('autocmd')
	let s:wpmode = exists('b:ctrlp_working_path_mode')
		\ ? b:ctrlp_working_path_mode : s:pathmode
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

fu! s:log(m)
	if exists('g:ctrlp_log') && g:ctrlp_log | if a:m
		let cadir = ctrlp#utils#cachedir()
		sil! exe 'redi! >' cadir.s:lash(cadir).'ctrlp.log'
	el
		sil! redi END
	en | en
endf

fu! s:openfile(cmd, fid, tail, ...)
	let cmd = a:cmd =~ '^[eb]$' && &modified ? 'hid '.a:cmd : a:cmd
	let cmd = cmd =~ '^tab' ? tabpagenr('$').cmd : cmd
	let j2l = a:0 && a:1 ? a:2 : 0
	exe cmd.( a:0 && a:1 ? '' : a:tail ) ctrlp#fnesc(a:fid)
	if j2l
		exe j2l
	en
	if !empty(a:tail) || j2l
		sil! norm! zvzz
	en
	if cmd != 'bad'
		cal ctrlp#setlcdir()
	en
endf
" Matchfuncs {{{2
fu! s:matchfname(item, pat)
	retu match(split(a:item, s:lash)[-1], a:pat)
endf

fu! s:matchtabs(item, pat)
	retu match(split(a:item, '\t\+')[0], a:pat)
endf

fu! s:matchtabe(item, pat)
	retu match(split(a:item, '\t\+[^\t]\+$')[0], a:pat)
endf
" Cache {{{2
fu! s:writecache(read_cache, cache_file)
	if !a:read_cache && ( ( g:ctrlp_newcache || !filereadable(a:cache_file) )
		\ && s:caching || len(g:ctrlp_allfiles) > s:nocache_lim )
		if len(g:ctrlp_allfiles) > s:nocache_lim | let s:caching = 1 | en
		cal ctrlp#utils#writecache(g:ctrlp_allfiles)
	en
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
" Extensions {{{2
fu! s:type(...)
	retu s:itemtype > 2
		\ ? g:ctrlp_ext_vars[s:itemtype - 3][a:0 ? 'type' : 'sname'] : s:itemtype
endf

fu! s:execextvar(key)
	if exists('g:ctrlp_ext_vars')
		cal map(filter(copy(g:ctrlp_ext_vars),
			\ 'has_key(v:val, a:key)'), 'eval(v:val[a:key])')
	en
endf

fu! s:getextvar(key)
	if s:itemtype > 2
		let vars = g:ctrlp_ext_vars[s:itemtype - 3]
		retu has_key(vars, a:key) ? vars[a:key] : -1
	en
	retu -1
endf

fu! ctrlp#exit()
	cal s:PrtExit()
endf

fu! ctrlp#prtclear()
	cal s:PrtClear()
endf

fu! ctrlp#switchtype(id)
	cal s:ToggleType(a:id - s:itemtype)
endf
"}}}1
" * Initialization {{{1
fu! ctrlp#setlines(type)
	let s:itemtype = a:type
	let types = ['ctrlp#files()', 'ctrlp#buffers()', 'ctrlp#mrufiles#list()']
	if exists('g:ctrlp_ext_vars')
		cal map(copy(g:ctrlp_ext_vars), 'add(types, v:val["init"])')
	en
	let g:ctrlp_lines = eval(types[a:type])
endf

fu! ctrlp#init(type, ...)
	if exists('s:init') | retu | en
	let [s:matches, s:init] = [1, 1]
	cal s:Open()
	cal s:SetWD(a:0 ? a:1 : '')
	cal s:SetDefTxt()
	cal s:MapKeys()
	if has('syntax') && exists('g:syntax_on')
		cal ctrlp#syntax()
	en
	cal ctrlp#setlines(a:type)
	cal s:BuildPrompt(1)
endf
" - Autocmds {{{1
fu! s:autocmds()
	if !has('autocmd') | retu | en
	aug CtrlPAug
		au!
		au BufEnter ControlP cal s:checkbuf()
		au BufLeave ControlP cal s:Close()
		au VimLeavePre * cal s:leavepre()
	aug END
	if exists('#CtrlPLazy')
		au! CtrlPLazy
	en
	if s:lazy
		aug CtrlPLazy
			au!
			au CursorHold ControlP cal s:ForceUpdate()
		aug END
	en
endf

cal s:autocmds()
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
