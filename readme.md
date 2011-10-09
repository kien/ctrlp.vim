# ctrlp.vim
Full path fuzzy __file__, __buffer__ and __MRU__ file finder for Vim.

* Written in pure Vimscript for MacVim and Vim 7.0+.
* Full support for Vim’s regexp as search pattern.
* Built-in Most Recently Used (MRU) files monitoring.
* Built-in project’s root finder.

![ctrlp][1]

## Basic Usage
* Press `<c-p>` or run `:CtrlP` to invoke CtrlP.

Once CtrlP is open:

* Press `<c-f>` and `<c-b>` to switch between find file, buffer, and MRU file modes.
* Press `<c-d>` to switch to filename only search instead of full path.
* Use `*` or `|` in the prompt to submit the string as a Vim’s regexp pattern.
* Or press `<c-r>` to switch to full regexp search mode.
* End the input string with a colon `:` followed by a command to execute after opening the file.  
e.g. `abc:45` will open the file matched the pattern and jump to line 45.
* Submit two dots `..` as the input string to go backward the directory tree by 1 level.
* Use `<c-y>` to create a new file and its parent dirs.
* Use `<c-z>` to mark/unmark files and `<c-o>` to open them.

## Basic Options
* Change the mapping to invoke CtrlP:

    ```vim
    let g:ctrlp_map = '<c-p>'
    ```

* When CtrlP is invoked, it automatically sets the working directory according to this variable:

    ```vim
    let g:ctrlp_working_path_mode = 1
    ```

    0 - don’t manage working directory.  
    1 - the parent directory of the current file.  
    2 - the nearest ancestor that contains one of these directories or files:

        .git/
        .hg/
        .bzr/
        _darcs/
        root.dir
        .vimprojects

* You can also use the set-working-directory functionality above outside of CtrlP
by adding the following line to your vimrc.  
The parameter is the same (0, 1 or 2):

    ```vim
    au BufEnter * cal ctrlp#SetWorkingPath(2)
    ```

* Enable/Disable Most Recently Used files monitoring and its functionalities:

    ```vim
    let g:ctrlp_mru_files = 1
    ```

* If you want to exclude directories or files from the search, you can use the Vim’s option `wildignore`.  
e.g. Just have something like this in your vimrc:

    ```vim
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*   " for Linux/MacOSX
    set wildignore+=.git\*,.hg\*,.svn\*         " for Windows
    ```

* Use a custom file listing command with:

    ```vim
    let g:ctrlp_user_command = 'find %s -type f'       " MacOSX/Linux
    let g:ctrlp_user_command = 'dir %s /-n /b /s /a-d' " Windows
    ```

_Check [the docs][2] for more mappings, commands and options._

[1]: http://i.imgur.com/3rtLt.png
[2]: https://github.com/kien/ctrlp.vim/blob/master/doc/ctrlp.txt
