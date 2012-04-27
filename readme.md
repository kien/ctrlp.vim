# Use ctrlp.vim to search for anything you like
### Input
Provide ctrlp with a simple list of strings to search in.

### Output
Specify an action to perform on the selected string.

## Example:
To see how it works, get the [sample.vim][1] from this branch and place it
(along with the directories) somewhere in your runtimepath. Then put this into
your vimrc, a new search type will show up when you open CtrlP:

```vim
let g:ctrlp_extensions = ['sample']
```

_Check out [sample.vim][1] for more details. For a list of extensions bundled with CtrlP, see `:help ctrlp-extensions`._

### Extensions in the wild:
* [tacahiroy/ctrlp.vim.exts][2]
* [sgur/ctrlp-extensions.vim][3]
* [mark][4], [register][5], [launcher][6] and [hackernews][7] by [mattn][8]

[1]: https://github.com/kien/ctrlp.vim/blob/extensions/autoload/ctrlp/sample.vim
[2]: https://github.com/tacahiroy/ctrlp.vim.exts
[3]: https://github.com/sgur/ctrlp-extensions.vim
[4]: https://github.com/mattn/ctrlp-mark
[5]: https://github.com/mattn/ctrlp-register
[6]: https://github.com/mattn/ctrlp-launcher
[7]: https://github.com/mattn/ctrlp-hackernews
[8]: https://github.com/mattn
