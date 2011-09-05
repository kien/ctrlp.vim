## About
* Full path fuzzy file finder with an intuitive interface.
* Has full support for Vim’s regexp as search pattern, and more.
* Written in pure Vimscript for MacVim and Vim 7.0+.

![ctrlp][1]

## Basic Usage
* Press `<c-p>` or run `:CtrlP` to invoke CtrlP.
* Ever remember only a file’s name but not where it is? Press `<c-d>` while
CtrlP is open to switch to filename only search. Press `<c-d>` again to switch
back to full path search.
* Use `*` `?` `^` `+` or `|` in the prompt to submit the string as a Vim’s
regexp pattern. Or press `<c-r>` to switch to full regexp mode.
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
* When starting up CtrlP, it automatically sets the working directory to:  
    ```vim
    let g:ctrlp_working_path_mode = 1
    ```
    1 - the parent directory of the current file.  
    2 - the nearest ancestor that contains one of these directories or files:  
        ```
        .git/
        .hg/
        .bzr/
        _darcs/
        root.dir
        .vimprojects
        ```
    0 - don’t manage working directory.
* You can also use the set-working-directory functionality outside of CtrlP by
adding the following line to your vimrc; the parameter is the same (1, 2 or 0):
    ```vim
    au BufEnter * cal ctrlp#SetWorkingPath(2)
    ```

Check the docs for more mappings, commands and options.

[1]: http://designslicer.com/vim/images/ctrlp1.png
[2]: http://designslicer.com/vim/images/ctrlp2.png
