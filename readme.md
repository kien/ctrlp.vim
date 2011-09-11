# ctrlp.vim
Full path fuzzy __file__, __buffer__ and __MRU__ file finder for Vim.

* Written in pure Vimscript for MacVim and Vim 7.0+.
* Has full support for Vim’s regexp as search pattern, and more.
* Can also find file in most recently used files.

![ctrlp][1]

## Basic Usage
* Press `<c-p>` or run `:CtrlP` to invoke CtrlP.
* Press `<c-f>` and `<c-b>` while CtrlP is open to switch between find file, find buffer, and find MRU file modes.
* Ever remember only a file’s name but not where it is? Press `<c-d>` while CtrlP is open to switch to filename only search.
* Use `*` `?` `^` `+` or `|` in the prompt to submit the string as a Vim’s regexp pattern.
* Or press `<c-r>` while CtrlP is open to switch to full regexp search mode.
* End the input string with a colon `:` followed with a number to jump to that line in the selected file.  
e.g. `abc:45` to open the file matched the pattern and jump to line 45.
* Submit two dots `..` as the input string to go backward the directory tree by 1 level.

_Screenshot: filename only mode with the match window focused._  
![ctrlp filename mode, match window focused][2]

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
    set wildignore+=.git/*,.hg/*,.svn/*   " for Linux/MacOSX
    set wildignore+=.git\*,.hg\*,.svn\*   " for Windows
    ```

_Check [the docs][3] for more mappings, commands and options._

[1]: http://i.imgur.com/Gfntl.png
[2]: http://i.imgur.com/MyRIv.png
[3]: https://github.com/kien/ctrlp.vim/blob/master/doc/ctrlp.txt
