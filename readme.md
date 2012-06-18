# ctrlp.vim
Full path fuzzy __file__, __buffer__, __mru__, __tag__, __...__ finder for Vim.

* Written in pure Vimscript for MacVim, gVim and Vim 7.0+.
* Full support for Vim's regexp as search patterns.
* Built-in Most Recently Used (MRU) files monitoring.
* Built-in project's root finder.
* Open multiple files at once.
* Create new files and directories.
* [Extensible][2].

![ctrlp][1]

## Installation
Use your favorite method or check the homepage for a [quick installation guide][3].

## Basic Usage
* Run `:CtrlP` or `:CtrlP [starting-directory]` to invoke CtrlP in find file mode.
* Run `:CtrlPBuffer` or `:CtrlPMRU` to invoke CtrlP in buffer or MRU mode.
* Run `:CtrlPMixed` to search in a mix of files, buffers and MRU files.

More at `:help ctrlp-commands` and `:help ctrlp-extensions`.

##### Once CtrlP is open:
* Press `<c-f>` and `<c-b>` to cycle between modes.
* Press `<c-d>` to switch to filename only search instead of full path.
* Press `<c-r>` to switch to regexp mode.
* Press `<F5>` to purge the cache for the current directory and get new files.
* Use `<c-n>`, `<c-p>` to select the next/previous string in the prompt's history.
* Use `<c-y>` to create a new file and its parent directories.
* Use `<c-z>` to mark/unmark multiple files and `<c-o>` to open them.

More at `:help ctrlp-mappings`.

* Submit two or more dots `..` to go up the directory tree by one or multiple levels.
* End the input string with a colon `:` followed by a command to execute it on the opening file(s):  
Use `:45` to jump to line 45.  
Use `:/any\:\ string` to jump to the first instance of `any: string`.  
Use `:diffthis` when opening multiple files to run `:diffthis` on the first 4 files.

## Basic Options
* When invoked, unless a starting directory is specified, CtrlP will set its local working directory according to this variable:

    ```vim
    let g:ctrlp_working_path_mode = 2
    ```

    0 - don't manage working directory.  
    1 - the directory of the current file.  
    2 - the nearest ancestor that contains one of these directories or files:
    `.git` `.hg` `.svn` `.bzr` `_darcs`

    Define additional root markers with the `g:ctrlp_root_markers` option.

* Exclude files and directories using Vim's `wildignore` or CtrlP's own `g:ctrlp_custom_ignore` option:

    ```vim
    set wildignore+=*/tmp/*,*.so,*.swp,*.zip  " MacOSX/Linux
    set wildignore+=tmp\*,*.swp,*.zip,*.exe   " Windows

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

More at `:help ctrlp-options`.

[1]: http://i.imgur.com/yIynr.png
[2]: https://github.com/kien/ctrlp.vim/tree/extensions
[3]: http://kien.github.com/ctrlp.vim
