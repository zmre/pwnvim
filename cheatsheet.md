# Cheatsheet pwnvim Hotkeys Reference

_This is a combination of built-in universal keys and things that are specific to my config._

## Misc
* `gx` to open a URL
* `gf` to open the file path under the cursor (in vim)
* `gv` to **reselect** last selection
* `gi` to go back to last insertion point and insert
* `,P` paste markdown url (auto lookup the title of the page)
* `:PasteImg` will save image to subdir if it is on clipboard
	* On mac, use `ctrl` modifier on screenshot like `cmd-ctrl-shift-4` to put screenshot on clipboard
* `g ctrl-g` show cursor col, line, word, byte offsets
* `g~`_m_ switch case of _movement_
* `'"` go to position before last edit
* `';` go to last edited line
* `g;`, `g,` go forward/backward in change list
* `di(`, `di"` delete within parents/quotes. Do `a` instead of `i` for taking out the delimiters
* `"_c`_m_ change _movement_ but blackhole the deletion so you can use the `"` register or paste
	* Alt: use `v`_m_`p` to select that which you want to change and paste over it (or use `cmd-v` instead of `p`)
* `,cd` change dir to current file's path
* `,lcd` change dir for cur buffer only to current file's path
* `,q` open quicklist with any errors
* `q:` opens command mode but in editor
	* `<C-f>` is equivalent but launches from command mode
* `F2`, `,e` Show/hide file explorer
* `F3` Quick grep with results to loclist (not live)
* `F4` Toggle showing invisible characters
* `F7` Show tags or file outline drawer
* `F8` Insert current date
* `F9` Focus mode for writing
* `F10` Quicklook preview file
* `F12` Reset syntax parsing

## Windowing
* `,x` close current buffer
* `^Ws` `:split` horiz window split
* `^Wv` `:vsplit` vert window split
* `^Wn` `:new` horz split with new
* `^Wo` `:only` make current window only one
* `^Wr` rotate windows
* `^Wc` close current window pane
* `:sb `_n_ Split the buffer window and populate new split with buffer _n_
* `H`, `L` goto prev/next buffer
* `[1`, `]1` jump to first buffer/tab (or second with 2, etc.)

## Folds
* `zf`_m_ create fold of movement _m_
* `zf/`_string_ create fold to match
* `:`_r_`fo` create fold for range _r_
* `zo`, `zc` open, close one fold
* `zO`, `zC` open, close folds recursively
* `zr`, `zm` open, close one fold level entire doc
* `zR`, `zM` open, close all folds
* `[z`, `]z` navigate between folds
* `za`, `<space>` toggle fold under cursor

## Completion
* `^N`, `^P` word completion _(INSERT)_
* `^X^L` line completion _(INSERT)_
* `^X^O` word completion _(INSERT)_
* `^X^U` to complete :emoji: symbols (then use `,e` to turn it into a symbol if desired)
* `^e` to cancel autocomplete (my config)

## Digraphs
* `^k<char1><char2>` to insert digraph with two char code
	* ✓ = OK
	* ✗ = XX
	* ™ = TM
	* © = Co
	* → = ->
* `ga` view code of char under cursor (note the digraph code at the end)
* `:help digraph-table` to view all

## Spelling
* `[s`, `]s` prev/next misspelled word
* `[S`, `]S` prev/next "bad" word (skips rare words)
* `zg` add to word list
* `zw` add to the bad word list
* `z=` suggest words
* `1z=` auto take first suggested word
* `^X^K` Autocomplete from dictionary 
* Thesaurus 
	* https://raw.githubusercontent.com/moshahmed/vim/master/thesaurus/thesaurii.txt or http://www.gutenberg.org/files/3202/files/mthesaur.txt
	* set thesaurus+=/Users/yanis/thesaurus/words.txt
	* `^X^T` show synonyms 

## Programming (many require lsp server)
* `,c ` (c space) comment, uncomment current line or selection
  * `gc`_m_ comment for motion or `gcc` for current line
  * `gb`_m_ comment blockwise for motion (or visual selection)
* `,lD` goto implementation
* `,ld` goto definition
* `,le` show line errors
* `,lf` fixit code actions menu
* `,li` info hover
* `,ll` toggle virtual text lines
* `,lr` show references
* `,lsd` find symbols in document
* `,lsw` find symbols in workspace
* `,lt` show signature

* When available
  * `,lR` rename symbol
  * `,l=` format current line or selection
  * `,lI` telescope implementations

* For rust
  * `,rr` run menu of options (tests, etc)
  * `,re` expand macro
  * `,rh` hover actions
  * `,ra` rust code actions

* Indentation
  * `,i1` use tab for indent
  * `,i2` use two spaces for indent
  * `,i4` use four spaces for indent
  * `,ir` retab to current setting

## Git
* `,gs` browse git status and jump to selected file
* `,gb` browse git branches and switch to selected
* `,gc` browse git commits
* `,g-` reset (unstage) current hunk
* `,g+` stage current hunk
* `,gu` undo stage hunk
* `,gS` stage buffer
* `,gR` reset buffer
* `,gp` preview hunk
* `,gB` blame hunk popup
* `,gd` diff this to index
* `,gD` diff this to previous

* Worktrees
  * `,gws` switch worktree
  * `,gwn` new worktree

* Toggles
  * `,gtb` toggle current line blame
  * `,gtd` toggle show deleted

  Motion
  * _action_`ih` select the current git hunk

* `]c`, `[c` next/prev change
* `]n`, `[n` next/prev conflict

* Fugitive
  * `:G`, `:GStatus`
    * Use `ctrl + n` / `ctrl + p` to jump between files
    * Press `-` on a file to toggle whether it is added (`git add` or `git reset` depending)
    * Press `p` on a file to walk through hunks of changes and selectively add parts of a file
    * Press `<enter>` to view it and then `:Gdiff` to see changes
    * Press `cc` to commit
    * Press `ca` to amend last commit
    * `gq` to close status buffer
    * `=` toggle inline diff of file under cursor (preferred)
      * Or `dp` to invoke git diff on the file under the cursor
  * `:Gdiff`
    * index on left (git added or last committed), working copy on right
    * `:diffget` will pull changes from opposite window in allowing to undo changes
    * Press `s` to stage a hunk
    * Press `u` to unstage a hunk
    * Press `-` to toggle staging of hunk
    * Use `]c` and `[c` to jump between hunks
  * `:Gcommit`
  * `:GBrowse` to launch current file in github in browser
    * "In commit messages, GitHub issues, issue URLs, and collaborators can be omni-completed (`<C-X><C-O>`, see :help compl-omni). This makes inserting those `Closes #123` remarks slightly easier than copying and pasting from the browser.
  * `:Gedit :0`
    * Open index version of current file in a tmp buffer. index file is the git added version.
  * `:Gedit`
    * Explore git objects to navigate commits and old versions of the tree without changing anything
    * Can hit enter on parent (prev commit) or tree (state of all files at this point) and then select other files
    * Get into this better with `:Gclog`
    * When looking at a commit, hit enter on a diff line to see how things changed
    * Capital `C` will jump you from a tmp file or whatever up to related commit
  * `:Git mergetool` load current conflicts into quickfix list (TODO: try `ri` on the git status screen to initiate rebase)
    * Navigate through the conflicted files (use the unimpaired `[q` and `]q`)
    * Launch the 3-way merge tool with `:Gvdiffsplit!` (the `!` is for 3-way and `v` for vertical split)
      * Now put cursor in the middle window. 
      * Left pane, "2", is local, right pane is remote, "3". For rebase though, left seems to be master and right the local branch.
      * Use `d2o` or `d3o` to pull changes from left or right for current chunk.
      * Navigate between chunks with `]c` and `[c`
      * When a file is good, use `:Gw` and move on
      * When finished you get to the end of the quickfix list, use `:G` to check status then `cc` to commit.
      * After commit, use `rr` in the status screen or `:G rebase --contine` and hope you don't get a fresh set of conflicts, but if you do, repeat from the top.

## Notes
* `,ng` spawn grammar checker
* `,nn` use zk to add new note under $ZK_NOTEBOOK_DIR (prompt for dir)
* `,no` use zk to open note by heading or filename
* `,nt` use zk to find notes by tag
* `,nf` use zk to find notes
* `,nm` use zk to make new meeting note in $ZK_NOTEBOOK_DIR/meetings
* `,nd` use zk to make new diary note in $ZK_NOTEBOOK_DIR/daily
* `,nh` open hotsheet note
* `gt` turn url under cursor into titled link
* in open markdown note only
  * `,np` new peer note in same folder as this one
  * `,nl` show outbound links
  * `,nr` show reference (inbound) links
  * `,ni` show info preview
  * `K` over link to preview linked note

## Plugin: Telescope
Fuzzy finder via Telescope

* `,ff` fuzzy search files
* `,fg` fuzzy grep files (live)
* `,fb` fuzzy find buffer
* `,fh` fuzzy search history of open files
* `,fq` fuzzy browse quickfix
* `,fl` fuzzy browse location list
* `,fz` fuzzy browse zoxide
* `,fp` fuzzy browse projects
* `,fk` fuzzy browse keymaps
* `,fd` fuzzy browse document symbols
* Inside the popup window:
	* `ctrl + p` on selection to paste selection at cursor
	* `ctrl + y` on selection to copy selection
	* `ctrl + o` on selection call `open` on it
	* ctrl + q to put results in quick fix list
	* `ctrl + e` create new file in current dir or creates dir if name contains trailing slash or subdirs like `dir/subdir/file`

### Plugin: Unimpaired
* `[a`, `]a` prev/next file if multiple specified on cli
* `[A`, `]A` first/last file if multiple specified on cli
* `[b`, `]b` prev/next buffer
* `[B`, `]B` first/last buffer
* `[l`, `]l` prev/next location list
* `[L`, `]L` first/last location list
* `[q`, `]q` prev/next quickfix errors list
* `[Q`, `]Q` first/last quickfix errors list
* `[o`, `]o` prev/next file in dir by alpha
* `[n`, `]n` prev/next git conflict
* `[<space>`, `]<space>` add line above/below
* `[e`, `]e` exchange line with above/below
* `[x`_m_ xml encode (&lt;) movement _m_ or _VISUAL_
* `]x`_m_ xml decode (&lt;) movement _m_ or _VISUAL_
* `[u`_m_ url encode (%20) movement _m_ or _VISUAL_
* `]u`_m_ url decode (%20) movement _m_ or _VISUAL_
* `[y`_m_ c encode (\") movement _m_ or _VISUAL_
* `]y`_m_ c decode (\") movement _m_ or _VISUAL_
* Pasting
	* `>p`    Paste after linewise, increasing indent.
	* `>P`    Paste before linewise, increasing indent.
	* `<p*    Paste after linewise, decreasing indent.
	* `<P`    Paste before linewise, decreasing indent.
	* `=p`    Paste after linewise, reindenting.
	* `=P`    Paste before linewise, reindenting.
	* `]p`, `[p`, `[P`, and `]P` have also been remapped to force linewise pasting,
	* `pkJ` or `vp` will take a yanked line with newlines and put it in the current line while preserving their usual indent matching behavior. So will insert mode `ctrl-r "`

### Plugin: Grammarous
* `,ng` will kick off the grammar checker
* `]g` and `[g` to navigate grammar issues
* `,gf` to auto fix an issue
* `,gx` to ignore an issue

### Plugin: DiffView
* `:DiffviewOpen`
* `[x` and `]x` to navigate conflicts
* `,co` choose ours
* `,ct` choose theirs
* `,cb` choose base
* `,ca` choose all
* `dx` delete entire conflict region
* `,b` toggle list of files
* `<tab>` and `<shift>-<tab>` next/prev file with conflicts
