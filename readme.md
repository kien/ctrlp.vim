Full path fuzzy file finder with an intuitive interface. Written in pure
Vimscript. Has full support for Vim’s regexp as search pattern, and more.

![ctrlp][1]
![ctrlp file name mode, match window focused][2]

## Basic Usage

* Press `<c-p>` or run `:CtrlP` to invoke CtrlP.
* Use `*` `?` `^` `+` or `|` in the prompt to submit the string as a Vim’s
regexp pattern. Or press `<c-r>` to switch to full regexp mode.
* Ever remember only the file name but not where it is? Press `<c-d>` while in
the prompt to switch to file name only search. Press `<c-d>` again to switch
back to full path search.
* End the input string with a colon `:` followed by a number to jump to that
line in the selected file.
    e.g. `abc:45` to open the file matched the pattern `abc` and jump to
    line 45.
* Press `<c-f>` to switch to find buffer mode. Or run `:CtrlPBuffer`.

## Basic Options

* Change the mapping to invoke CtrlP with:
    ```vim
    let g:ctrlp_map = '<c-p>'
    ```
* When starting up the prompt, automatically set the working directory to:  
    1 - the parent directory of the current file.  
    2 - the nearest ancestor that contains one of these directories/files:  
        .git/  
        .hg/  
        .bzr/  
        _darcs/  
        root.dir  
        .vimprojects  
    0 - don’t manage working directory.  
    ```vim
    let g:ctrlp_working_path_mode = 1
    ```
* You can also use the set-working-directory functionality outside of CtrlP by
adding the following line to your vimrc; the parameter is the same (1, 2 and 0):
    ```vim
    au BufEnter * cal ctrlp#SetWorkingPath(2)
    ```

Check the docs for more mappings and options.

[1]: http://designslicer.com/vim/images/ctrlp1.png
[2]: http://designslicer.com/vim/images/ctrlp2.png
