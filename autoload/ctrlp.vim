" =============================================================================
" File:          autoload/ctrlp.vim
" Description:   Full path fuzzy file, buffer and MRU file finder for Vim.
" Author:        Kien Nguyen <github.com/kien>
" License:       MIT
" Version:       1.5.5
" =============================================================================

if v:version < '700' "{{{
	fini
endif "}}}

" Option variables {{{
func! s:opts()
	let opts = {
				\ 'g:ctrlp_by_filename'           : ['s:byfname', 0],
				\ 'g:ctrlp_clear_cache_on_exit'   : ['s:cconex', 1],
				\ 'g:ctrlp_dotfiles'              : ['s:dotfiles', 1],
				\ 'g:ctrlp_highlight_match'       : ['s:mathi', [1, 'Identifier']],
				\ 'g:ctrlp_jump_to_buffer'        : ['s:jmptobuf', 1],
				\ 'g:ctrlp_match_window_bottom'   : ['s:mwbottom', 1],
				\ 'g:ctrlp_match_window_reversed' : ['s:mwreverse', 1],
				\ 'g:ctrlp_max_depth'             : ['s:maxdepth', 40],
				\ 'g:ctrlp_max_files'             : ['s:maxfiles', 20000],
				\ 'g:ctrlp_max_height'            : ['s:mxheight', 10],
				\ 'g:ctrlp_open_multi'            : ['s:opmul', 1],
				\ 'g:ctrlp_open_new_file'         : ['s:newfop', 3],
				\ 'g:ctrlp_prompt_mappings'       : ['s:urprtmaps', 0],
				\ 'g:ctrlp_regexp_search'         : ['s:regexp', 0],
				\ 'g:ctrlp_root_markers'          : ['s:rmarkers', []],
				\ 'g:ctrlp_split_window'          : ['s:splitwin', 0],
				\ 'g:ctrlp_use_caching'           : ['s:caching', 1],
				\ 'g:ctrlp_working_path_mode'     : ['s:pathmode', 1],
				\ }
	for key in keys(opts)
		let def = call('exists', [key]) ? string(eval(key)) : string(opts[key][1])
		exe 'unl!' key
		exe 'let' opts[key][0] '=' def
	endfor
	if !exists('g:ctrlp_cache_dir')
		let s:cache_dir = $HOME
	else
		let s:cache_dir = g:ctrlp_cache_dir
	endif
	if !exists('g:ctrlp_newcache')
		let g:ctrlp_newcache = 0
	endif
	if s:maxdepth > 200
		let s:maxdepth = 200
	endif
	if !exists('g:ctrlp_user_command')
		let g:ctrlp_user_command = ''
	endif
	if !exists('g:ctrlp_max_history')
		let s:maxhst = exists('+hi') ? &hi : 20
	else
		let s:maxhst = g:ctrlp_max_history
		unl g:ctrlp_max_history
	endif
endfunc
cal s:opts()

let s:lash = ctrlp#utils#lash()

" Limiters
let [s:compare_lim, s:nocache_lim, s:mltipats_lim] = [3000, 4000, 2000]
"}}}

" * Clear caches {{{
func! ctrlp#clearcache()
	let g:ctrlp_newcache = 1
endfunc

func! ctrlp#clearallcaches()
	let cache_dir = ctrlp#utils#cachedir()
	if isdirectory(cache_dir) && match(cache_dir, '.ctrlp_cache') >= 0
		let cache_files = split(globpath(cache_dir, '*.txt'), '\n')
		cal filter(cache_files, '!isdirectory(v:val)')
		for each in cache_files | sil! cal delete(each) | endfor
	endif
	cal ctrlp#clearcache()
endfunc

func! ctrlp#reset()
	cal s:opts()
	cal ctrlp#utils#opts()
	if g:ctrlp_mru_files | cal ctrlp#mrufiles#opts() | endif
	" Clear user input
	let s:prompt = ['','','']
	unl! s:cline
endfunc
"}}}

" * ListAllFiles {{{
func! s:GlobPath(dirs, allfiles, depth)
	" Note: wildignore is ignored when using **
	let glob     = s:dotfiles ? '.*\|*' : '*'
	let entries  = split(globpath(a:dirs, glob), '\n')
	let entries  = filter(entries, 'getftype(v:val) != "link"')
	let entries2 = deepcopy(entries)
	let alldirs  = s:dotfiles ? filter(entries, 's:dirfilter(v:val)') : filter(entries, 'isdirectory(v:val)')
	let g:ctrlp_allfiles = filter(entries2, '!isdirectory(v:val)')
	cal extend(g:ctrlp_allfiles, a:allfiles, 0)
	let depth = a:depth + 1
	if empty(alldirs) || s:maxfiles(len(g:ctrlp_allfiles)) || depth > s:maxdepth
		retu
	else
		let dirs = join(alldirs, ',')
		sil! cal s:progress(len(g:ctrlp_allfiles))
		cal s:GlobPath(dirs, g:ctrlp_allfiles, depth)
	endif
endfunc

func! s:UserCommand(path, lscmd)
	let path = a:path
	if exists('+ssl') && &ssl
		let ssl = &ssl
		let &ssl = 0
		let path = tr(path, '/', '\')
	endif
	let path = exists('*shellescape') ? shellescape(path) : path
	let g:ctrlp_allfiles = split(system(printf(a:lscmd, path)), '\n')
	if exists('+ssl') && exists('ssl')
		let &ssl = ssl
		cal map(g:ctrlp_allfiles, 'tr(v:val, "\\", "/")')
	endif
	if exists('s:vcscmd') && s:vcscmd
		cal map(g:ctrlp_allfiles, 'tr(v:val, "/", "\\")')
	endif
endfunc

func! s:ListAllFiles(path)
	let cache_file = ctrlp#utils#cachefile()
	if g:ctrlp_newcache || !filereadable(cache_file) || !s:caching
		let lscmd = s:lscommand()
		" Get the list of files
		if empty(lscmd)
			cal s:GlobPath(a:path, [], 0)
		else
			sil! cal s:progress('Waiting...')
			try
				cal s:UserCommand(a:path, lscmd)
			catch
				retu []
			endtry
		endif
		" Remove base directory
		let path = &ssl || !exists('+ssl') ? getcwd().'/' : substitute(getcwd(), '\\', '\\\\', 'g').'\\'
		cal map(g:ctrlp_allfiles, 'substitute(v:val, path, "", "g")')
		let read_cache = 0
	else
		let g:ctrlp_allfiles = ctrlp#utils#readfile(cache_file)
		let read_cache = 1
	endif
	if len(g:ctrlp_allfiles) <= s:compare_lim | cal sort(g:ctrlp_allfiles, 's:complen') | endif
	" Write cache
	if !read_cache && ( ( g:ctrlp_newcache || !filereadable(cache_file) )
				\ && s:caching || len(g:ctrlp_allfiles) > s:nocache_lim )
		if len(g:ctrlp_allfiles) > s:nocache_lim | let s:caching = 1 | endif
		cal ctrlp#utils#writecache(g:ctrlp_allfiles)
	endif
	retu g:ctrlp_allfiles
endfunc
"}}}

func! s:ListAllBuffers() "{{{
	let allbufs = []
	for each in range(1, bufnr('$'))
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
	let str = a:str
	" Restore the number of backslashes
	let str = substitute(str, '\\\\', '\', 'g')
	" Clear the tail var
	unl! s:optail
	" If pattern contains :str$
	" e.g. abc:25, abc:/myclass or abc:++[opt] +[cmd]
	if match(str, ':\([^:]\|\\:\)*$') >= 0
		" Set the tail var
		let s:optail = matchstr(str, ':\zs\([^:]\|\\:\)*$')
		" Remove the tail
		let str = substitute(str, ':\([^:]\|\\:\)*$', '', 'g')
	endif
	let s:savestr = str
	if s:regexp || match(str, '[*|]') >= 0
				\ || match(str, '\\\(zs\|ze\|<\|>\)') >= 0
		let array = [str]
	else
		let array = split(str, '\zs')
		if exists('+ssl') && !&ssl
			cal map(array, 'substitute(v:val, "\\", "\\\\\\", "g")')
		endif
		" Literal ^ and $
		for each in ['^', '$']
			cal map(array, 'substitute(v:val, "\\\'.each.'", "\\\\\\'.each.'", "g")')
		endfor
	endif
	" Build the new pattern
	let nitem = !empty(array) ? array[0] : ''
	let newpats = [nitem]
	if len(array) > 1
		for i in range(1, len(array) - 1)
			" Separator
			let sp = exists('a:1') ? a:1 : '[^'.array[i-1].']\{-}'
			let nitem .= sp.array[i]
			cal add(newpats, nitem)
		endfor
	endif
	retu newpats
endfunc "}}}

" * GetMatchedItems {{{
func! s:MatchIt(items, pat, limit)
	let [items, pat, limit] = [a:items, a:pat, a:limit]
	let newitems = []
	for item in items
		if s:byfname
			if s:matchsubstr(item, pat) >= 0 | cal add(newitems, item) | endif
		else
			if match(item, pat) >= 0 | cal add(newitems, item) | endif
		endif
		" Stop if reached the limit
		if limit > 0 && len(newitems) == limit | break | endif
	endfor
	retu newitems
endfunc

func! s:GetMatchedItems(items, pats, limit)
	let [items, pats, limit] = [a:items, a:pats, a:limit]
	" If items is longer than s:mltipats_lim, use only the last pattern
	if len(items) >= s:mltipats_lim
		let pats = [pats[-1]]
	endif
	cal map(pats, 'substitute(v:val, "\\\~", "\\\\\\~", "g")')
	" Loop through the patterns
	for each in pats
		" If newitems is small, set it as items to search in
		if exists('newitems') && len(newitems) < limit
			let items = deepcopy(newitems)
		endif
		if !s:regexp | let each = escape(each, '.') | endif
		if empty(items) " End here
			retu exists('newitems') ? newitems : []
		else " Start here, goes back up if has 2 or more in pats
			" Loop through the items
			let newitems = s:MatchIt(items, each, limit)
		endif
	endfor
	let s:matches = len(newitems)
	retu newitems
endfunc
"}}}

" * Open & Close {{{
func! s:Open(name)
	let pos = s:mwbottom ? 'bo' : 'to'
	sil! exe pos '1new' a:name
	let s:currwin = s:mwbottom ? winnr('#') : winnr('#') + 1
	abc <buffer>
	let s:winnr = bufwinnr('%')
	let s:bufnr = bufnr('%')
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
	let s:CtrlP_mfd    = &mfd
	let s:CtrlP_gcr    = &gcr
	let s:prompt = ['', '', '']
	if !exists('s:hstry')
		let hst = filereadable(s:gethistloc()[1]) ? s:gethistdata() : ['']
		let s:hstry = empty(hst) || !s:maxhst ? [''] : hst
	endif
	" Set global options
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
	se mfd=200
	se gcr=a:block-PmenuSel-blinkon0
	if s:opmul && has('signs')
		sign define ctrlpmark text=+> texthl=Search
	endif
endfunc

func! s:Close()
	try | bun! | catch | clo! | endtry
	" Restore global options
	let &magic  = s:CtrlP_magic
	let &to     = s:CtrlP_to
	let &tm     = s:CtrlP_tm
	let &sb     = s:CtrlP_sb
	let &hls    = s:CtrlP_hls
	let &im     = s:CtrlP_im
	let &report = s:CtrlP_report
	let &sc     = s:CtrlP_sc
	let &ss     = s:CtrlP_ss
	let &siso   = s:CtrlP_siso
	let &mfd    = s:CtrlP_mfd
	let &gcr    = s:CtrlP_gcr
	" Cleaning up
	cal s:unmarksigns()
	let g:ctrlp_lines = []
	let g:ctrlp_allfiles = []
	if exists('s:cwd')
		exe 'chd!' s:cwd
		unl s:cwd
	endif
	unl! s:focus s:hisidx s:hstgot s:marked s:winnr s:init s:savestr s:cline
	" Record the input string
	let prt = s:prompt
	cal s:recordhist(prt[0] . prt[1] . prt[2])
	ec
endfunc
"}}}

func! s:Renderer(lines, pat) "{{{
	let nls = deepcopy(a:lines)
	" Determine/set max height
	let height = s:mxheight
	let max = len(nls) < height ? len(nls) : height
	exe 'res' max
	" Output to buffer
	if !empty(nls)
		setl cul
		" Sort if not type 2 (MRU)
		if index([2], s:itemtype) < 0
			let s:compat = a:pat
			cal sort(nls, 's:mixedsort')
			unl s:compat
		endif
		if s:mwreverse
			cal reverse(nls)
		endif
		let s:matched = deepcopy(nls)
		cal map(nls, 'substitute(v:val, "^", "> ", "")')
		cal setline('1', nls)
		let cmd = s:mwreverse ? 'G' : 'gg'
		exe 'keepj norm!' cmd
		keepj norm! 1|
		cal s:unmarksigns()
		cal s:remarksigns(s:matched)
	else
		setl nocul
		cal setline('1', ' == NO MATCHES ==')
		cal s:unmarksigns()
	endif
	" Remember selected line
	if exists('s:cline')
		cal cursor(s:cline, 1)
	endif
endfunc "}}}

func! s:UpdateMatches(pat,...) "{{{
	let pat = a:pat
	" Get the previous string if existed
	let oldstr = exists('s:savestr') ? s:savestr : ''
	let pats   = s:SplitPattern(pat)
	" Get the new string sans tail
	let notail = substitute(pat, ':\([^:]\|\\:\)*$', '', 'g')
	" Stop if the string's unchanged
	if notail == oldstr && !empty(notail) && !exists('a:1') | retu | endif
	let lines = s:GetMatchedItems(g:ctrlp_lines, pats, s:mxheight)
	let pat   = pats[-1]
	" Delete the buffer's content
	sil! %d _
	cal s:Renderer(lines, pat)
	" Highlighting
	if type(s:mathi) == 3 && len(s:mathi) == 2 && s:mathi[0] && exists('*clearmatches')
		let grp = empty(s:mathi[1]) ? 'Identifier' : s:mathi[1]
		cal s:highlight(pat, grp)
	endif
endfunc "}}}

func! s:BuildPrompt(upd,...) "{{{
	let base1 = s:regexp ? 'r' : '>'
	let base2 = s:byfname ? 'd' : '>'
	let base  = base1.base2.'> '
	let cur   = '_'
	let estr  = '"\'
	let prt   = deepcopy(s:prompt)
	cal map(prt, 'escape(v:val, estr)')
	let str   = prt[0] . prt[1] . prt[2]
	if a:upd && ( s:matches || s:regexp || match(str, '[*|]') >= 0 )
		if exists('a:2')
			sil! cal s:UpdateMatches(str, a:2)
		else
			sil! cal s:UpdateMatches(str)
		endif
	endif
	sil! cal s:statusline()
	" Toggling
	if !exists('a:1') || ( exists('a:1') && a:1 )
		let [hiactive, hicursor] = ['Normal', 'Constant']
	elseif exists('a:1') || ( exists('a:1') && !a:1 )
		let [hiactive, hicursor] = ['Comment', 'Comment']
		let base = tr(base, '>', '-')
	endif
	let hibase = 'Comment'
	" Build it
	redr
	exe 'echoh' hibase '| echon "'.base.'"
				\ | echoh' hiactive '| echon "'.prt[0].'"
				\ | echoh' hicursor '| echon "'.prt[1].'"
				\ | echoh' hiactive '| echon "'.prt[2].'"
				\ | echoh None'
	" Append the cursor _ at the end
	if empty(prt[1]) && ( !exists('a:1') || ( exists('a:1') && a:1 ) )
		exe 'echoh' hibase '| echon "'.cur.'" | echoh None'
	endif
endfunc "}}}

func! s:CreateNewFile() "{{{
	let prt = s:prompt
	let str = prt[0] . prt[1] . prt[2]
	if empty(str) | retu | endif
	let arr = split(str, '[\/]')
	let fname = remove(arr, -1)
	if s:newfop <= 1 " In new tab or current window
		let cmd = 'e'
	elseif s:newfop == 2 " In new hor split
		let cmd = 'new'
	elseif s:newfop == 3 " In new ver split
		let cmd = 'vne'
	endif
	if len(arr)
		if isdirectory(s:createparentdirs(arr))
			let filpath = escape(getcwd().s:lash.str, '%#')
			let opcmd = 'bo '.cmd.' '.filpath
		endif
	else
		let filpath = escape(getcwd().s:lash.fname, '%#')
		let opcmd = 'bo '.cmd.' '.filpath
	endif
	if exists('opcmd') && !empty(opcmd)
		cal s:insertcache(str)
		cal s:PrtExit()
		if s:newfop == 1
			tabnew
		endif
		cal s:openfile(opcmd)
	endif
endfunc "}}}

" * OpenMulti {{{
func! s:MarkToOpen()
	if s:bufnr <= 0 || !s:opmul | retu | endif
	let matchstr = matchstr(getline('.'), '^> \zs.\+\ze\t*$')
	if empty(matchstr) | retu | endif
	let filpath = s:itemtype ? matchstr : getcwd().s:lash.matchstr
	if exists('s:marked') && s:dictindex(s:marked, filpath) > 0
		" Unmark, remove the file from s:marked
		let key = s:dictindex(s:marked, filpath)
		cal remove(s:marked, key)
		if has('signs')
			exe 'sign unplace' key 'buffer='.s:bufnr
		endif
		if empty(s:marked) | unl! s:marked | endif
	else
		" Add to s:marked and place a new sign
		if exists('s:marked')
			let vac = s:vacantdict(s:marked)
			let key = empty(vac) ? len(s:marked) + 1 : vac[0]
			let s:marked = extend(s:marked, { key : filpath })
		else
			let key = 1
			let s:marked = { 1: filpath }
		endif
		if has('signs')
			exe 'sign place' key 'line='.line('.').' name=ctrlpmark buffer='.s:bufnr
		endif
	endif
	cal s:statusline()
endfunc

func! s:OpenMulti()
	if !exists('s:marked') || !s:opmul
		cal s:AcceptSelection('e')
		retu
	endif
	let marked = deepcopy(s:marked)
	cal s:PrtExit()
	" Try not to open in new tab
	let ntab = 0
	let norwins = s:normbuf()
	if empty(norwins)
		let ntab = 1
	else
		for each in norwins
			let bufnr = winbufnr(each)
			if !empty(bufname(bufnr)) && !empty(getbufvar(bufnr, '&ft'))
						\ && bufname(bufnr) != 'ControlP'
				let ntab = 1
			endif
		endfor
		if !ntab
			let wnr = min(norwins)
		endif
	endif
	if ntab | tabnew | endif
	let ic = 1
	let wnr = exists('wnr') ? wnr : 1
	exe wnr.'winc w'
	for key in keys(marked)
		let filpath = escape(marked[key], '%#')
		let cmd = ic == 1 ? 'e ' : 'vne '
		sil! exe cmd.filpath
		if s:opmul > 1 && s:opmul < ic
			clo!
		else
			let ic += 1
		endif
	endfor
	ec
endfunc
"}}}

" * Prt Actions {{{
func! s:PrtClear()
	let s:matches = 1
	unl! s:hstgot
	let s:prompt = ['','','']
	cal s:BuildPrompt(1)
endfunc

func! s:PrtAdd(char)
	unl! s:hstgot
	let prt = s:prompt
	let prt[0] = prt[0] . a:char
	cal s:BuildPrompt(1)
endfunc

func! s:PrtBS()
	let s:matches = 1
	unl! s:hstgot
	let prt = s:prompt
	let prt[0] = strpart(prt[0], -1, strlen(prt[0]))
	cal s:BuildPrompt(1)
endfunc

func! s:PrtDelete()
	let s:matches = 1
	unl! s:hstgot
	let prt = s:prompt
	let prt[1] = strpart(prt[2], 0, 1)
	let prt[2] = strpart(prt[2], 1)
	cal s:BuildPrompt(1)
endfunc

func! s:PrtCurLeft()
	if !empty(s:prompt[0])
		let prt = s:prompt
		let prt[2] = prt[1] . prt[2]
		let prt[1] = strpart(prt[0], strlen(prt[0]) - 1)
		let prt[0] = strpart(prt[0], -1, strlen(prt[0]))
	endif
	cal s:BuildPrompt(0)
endfunc

func! s:PrtCurRight()
	let prt = s:prompt
	let prt[0] = prt[0] . prt[1]
	let prt[1] = strpart(prt[2], 0, 1)
	let prt[2] = strpart(prt[2], 1)
	cal s:BuildPrompt(0)
endfunc

func! s:PrtCurStart()
	let prt = s:prompt
	let str = prt[0] . prt[1] . prt[2]
	let [prt[0], prt[1], prt[2]] = ['', strpart(str, 0, 1), strpart(str, 1)]
	cal s:BuildPrompt(0)
endfunc

func! s:PrtCurEnd()
	let prt = s:prompt
	let str = prt[0] . prt[1] . prt[2]
	let [prt[0], prt[1], prt[2]] = [str, '', '']
	cal s:BuildPrompt(0)
endfunc

func! s:PrtDeleteWord()
	let s:matches = 1
	unl! s:hstgot
	let str = s:prompt[0]
	if match(str, '\W\w\+$') >= 0
		let str = matchstr(str, '^.\+\W\ze\w\+$')
	elseif match(str, '\w\W\+$') >= 0
		let str = matchstr(str, '^.\+\w\ze\W\+$')
	elseif match(str, '[ ]\+$') >= 0
		let str = matchstr(str, '^.*[^ ]\+\ze[ ]\+$')
	elseif match(str, ' ') <= 0
		let str = ''
	endif
	let s:prompt[0] = str
	cal s:BuildPrompt(1)
endfunc

func! s:PrtSelectMove(dir)
	exe 'norm!' a:dir
	let s:cline = line('.')
endfunc

func! s:PrtSelectJump(char,...)
	let lines = deepcopy(s:matched)
	if exists('a:1')
		let lines = map(lines, 'split(v:val, ''[\/]\ze[^\/]\+$'')[-1]')
	endif
	" Cycle through matches, use s:jmpchr to store last jump
	let chr = escape(a:char, '.~')
	if match(lines, '\c^'.chr) >= 0
		" If not exists or does but not for the same char
		let pos = match(lines, '\c^'.chr)
		if !exists('s:jmpchr') || ( exists('s:jmpchr') && s:jmpchr[0] != chr )
			let jmpln = pos
			let s:jmpchr = [chr, pos]
		elseif exists('s:jmpchr') && s:jmpchr[0] == chr
			" Start of lines
			if s:jmpchr[1] == -1
				let s:jmpchr[1] = pos
			endif
			let npos = match(lines, '\c^'.chr, s:jmpchr[1] + 1)
			let jmpln = npos == -1 ? pos : npos
			let s:jmpchr = [chr, npos]
		endif
		keepj exe jmpln + 1
		let s:cline = line('.')
	endif
endfunc

func! s:PrtClearCache()
	cal ctrlp#clearcache()
	cal s:SetLines(s:itemtype)
	cal s:BuildPrompt(1)
endfunc

func! s:PrtExit()
	" Manually remove the prompt and match window
	if !has('autocmd') | cal s:Close() | endif
	exe s:currwin.'winc w'
endfunc

func! s:PrtHistory(...)
	if !s:maxhst | retu | endif
	let s:matches = 1
	let prt = s:prompt
	let str = prt[0] . prt[1] . prt[2]
	let hst = s:hstry
	" Save to history if not saved before
	let hst[0] = exists('s:hstgot') ? hst[0] : str
	let hslen = len(hst)
	let idx = exists('s:hisidx') ? s:hisidx + a:1 : a:1
	" Limit idx within 0 and hslen
	let idx = idx < 0 ? 0 : idx >= hslen ? hslen > 1 ? hslen - 1 : 0 : idx
	let s:prompt = [hst[idx], '', '']
	let s:hisidx = idx
	let s:hstgot = 1
	cal s:BuildPrompt(1)
endfunc
"}}}

" * MapKeys {{{
func! s:MapKeys(...)
	" Normal keystrokes
	let func = !exists('a:1') || ( exists('a:1') && a:1 ) ? 'PrtAdd' : 'PrtSelectJump'
	let sjbyfname = s:byfname && func == 'PrtSelectJump' ? ', 1' : ''
	for each in range(32,126)
		exe "nn \<buffer> \<silent> \<char-".each."> :<c-u>cal \<SID>".func."(\"".escape(nr2char(each), '"|\')."\"".sjbyfname.")\<cr>"
	endfor
	if exists('a:2') | retu | endif
	" Special keystrokes
	if exists('a:1') && !a:1
		cal s:MapSpecs('unmap')
	else
		cal s:MapSpecs()
	endif
endfunc

func! s:MapSpecs(...)
	let prtmaps = {
				\ 'PrtBS()':              ['<bs>'],
				\ 'PrtDelete()':          ['<del>'],
				\ 'PrtDeleteWord()':      ['<c-w>'],
				\ 'PrtClear()':           ['<c-u>'],
				\ 'PrtSelectMove("j")':   ['<c-j>', '<down>'],
				\ 'PrtSelectMove("k")':   ['<c-k>', '<up>'],
				\ 'PrtHistory(-1)':       ['<c-n>'],
				\ 'PrtHistory(1)':        ['<c-p>'],
				\ 'AcceptSelection("e")': ['<cr>'],
				\ 'AcceptSelection("h")': ['<c-x>', '<c-cr>', '<c-s>'],
				\ 'AcceptSelection("t")': ['<c-t>'],
				\ 'AcceptSelection("v")': ['<c-v>', '<c-q>'],
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
				\ }
	if type(s:urprtmaps) == 4
		cal extend(prtmaps, s:urprtmaps)
	endif
	let lcmap = 'nn <buffer> <silent>'
	" Correct arrow keys in terminal
	if ( has('termresponse') && !empty(v:termresponse) )
				\ || &term =~? 'xterm\|\<k\?vt\|gnome\|screen'
		for each in ['\A <up>','\B <down>','\C <right>','\D <left>']
			exe lcmap.' <esc>['.each
		endfor
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
			exe lcmap kp '<Nop>'
		endfor | endfor
	else
		for each in keys(prtmaps) | for kp in prtmaps[each]
			exe lcmap kp ':<c-u>cal <SID>'.each.'<cr>'
		endfor | endfor
	endif
endfunc
"}}}

" * Toggling functions {{{
func! s:Focus()
	retu !exists('s:focus') ? 1 : s:focus
endfunc

func! s:ToggleFocus()
	let s:focus = !exists('s:focus') || s:focus ? 0 : 1
	cal s:MapKeys(s:focus)
	cal s:BuildPrompt(0, s:focus)
endfunc

func! s:ToggleRegex()
	let s:regexp = s:regexp ? 0 : 1
	cal s:PrtSwitcher()
endfunc

func! s:ToggleByFname()
	let s:byfname = s:byfname ? 0 : 1
	cal s:MapKeys(s:Focus(), 1)
	cal s:PrtSwitcher()
endfunc

func! s:ToggleType(dir)
	let len = 1 + g:ctrlp_mru_files
	let s:itemtype = s:walker(len, s:itemtype, a:dir)
	cal s:Type(s:itemtype)
endfunc

func! s:Type(type)
	let s:itemtype = a:type
	cal s:SetLines(s:itemtype)
	cal s:PrtSwitcher()
	cal s:syntax()
endfunc

func! s:PrtSwitcher()
	let s:matches = 1
	cal s:BuildPrompt(1, s:Focus(), 1)
endfunc
"}}}

" * SetWorkingPath {{{
func! s:FindRoot(curr, mark, depth, type)
	let depth = a:depth + 1
	let notfound = empty(globpath(a:curr, a:mark, 1))
	if !notfound || depth > s:maxdepth
		if notfound | retu 0 | endif
		if a:type
			let s:vcsroot = depth <= s:maxdepth ? a:curr : ''
		else
			sil! exe 'chd!' a:curr
			retu 1
		endif
	else
		let parent = substitute(a:curr, '[\/]\zs[^\/]\+[\/]\?$', '', '')
		if parent != a:curr | cal s:FindRoot(parent, a:mark, depth, a:type) | endif
	endif
endfunc

func! ctrlp#SetWorkingPath(...)
	let l:pathmode = 2
	let s:cwd = getcwd()
	if exists('a:1') && len(a:1) == 1 && !type(a:1)
		let l:pathmode = a:1
	elseif exists('a:1') && len(a:1) > 1 && type(a:1)
		sil! exe 'chd!' a:1
		retu
	endif
	if match(expand('%:p'), '^\<.\+\>://.*') >= 0
				\ || !s:pathmode || !l:pathmode
		retu
	endif
	if exists('+acd') | let &acd = 0 | endif
	let path = expand('%:p:h')
	let path = exists('*fnameescape') ? fnameescape(path) : escape(path, '%#')
	sil! exe 'chd!' path
	if s:pathmode == 1 || l:pathmode == 1 | retu | endif
	let markers = [
				\ 'root.dir',
				\ '.git/',
				\ '.hg/',
				\ '.vimprojects',
				\ '_darcs/',
				\ '.bzr/',
				\ ]
	if exists('s:rmarkers') && type(s:rmarkers) == 3 && !empty(s:rmarkers)
		cal extend(markers, s:rmarkers, 0)
	endif
	for marker in markers
		let found = s:FindRoot(getcwd(), marker, 0, 0)
		if getcwd() != expand('%:p:h') || found | break | endif
	endfor
endfunc
"}}}

func! s:AcceptSelection(mode,...) "{{{
	let [md, prt] = [a:mode, s:prompt]
	let str = prt[0] . prt[1] . prt[2]
	if md == 'e' && !s:itemtype
		if str == '..'
			" Walk backward the dir tree
			cal s:parentdir(getcwd())
			cal s:SetLines(s:itemtype)
			cal s:PrtClear()
			retu
		elseif str == '?'
			" Use ? for help
			cal s:PrtExit()
			let hlpwin = &columns > 159 ? '| vert res 80' : ''
			exe 'bo vert h ctrlp-mappings' hlpwin '| norm! 0'
			retu
		endif
	endif
	" Get the full path
	let matchstr = matchstr(getline('.'), '^> \zs.\+\ze\t*$')
	if empty(matchstr) | retu | endif
	let filpath = s:itemtype ? matchstr : getcwd().s:lash.matchstr
	" If only need the full path
	if exists('a:1') && a:1 | retu filpath | endif
	cal s:PrtExit()
	let bufnum  = bufnr(filpath)
	let norwins = s:normbuf()
	let norwin  = empty(norwins) ? 0 : norwins[0]
	if s:jmptobuf && bufnum > 0 && md == 'e'
		let [jmpb, bufwinnr] = [1, bufwinnr(bufnum)]
		let buftab = s:jmptobuf > 1 ? s:buftab(bufnum) : [0, 0]
	endif
	" Get the tail
	let tail = ''
	if exists('s:optail') && !empty('s:optail')
		let tailpref = match(s:optail, '^\s*+') < 0 ? ' +' : ' '
		let tail = tailpref.s:optail
	endif
	" Switch to existing buffer or open new one
	let filpath = escape(filpath, '%#')
	" If the file's already opened
	if exists('jmpb') && buftab[0] " In a tab
		exe 'norm!' buftab[1].'gt'
		exe buftab[0].'winc w'
	elseif exists('jmpb') && bufwinnr > 0 " In a window
		exe bufwinnr.'winc w'
	else
		" Determine the command to use
		if md == 't' || s:splitwin == 1 " In new tab
			tabnew
			let cmd = 'e'
		elseif md == 'h' || s:splitwin == 2 " In new hor split
			let cmd = 'new'
		elseif md == 'v' || s:splitwin == 3 " In new ver split
			let cmd = 'vne'
		elseif md == 'e'
			let cmd = 'e'
			" If there's at least 1 normal buffer
			if norwin
				" But not the current one
				if !&l:bl || !empty(&l:bt) || !&l:ma
					" Go to the first normal one
					exe norwin.'winc w'
				endif
			else
				" No normal buffers
				let cmd = 'vne'
			endif
		endif
		" Open new window/buffer
		let opcmd = 'bo '.cmd.tail.' '.filpath
		cal s:openfile(opcmd)
	endif
	if !empty('tail')
		sil! norm! zOzz
	endif
	ec
endfunc "}}}

" ** Helper functions {{{
" Sorting {{{
func! s:complen(s1, s2)
	" By length
	let [len1, len2] = [strlen(a:s1), strlen(a:s2)]
	retu len1 == len2 ? 0 : len1 > len2 ? 1 : -1
endfunc

func! s:compmatlen(s1, s2)
	" By match length
	let mln1  = s:shortest(s:matchlens(a:s1, s:compat))
	let mln2  = s:shortest(s:matchlens(a:s2, s:compat))
	retu mln1 == mln2 ? 0 : mln1 > mln2 ? 1 : -1
endfunc

func! s:compword(s1, s2)
	" By word-only (no non-word in match)
	let wrd1  = s:wordonly(s:matchlens(a:s1, s:compat))
	let wrd2  = s:wordonly(s:matchlens(a:s2, s:compat))
	retu wrd1 == wrd2 ? 0 : wrd1 > wrd2 ? 1 : -1
endfunc

func! s:comptime(s1, s2)
	" By last modified time
	let [time1, time2] = [getftime(a:s1), getftime(a:s2)]
	retu time1 == time2 ? 0 : time1 < time2 ? 1 : -1
endfunc

func! s:matchlens(str, pat, ...)
	if empty(a:pat) || index(['^','$'], a:pat) >= 0
		retu {}
	endif
	let st   = exists('a:1') ? a:1 : 0
	let lens = exists('a:2') ? a:2 : {}
	let nr   = exists('a:3') ? a:3 : 0
	if match(a:str, a:pat, st) != -1
		let start = match(a:str, a:pat, st)
		let str   = matchstr(a:str, a:pat, st)
		let len   = len(str)
		let end   = matchend(a:str, a:pat, st)
		let lens  = extend(lens, { nr : [len, str] })
		let lens  = s:matchlens(a:str, a:pat, end, lens, nr + 1)
	endif
	retu lens
endfunc

func! s:shortest(lens)
	let lns = []
	for nr in keys(a:lens)
		cal add(lns, a:lens[nr][0])
	endfor
	retu min(lns)
endfunc

func! s:wordonly(lens)
	let lens  = a:lens
	let minln = s:shortest(lens)
	cal filter(lens, 'minln == v:val[0]')
	for nr in keys(lens)
		if match(lens[nr][1], '\W') >= 0 | retu 1 | endif
	endfor
	retu 0
endfunc

func! s:mixedsort(s1, s2)
	let cmatlen = s:compmatlen(a:s1, a:s2)
	let ctime   = s:comptime(a:s1, a:s2)
	let clen    = s:complen(a:s1, a:s2)
	let cword   = s:compword(a:s1, a:s2)
	retu 3 * cmatlen + 3 * ctime + 2 * clen + cword
endfunc
"}}}

" Statusline {{{
func! s:statusline(...)
	let itemtypes = [
				\ ['files', 'fil'],
				\ ['buffers', 'buf'],
				\ ['mru files', 'mru'],
				\ ]
	if !g:ctrlp_mru_files
		cal remove(itemtypes, 2)
	endif
	let max     = len(itemtypes) - 1
	let next    = itemtypes[s:walker(max, s:itemtype,  1, 1)][1]
	let prev    = itemtypes[s:walker(max, s:itemtype, -1, 1)][1]
	let item    = itemtypes[s:itemtype][0]
	let focus   = s:Focus() ? 'prt'  : 'win'
	let byfname = s:byfname ? 'file' : 'path'
	let regex   = s:regexp  ? '%#LineNr# regex %*' : ''
	let focus   = '%#LineNr# '.focus.' %*'
	let byfname = '%#Character# '.byfname.' %*'
	let item    = '%#Character# '.item.' %*'
	let slider  = ' <'.prev.'>={'.item.'}=<'.next.'>'
	let dir     = ' %=%<%#LineNr# '.getcwd().' %*'
	let marked  = s:opmul ? exists('s:marked') ? ' <'.s:dismarks(s:marked).'>' : ' <+>' : ''
	let &l:stl  = focus.byfname.regex.slider.marked.dir
endfunc

func! s:progress(len)
	let [cnt, dir] = ['%#Function# '.a:len.' %*', ' %=%<%#LineNr# '.getcwd().' %*']
	let &l:stl = cnt.dir
	redr
endfunc

func! s:dismarks(marked)
	let marked = deepcopy(a:marked)
	cal map(marked, 'split(v:val, "[\\/]")[-1]')
	if has('signs')
		let str = '+'.len(marked)
	else
		let str = '%<'
		for each in values(marked)
			let str .= ', '.each
		endfor
		let str = substitute(str, ', ', '', '')
	endif
	retu str
endfunc
"}}}

" Paths {{{
func! s:dirfilter(val)
	retu isdirectory(a:val) && match(a:val, '[\/]\.\{,2}$') < 0 ? 1 : 0
endfunc

func! s:parentdir(curr)
	let parent = substitute(a:curr, '[\/]\zs[^\/]\+[\/]\?$', '', '')
	if parent != a:curr
		sil! exe 'lc!' parent
	endif
endfunc

func! s:createparentdirs(arr)
	let curr = ''
	for each in a:arr
		let curr = empty(curr) ? each : curr.s:lash.each
		cal ctrlp#utils#mkdir(curr)
	endfor
	retu curr
endfunc

func! s:listdirs(path,parent)
	let str = ''
	for entry in filter(split(globpath(a:path, '*'), '\n'), 'isdirectory(v:val)')
		let str .= a:parent.split(entry, '[\/]')[-1] . "\n"
	endfor
	retu str
endfunc

func! ctrlp#compl(A,L,P)
	let haslash = match(a:A, '[\/]')
	let parent = substitute(a:A, '[^\/]*$', '', 'g')
	let path = !haslash ? parent : haslash > 0 ? getcwd().s:lash.parent : getcwd()
	retu s:listdirs(path,parent)
endfunc
"}}}

" Highlighting {{{
func! s:syntax()
	sy match CtrlPNoEntries '^ == NO MATCHES ==$'
	sy match CtrlPLineMarker '^>'
	hi link CtrlPNoEntries Error
	hi CtrlPLineMarker guifg=bg
endfunc

func! s:highlight(pat, grp)
	cal clearmatches()
	if !empty(a:pat) && a:pat != '..'
		let pat = substitute(a:pat, '\~', '\\~', 'g')
		if !s:regexp | let pat = escape(pat, '.') | endif
		" Match only filename
		if s:byfname
			let pat = substitute(pat, '\[\^\(.\{-}\)\]\\{-}', '[^\\/\1]\\{-}', 'g')
			let pat = substitute(pat, '$', '\\ze[^\\/]*$', 'g')
		endif
		cal matchadd(a:grp, '\c'.pat)
		cal matchadd('CtrlPLineMarker', '^>')
	endif
endfunc
"}}}

" Prompt history {{{
func! s:gethistloc()
	let cache_dir = ctrlp#utils#cachedir().s:lash.'hist'
	let cache_file = cache_dir.s:lash.'cache.txt'
	retu [cache_dir, cache_file]
endfunc

func! s:gethistdata()
	retu ctrlp#utils#readfile(s:gethistloc()[1])
endfunc

func! s:recordhist(str)
	if empty(a:str) || !s:maxhst | retu | endif
	let hst = s:hstry
	if len(hst) > 1 && hst[1] == a:str | retu | endif
	cal extend(hst, [a:str], 1)
	if len(hst) > s:maxhst
		cal remove(hst, s:maxhst, -1)
	endif
endfunc
"}}}

" Signs {{{
func! s:unmarksigns()
	if !s:dosigns() | retu | endif
	for key in keys(s:marked)
		exe 'sign unplace' key 'buffer='.s:bufnr
	endfor
endfunc

func! s:remarksigns(nls)
	if !s:dosigns() | retu | endif
	let nls = deepcopy(a:nls)
	let ic = 1
	while ic <= len(nls)
		let filpath = s:itemtype ? nls[ic - 1] : getcwd().s:lash.nls[ic - 1]
		let key = s:dictindex(s:marked, filpath)
		if key > 0
			exe 'sign place' key 'line='.ic.' name=ctrlpmark buffer='.s:bufnr
		endif
		let ic+= 1
	endwhile
endfunc

func! s:dosigns()
	retu exists('s:marked') && s:bufnr > 0 && s:opmul && has('signs')
endfunc
"}}}

" Dictionaries {{{
func! s:dictindex(dict, expr)
	for key in keys(a:dict)
		let val = a:dict[key]
		if val == a:expr
			retu key
		endif
	endfor
	retu -1
endfunc

func! s:vacantdict(dict)
	let vac = []
	for ic in range(1, max(keys(a:dict)))
		if !has_key(a:dict, ic)
			cal add(vac, ic)
		endif
	endfor
	retu vac
endfunc
"}}}

" Buffers {{{
func! s:buftab(bufnum)
	" Check if the file's already opened in a tab
	for nr in range(1, tabpagenr('$'))
		" Get a list of the buffers in the nr tab
		let buflist = tabpagebuflist(nr)
		" If it has the buffer we're looking for
		if match(buflist, a:bufnum) >= 0
			" Get the number of windows
			let [buftabnr, tabwinnrs] = [nr, tabpagewinnr(nr, '$')]
			" Find the buffer that we know is in this tab
			for ewin in range(1, tabwinnrs)
				if buflist[ewin - 1] == a:bufnum
					retu [ewin, buftabnr]
				endif
			endfor
		endif
	endfor
	retu [0, 0]
endfunc

func! s:normbuf()
	let winnrs = []
	for each in range(1, winnr('$'))
		let bufnr = winbufnr(each)
		if getbufvar(bufnr, '&bl') && empty(getbufvar(bufnr, '&bt'))
					\ && getbufvar(bufnr, '&ma')
			cal add(winnrs, each)
		endif
	endfor
	retu winnrs
endfunc

func! s:setupblank()
	setl noswf nobl nonu nowrap nolist nospell cul nocuc wfh fdc=0 tw=0 bt=nofile bh=unload
	if v:version >= '703'
		setl nornu noudf cc=0
	endif
endfunc

func! s:leavepre()
	if s:cconex | cal ctrlp#clearallcaches() | endif
	cal ctrlp#utils#writecache(s:hstry, s:gethistloc()[0], s:gethistloc()[1])
endfunc

func! s:checkbuf()
	if exists('s:init') | retu | endif
	if exists('s:bufnr') && s:bufnr > 0
		exe s:bufnr.'bw!'
		unl! s:bufnr
	endif
endfunc
"}}}

" Misc {{{
func! s:openfile(cmd)
	try
		exe a:cmd
	catch
		echoh Error
		echon 'Operation can''t be completed. Make sure filename is valid.'
		echoh None
	endtry
endfunc

func! s:walker(max, pos, dir, ...)
	if a:dir == 1
		let pos = a:pos < a:max ? a:pos + 1 : 0
	elseif a:dir == -1
		let pos = a:pos > 0 ? a:pos - 1 : a:max
	endif
	if !g:ctrlp_mru_files && pos == 2 && !exists('a:1')
		let jmp = pos == a:max ? 0 : 3
		let pos = a:pos == 1 ? jmp : 1
	endif
	retu pos
endfunc

func! s:matchsubstr(item, pat)
	retu match(split(a:item, '[\/]\ze[^\/]\+$')[-1], a:pat)
endfunc

func! s:maxfiles(len)
	retu s:maxfiles && a:len > s:maxfiles ? 1 : 0
endfunc

func! s:insertcache(str)
	let cache_file = ctrlp#utils#cachefile()
	if filereadable(cache_file)
		let data = readfile(cache_file)
		if index(data, a:str) >= 0 | retu | endif
		if strlen(a:str) <= strlen(data[0])
			let pos = 0
		elseif strlen(a:str) >= strlen(data[-1])
			let pos = len(data) - 1
		else
			" Boost the value
			let strlen = abs((strlen(a:str) - strlen(data[0])) * 100000)
			let fullen = abs(strlen(data[-1]) - strlen(data[0]))
			let posi = string(len(data) * strlen / fullen)
			" Find and move the floating point back
			let floatpos = stridx(posi, '.')
			let posi = substitute(posi, '\.', '', 'g')
			let posi = join(insert(split(posi, '\zs'), '.', floatpos - 5), '')
			" Get the approximate integer
			let pos = float2nr(round(str2float(posi)))
		endif
		cal insert(data, a:str, pos)
		cal ctrlp#utils#writecache(data)
	endif
endfunc

func! s:lscommand()
	let usercmd = g:ctrlp_user_command
	if type(usercmd) == 1
		retu usercmd
	elseif type(usercmd) == 3 && len(usercmd) >= 2
				\ && !empty(usercmd[0]) && !empty(usercmd[1])
		let rmarker = usercmd[0]
		" Find a repo root if existed
		cal s:FindRoot(getcwd(), rmarker, 0, 1)
		if !exists('s:vcsroot') || ( exists('s:vcsroot') && empty(s:vcsroot) )
			" Try the secondary_command if defined
			retu len(usercmd) == 3 ? usercmd[2] : ''
		else
			let s:vcscmd = s:lash == '\' ? 1 : 0
			retu usercmd[1]
		endif
	endif
endfunc
"}}}
"}}}

if has('autocmd') "{{{
	aug CtrlPAug
		au!
		au BufEnter ControlP cal s:checkbuf()
		au BufLeave ControlP cal s:Close()
		au VimLeavePre * cal s:leavepre()
	aug END
endif "}}}

" * Initialization {{{
func! s:SetLines(type)
	let s:itemtype = a:type
	let types = [
				\ 's:ListAllFiles(getcwd())',
				\ 's:ListAllBuffers()',
				\ 'ctrlp#mrufiles#list(-1)',
				\ ]
	let g:ctrlp_lines = eval(types[a:type])
endfunc

func! ctrlp#init(type, ...)
	if exists('s:init') | retu | endif
	let [s:matches, s:init] = [1, 1]
	let a1 = exists('a:1') ? a:1 : ''
	cal ctrlp#SetWorkingPath(a1)
	cal s:Open('ControlP')
	cal s:setupblank()
	cal s:MapKeys()
	cal s:SetLines(a:type)
	cal s:BuildPrompt(1)
	cal s:syntax()
endfunc
"}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
