# ctrlp.vim
Full path fuzzy file and buffer finder for Vim.

* Written in pure Vimscript for MacVim and Vim 7.0+.
* Has full support for Vim’s regexp as search pattern, and more.

![ctrlp][1]

## Basic Usage
* Press `<c-p>` or run `:CtrlP` to invoke CtrlP.
* Ever remember only a file’s name but not where it is?  
Press `<c-d>` while CtrlP is open to switch to filename only search.  
Press `<c-d>` again to switch back to full path search.
* Use `*` `?` `^` `+` or `|` in the prompt to submit the string as a Vim’s
regexp pattern.  
Or press `<c-r>` to switch to full regexp mode.
* End the input string with a colon `:` followed by a number to jump to that
line in the selected file.  
e.g. `abc:45` to open the file matched the pattern and jump to line 45.
* Press `<c-f>` to toggle find buffer mode/find file mode while CtrlP is open.  
Run `:CtrlPBuffer` to start CtrlP in find buffer mode.

_Screenshot: filename only mode with the match window focused._  
![ctrlp filename mode, match window focused][2]

## Basic Options
* Change the mapping to invoke CtrlP:
    ```vim
    let g:ctrlp_map = '<c-p>'
    ```
* When starting up CtrlP, it automatically sets the working directory according
to this variable:  

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

* You can also use the set-working-directory functionality above outside of
CtrlP by adding the following line to your vimrc.  
The parameter is the same (1, 2 or 0):

    ```vim
    au BufEnter * cal ctrlp#SetWorkingPath(2)
    ```

_Check [the docs][3] for more mappings, commands and options._

[1]: http://i.imgur.com/lQScr.png
[2]: http://i.imgur.com/MyRIv.png
[3]: https://github.com/kien/ctrlp.vim/blob/master/doc/ctrlp.txt
