# Use ctrlp.vim to search for anything you like
Add something else other than files, buffers and MRU files for CtrlP to search for
and perform any actions on.

There are 2 points of entry:
### Input
Provide ctrlp with a simple list of strings to search in.

### Output
Specify an action to perform on the selected string.

## Example:
To see how it works, get the [sample.vim][1] from this branch and place it
(along with the directories) somewhere in your runtimepath. Then put this into
your vimrc:

```vim
let g:ctrlp_extensions = ['sample']
```

A 4th search type will show up when you open CtrlP.

_Checkout [sample.vim][1] for more details_

[1]: https://github.com/kien/ctrlp.vim/blob/extensions/autoload/ctrlp/sample.vim
