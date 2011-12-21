" =============================================================================
" File:          autoload/ctrlp/buffertag.vim
" Description:   Buffer Tag extension
" Maintainer:    Kien Nguyen <github.com/kien>
" =============================================================================

" Init {{{1
if exists('g:loaded_ctrlp_buftag') && g:loaded_ctrlp_buftag
	fini
en
let g:loaded_ctrlp_buftag = 1

let s:buftag_var = ['ctrlp#buffertag#init(s:crfile, s:crbufnr)',
	\ 'ctrlp#buffertag#accept', 'buffer tags', 'bft']

let g:ctrlp_ext_vars = exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
	\ ? add(g:ctrlp_ext_vars, s:buftag_var) : [s:buftag_var]

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

fu! s:opts()
	let opts = {
		\ 'g:ctrlp_buftag_systemenc': ['s:enc', &enc],
		\ 'g:ctrlp_buftag_ctags_bin': ['s:bin', ''],
		\ 'g:ctrlp_buftag_types': ['s:usr_types', ''],
		\ }
	for [ke, va] in items(opts)
		exe 'let' va[0] '=' string(exists(ke) ? eval(ke) : va[1])
	endfo
endf
cal s:opts()

fu! s:bins()
	let bins = [
		\ 'ctags-exuberant',
		\ 'exuberant-ctags',
		\ 'exctags',
		\ '/usr/local/bin/ctags',
		\ '/opt/local/bin/ctags',
		\ 'ctags',
		\ 'ctags.exe',
		\ 'tags',
		\ ]
	if empty(s:bin)
		for bin in bins
			if executable(bin)
				let s:bin = bin
				brea
			en
		endfo
	el
		let s:bin = expand(s:bin, 1)
	en
endf
cal s:bins()

" Arguments {{{2
let s:types = {
	\ 'asm'       : '--language-force=asm        --asm-types=dlmt',
	\ 'aspperl'   : '--language-force=asp        --asp-types=fsv',
	\ 'aspvbs'    : '--language-force=asp        --asp-types=fsv',
	\ 'awk'       : '--language-force=awk        --awk-types=f',
	\ 'beta'      : '--language-force=beta       --beta-types=fsv',
	\ 'c'         : '--language-force=c          --c-types=dgsutvf',
	\ 'cpp'       : '--language-force=c++        --c++-types=nvdtcgsuf',
	\ 'cs'        : '--language-force=c#         --c#-types=dtncEgsipm',
	\ 'cobol'     : '--language-force=cobol      --cobol-types=dfgpPs',
	\ 'eiffel'    : '--language-force=eiffel     --eiffel-types=cf',
	\ 'erlang'    : '--language-force=erlang     --erlang-types=drmf',
	\ 'expect'    : '--language-force=tcl        --tcl-types=cfp',
	\ 'fortran'   : '--language-force=fortran    --fortran-types=pbceiklmntvfs',
	\ 'html'      : '--language-force=html       --html-types=af',
	\ 'java'      : '--language-force=java       --java-types=pcifm',
	\ 'javascript': '--language-force=javascript --javascript-types=f',
	\ 'lisp'      : '--language-force=lisp       --lisp-types=f',
	\ 'lua'       : '--language-force=lua        --lua-types=f',
	\ 'make'      : '--language-force=make       --make-types=m',
	\ 'pascal'    : '--language-force=pascal     --pascal-types=fp',
	\ 'perl'      : '--language-force=perl       --perl-types=clps',
	\ 'php'       : '--language-force=php        --php-types=cdvf',
	\ 'python'    : '--language-force=python     --python-types=cmf',
	\ 'rexx'      : '--language-force=rexx       --rexx-types=s',
	\ 'ruby'      : '--language-force=ruby       --ruby-types=cfFm',
	\ 'scheme'    : '--language-force=scheme     --scheme-types=sf',
	\ 'sh'        : '--language-force=sh         --sh-types=f',
	\ 'csh'       : '--language-force=sh         --sh-types=f',
	\ 'zsh'       : '--language-force=sh         --sh-types=f',
	\ 'slang'     : '--language-force=slang      --slang-types=nf',
	\ 'sml'       : '--language-force=sml        --sml-types=ecsrtvf',
	\ 'sql'       : '--language-force=sql        --sql-types=cFPrstTvfp',
	\ 'tcl'       : '--language-force=tcl        --tcl-types=cfmp',
	\ 'vera'      : '--language-force=vera       --vera-types=cdefgmpPtTvx',
	\ 'verilog'   : '--language-force=verilog    --verilog-types=mcPertwpvf',
	\ 'vim'       : '--language-force=vim        --vim-types=avf',
	\ 'yacc'      : '--language-force=yacc       --yacc-types=l',
	\ }

if executable('jsctags')
	cal extend(s:types, { 'javascript': { 'args': '-f -', 'bin': 'jsctags' } })
en

if type(s:usr_types) == 4
	cal extend(s:types, s:usr_types)
en
" Utilities {{{1
fu! s:validfile(fname, ftype)
	if ( !empty(a:fname) || !empty(a:ftype) ) && filereadable(a:fname)
		\ && index(keys(s:types), a:ftype) >= 0 | retu 1 | en
	retu 0
endf

fu! s:exectags(cmd)
	if exists('+ssl')
		let [ssl, &ssl] = [&ssl, 0]
	en
	if &sh =~ 'cmd\.exe'
		let [sxq, &sxq, shcf, &shcf] = [&sxq, '"', &shcf, '/s /c']
	en
	let output = system(a:cmd)
	if &sh =~ 'cmd\.exe'
		let [&sxq, &shcf] = [sxq, shcf]
	en
	if exists('+ssl')
		let &ssl = ssl
	en
	retu output
endf

fu! s:exectagsonfile(fname, ftype)
	let args = '-f - --sort=no --excmd=pattern --fields=nKs '
	if type(s:types[a:ftype]) == 1
		let args .= s:types[a:ftype]
		let bin = s:bin
	elsei type(s:types[a:ftype]) == 4
		let args = s:types[a:ftype]['args']
		let bin = expand(s:types[a:ftype]['bin'], 1)
	en
	if empty(bin) | retu '' | en
	let cmd = s:esctagscmd(bin, args, a:fname)
	if empty(cmd) | retu '' | en
	let output = s:exectags(cmd)
	if v:shell_error || output =~ 'Warning: cannot open' | retu '' | en
	retu output
endf

fu! s:esctagscmd(bin, args, ...)
	if exists('+ssl')
		let [ssl, &ssl] = [&ssl, 0]
	en
	let fname = a:0 == 1 ? shellescape(a:1) : ''
	let cmd = shellescape(a:bin).' '.a:args.' '.fname
	if exists('+ssl')
		let &ssl = ssl
	en
	if has('iconv')
		let last = s:enc != &enc ? s:enc : !empty($LANG) ? $LANG : &enc
		let cmd = call('iconv', [cmd, &encoding, last])
	en
	if empty(cmd)
		cal ctrlp#msg('Encoding conversion failed!')
	en
	retu cmd
endf

fu! s:process(fname, ftype)
	if !s:validfile(a:fname, a:ftype) | retu [] | endif
	let ftime = getftime(a:fname)
	if has_key(g:ctrlp_buftags, a:fname)
		\ && g:ctrlp_buftags[a:fname]['time'] >= ftime
		let data = g:ctrlp_buftags[a:fname]['data']
	el
		let data = s:exectagsonfile(a:fname, a:ftype)
		let cache = { a:fname : { 'time': ftime, 'data': data } }
		cal extend(g:ctrlp_buftags, cache)
	en
	let [raw, lines] = [split(data, '\n\+'), []]
	for line in raw | if len(split(line, ';"')) == 2
		cal add(lines, s:parseline(line))
	en | endfo
	retu lines
endf

fu! s:parseline(line)
	let eval = '\v^([^\t]+)\t(.+)\t\/\^(.+)\$\/\;\"\t(.+)\tline(no)?\:(\d+)'
	let vals = matchlist(a:line, eval)
	if empty(vals) | retu '' | en
	retu vals[1].'	'.vals[4].'|'.vals[6].'| '.vals[3]
endf
" Public {{{1
fu! ctrlp#buffertag#init(fname, bufnr)
	let s:fname = a:fname
	let ftype = get(split(getbufvar(a:bufnr, '&filetype'), '\.'), 0, '')
	sy match CtrlPTabExtra '\zs\t.*\ze$'
	hi link CtrlPTabExtra Comment
	retu s:process(a:fname, ftype)
endf

fu! ctrlp#buffertag#accept(mode, str)
	cal ctrlp#exit()
	if a:mode == 't'
		exe 'tabe' ctrlp#fnesc(s:fname)
	elsei a:mode == 'h'
		sp
	elsei a:mode == 'v'
		vs
	en
	cal ctrlp#j2l(str2nr(matchstr(a:str, '^[^\t]\+\t\+[^\t|]\+|\zs\d\+\ze|')))
endf

fu! ctrlp#buffertag#id()
	retu s:id
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
