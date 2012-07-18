# ctrlp.vim
Full path fuzzy __file__, __buffer__, __mru__, __tag__, __...__ finder for Vim.  
Version: 1.78.

* Written in pure Vimscript for MacVim, gVim and Vim 7.0+.
* Full support for Vim's regexp as search patterns.
* Built-in Most Recently Used (MRU) files monitoring.
* Built-in project's root finder.
* Open multiple files at once.
* Create new files and directories.
* [Extensible][2].

![ctrlp][1]

## Basic Usage
* Run `:CtrlP` or `:CtrlP [starting-directory]` to invoke CtrlP in find file mode.
* Run `:CtrlPBuffer` or `:CtrlPMRU` to invoke CtrlP in find buffer or find MRU file mode.
* Run `:CtrlPMixed` to search in Files, Buffers and MRU files at the same time.

Check `:help ctrlp-commands` and `:help ctrlp-extensions` for other commands.

##### Once CtrlP is open:
* Press `<c-f>` and `<c-b>` to cycle between modes.
* Press `<c-d>` to switch to filename only search instead of full path.
* Press `<c-r>` to switch to regexp mode.
* Press `<F5>` to purge the cache for the current directory and get new files.
* Use `<c-n>`, `<c-p>` to select the next/previous string in the prompt's history.
* Use `<c-y>` to create a new file and its parent directories.
* Use `<c-z>` to mark/unmark multiple files and `<c-o>` to open them.

Run `:help ctrlp-mappings` or submit `?` in CtrlP for more mapping help.

* Submit two or more dots `..` to go up the directory tree by one or multiple levels.
* End the input string with a colon `:` followed by a command to execute it on the opening file(s):  
Use `:25` to jump to line 25.  
Use `:/any\:\ string` to jump to the first instance of `any: string`.  
Use `:difft` when opening multiple files to run `:difft` on the first 4 files.

## Basic Options
* Change the default mapping and the default command to invoke CtrlP:

    ```vim
    let g:ctrlp_map = '<c-p>'
    let g:ctrlp_cmd = 'CtrlP'
    ```

* When invoked, unless a starting directory is specified, CtrlP will set its local working directory
according to this variable:

    ```vim
    let g:ctrlp_working_path_mode = 2
    ```

    0 - don't manage working directory.  
    1 - the directory of the current file.  
    2 - the nearest ancestor that contains one of these directories or files:
    `.git` `.hg` `.svn` `.bzr` `_darcs`

    Define additional root markers with the `g:ctrlp_root_markers` option.

* Exclude files and directories using Vim's `wildignore` and CtrlP's own `g:ctrlp_custom_ignore`:

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

Check `:help ctrlp-options` for other options.

## FAQs
__Q:__ Why aren't recently created files listed?  
__Q:__ Why do ignored files show up in the results?  
__A:__ After changing some options like `wildignore, g:ctrlp_custom_ignore, g:ctrlp_max_files, ...`, or having
new files added to the relevant working directory independently of CtrlP, you need to clear the old cache by
pressing `<F5>` in the prompt, or if you want to be sure, run `:CtrlPClearAllCaches` from Vim's command line.

__Q:__ How to open the selected file in a new split or in a new tab?  
__Q:__ How to _always_ open the selected file in a new split or in a new tab with `<cr>`?  
__Q:__ How to use _this_ key to do _that_ action in the prompt?  
__A:__ Take a look at `:help ctrlp-mappings` and the corresponding option `:help g:ctrlp_prompt_mappings`.

__Q:__ Instead of `:lcd` into a parent directory, typing `..`, `...`, `../../`, etc just shows the files or
directories containing dots in its name, is this a known bug on Windows/Linux/MacOSX?  
__A:__ Just press `<cr>` to submit the dots.

__Q:__ Why are some deep directories/files under the current working directory not being indexed?  
__A:__ This is most likely because one or both of the limits set by `g:ctrlp_max_files` and `g:ctrlp_max_depth`
have been reached.

Invest a few minutes to skim through the documentation at `:help ctrlp.txt`. If you can't find the answer to
your question there nor in the old issues here on Github, open a new issue and let me know. For a bug report,
make sure to include some informations like steps to reproduce and any related configurations.

## Installation
Use your favorite method or check the homepage for a [quick installation guide][3].

[1]: http://i.imgur.com/yIynr.png
[2]: https://github.com/kien/ctrlp.vim/tree/extensions
[3]: http://kien.github.com/ctrlp.vim#installation
