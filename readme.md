# ctrlp.vim
Fuzzy __file__, __buffer__, __mru__, __tag__, ... finder for Vim.

* Written in pure Vimscript for MacVim, gVim and Vim 7.0+.
* Full support for Vim's regexp as search patterns.
* Built-in Most Recently Used (MRU) files monitoring.
* Built-in project's root finder.
* Open multiple files at once.
* Create new files and directories.
* [Extensible][2].

![ctrlp][1]

## Installation
1. Clone the plugin into a separate directory:

    ```
    $ cd ~/.vim
    $ git clone https://github.com/kien/ctrlp.vim.git bundle/ctrlp.vim
    ```

2. Add to your `~/.vimrc`:

    ```vim
    set runtimepath^=~/.vim/bundle/ctrlp.vim
    ```

3. Run at Vim's command line:

    ```
    :helptags ~/.vim/bundle/ctrlp.vim/doc
    ```

4. Restart Vim and start reading `:help ctrlp.txt` for usage and configuration details.

On Windows, use the `$HOME/vimfiles` or the `$VIM/vimfiles` directory instead of the `~/.vim` directory.

## Usage
1. See `:help ctrlp-commands` and `:help ctrlp-extensions`.
2. Once the prompt's open:
    * Press `<c-f>` and `<c-b>` to cycle between modes.
    * Press `<c-d>` to switch to filename only search instead of full path.
    * Press `<F5>` to purge the cache for the current directory and get new files.
    * Submit two or more dots `..` to go up the directory tree by one or multiple levels.
    * Use `<c-n>`, `<c-p>` to go to the next/previous string in the prompt's history.
    * Use `<c-y>` to create a new file and its parent dirs.
    * Use `<c-z>` to mark/unmark multiple files and `<c-o>` to open them.
    * End the input string with a colon `:` followed by a command to execute it on the opening file(s).

    More at `:help ctrlp-mappings`.

## Configuration
* Unless a starting directory is specified, the local working directory will be set according to this variable:

    ```vim
    let g:ctrlp_working_path_mode = 2
    ```

    0 - don't manage working directory.  
    1 - the directory of the current file.  
    2 - the nearest ancestor that contains one of these directories or files:
    `.git` `.hg` `.svn` `.bzr` `_darcs`

    Define additional root markers with the `g:ctrlp_root_markers` option.

* Exclude files and directories:

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

More at `:help ctrlp-options`.

[1]: http://i.imgur.com/yIynr.png
[2]: https://github.com/kien/ctrlp.vim/tree/extensions
