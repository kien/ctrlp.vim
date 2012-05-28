# ctrlp.vim
Full path fuzzy __file__, __buffer__, __mru__ and __tag__ finder for Vim.

* Written in pure Vimscript for MacVim and Vim 7.0+.
* Full support for Vim’s regexp as search pattern.
* Built-in Most Recently Used (MRU) files monitoring.
* Built-in project’s root finder.
* Open multiple files at once.
* Create new files and directories.
* [Extensible][3].

![ctrlp][1]

## Basic Usage
* Press `<c-p>` or run `:CtrlP [dir]` to invoke CtrlP in find file mode.
* Run `:CtrlPBuffer` or `:CtrlPMRU` to invoke CtrlP in buffer or MRU mode.
* Run `:CtrlPMixed` to search in a mix of files, buffers and MRU files.

Once CtrlP is open:

* Press `<c-f>` and `<c-b>` to cycle between modes.
* Press `<c-d>` to switch to filename only search instead of full path.
* Press `<c-r>` to switch to regexp mode.
* Press `<F5>` to purge the cache for the current directory and get new files.
* End the input string with a colon `:` followed by a command to execute it
after opening the file:  
Use `:45` to jump to line 45.  
Use `:/any\:string` to jump to the first instance of `any:string`.  
Use `:difft` when opening multiple files to run `:difft` on the first 4 files.
* Submit two or more dots `.` as the input string to go backward the directory
tree by one or multiple levels.
* Use `<c-y>` to create a new file and its parent dirs.
* Use `<c-z>` to mark/unmark multiple files and `<c-o>` to open them.

## Basic Options
* Change the mapping to invoke CtrlP:

    ```vim
    let g:ctrlp_map = '<c-p>'
    ```

* When invoked, unless a starting directory is specified, CtrlP will
automatically set its local working directory according to this variable:

    ```vim
    let g:ctrlp_working_path_mode = 2
    ```

    0 - don’t manage working directory.  
    1 - the directory of the current file.  
    2 - the nearest ancestor that contains one of these directories or files:
    `.git/` `.hg/` `.svn/` `.bzr/` `_darcs/`

* To exclude files or directories from the search, use the Vim’s option
`wildignore` and/or the option `g:ctrlp_custom_ignore`:

    ```vim
    set wildignore+=*/tmp/*,*.so,*.swp,*.zip  " MacOSX/Linux
    set wildignore+=tmp\*,*.swp,*.zip,*.exe   " Windows

    let g:ctrlp_custom_ignore = '\.git$\|\.hg$\|\.svn$'
    let g:ctrlp_custom_ignore = {
      \ 'dir':  '\.git$\|\.hg$\|\.svn$',
      \ 'file': '\.exe$\|\.so$\|\.dll$',
      \ 'link': 'some_bad_symbolic_links',
      \ }
    ```

* Use a custom file listing command:

    ```vim
    let g:ctrlp_user_command = 'find %s -type f'        " MacOSX/Linux
    let g:ctrlp_user_command = 'dir %s /-n /b /s /a-d'  " Windows
    ```

* Define an external matcher:

    ```vim
    let g:ctrlp_match_func = {}
    ```

_Check [the docs][2] for more mappings, commands and options._

[1]: http://i.imgur.com/yIynr.png
[2]: https://github.com/kien/ctrlp.vim/blob/master/doc/ctrlp.txt
[3]: https://github.com/kien/ctrlp.vim/tree/extensions
