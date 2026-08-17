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
  * `,lI` find implementations

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
* `,gm` browse git commits (log)
* `,gB` open current file/line in browser (gitbrowse)
* `,gi` browse GitHub issues
* `,gP` browse GitHub PRs
* `,g-` reset (unstage) current hunk
* `,g+` stage current hunk
* `,gu` undo stage hunk
* `,gS` stage buffer
* `,gR` reset buffer
* `,gp` preview hunk
* `,gB` blame hunk popup
* `,gd` diff this to index
* `,gD` diff this to previous

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

## Fuzzy Finder (snacks.picker)

* `,ff` fuzzy search files
* `,fg` fuzzy grep files (live)
* `,fb` fuzzy find buffer
* `,fh` fuzzy search history of open files (local)
* `,fo` fuzzy search old file history (global)
* `,fq` fuzzy browse quickfix
* `,fl` fuzzy browse location list
* `,fz` fuzzy browse folders
* `,fp` fuzzy browse projects
* `,fk` fuzzy browse keymaps
* `,fd` fuzzy browse document symbols
* `,ft` fuzzy find todos in markdown files
* `ctrl + p` open file picker

## Terminal (snacks.terminal)

* `Ctrl-\` toggle terminal (vertical)
* `Ctrl-'` toggle terminal (horizontal)

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

### Review (code review with inline comments)

Replaces diffview. `,crr` opens codediff side-by-side over your changes and
turns that tab into a review; `,cr*` adds typed comments. Every comment shows
up **twice**: as a sign in the gutter and as virtual text at the end of the
line (`⚠ ISSUE: don't swallow this error`). Copy the review as Markdown with
`,crm`, or hand it to an AI CLI with `,crS`.

The comments are ours, not a plugin's: a list of
`{ file, lnum, end_lnum, type, text }` in `pwnvim/plugins/review.lua`, saved as
JSON per branch. The quickfix list is a *rendered view* of that list, so a
`:grep` can no longer throw a review away — `,crl` just rebuilds it.

You comment on the **right-hand pane**, which is the real working-tree file, so
LSP is fully live there: `,ld` into a file that isn't part of the diff works,
and `<C-o>` brings you back. While that buffer is open, comments follow the
edits made around them — including edits *inside* a range, which grows it.

The left pane is the file at the git revision (a `codediff://` buffer). Its line
numbers are that revision's, not the file's, so it carries no signs and its
`,cr*` keys tell you to switch panes rather than file a comment against the
wrong line. codediff also keeps LSP off it, so navigate from the right.

#### Opening a review
* `,crr` or `:Review` — review working-tree changes vs HEAD
* `:Review file HEAD~3` — any `:CodeDiff` arguments are forwarded
* `:CodeDiff` on its own still works and does *not* enable review comments

#### Adding comments (`,cr*`, buffer-local inside the review tab)
Review has its own room in the `,c` family, next to `,ca` agentic, `,cc`
codecompanion and `,cs` sidekick. Press `,cr` and wait for which-key.
* `,crc` add comment — prompts for the type
* `,cri` add Issue ⚠
* `,crs` add Suggestion 💭
* `,crn` add Note 📝
* `,crp` add Praise ✨
* `,crq` add Question ?
* `,crk` add Insight 💡
* `,crf` add file-level comment (a Note 📝, anchored at line 1)
* `,crd` delete comment on the line / selection
* `,cre` edit comment on the line
* `,crv` view the comment(s) on this line in full
* `]r` / `[r` next / previous comment in this file

The six typed bindings are listed in the order `,crc` offers them. They and
`,crc` and `,crd` work from visual mode too and record the line range; `,crf` is
normal-mode only, since it always means line 1.

Comment text is typed in a small floating window, so it can be **as long as you
like and span multiple lines**:
* `<C-s>` (normal or insert) or `<CR>` in normal mode — save
* `q` in normal mode, `<C-c>`, or just closing the window — cancel
* saving an empty buffer adds nothing, and on an edit leaves the comment as it
  was — deleting is `,crd`, so a stray `<C-s>` can't blank a comment

#### Seeing and exporting
These four are global — comments outlive the review tab.
* `,crr` start a review
* `,crl` list every comment in **Trouble**; `q` closes it
* `,crm` copy the whole review to the clipboard as Markdown
* `,crS` send the review to the sidekick AI CLI
* `:ReviewList` / `:ReviewMarkdown` / `:ReviewSidekick` — same three
* `:ReviewRefresh` re-read the current branch's comments, redraw signs and virtual text
* `:ReviewClear` delete every comment on this branch

The Trouble list opens on its own (without stealing the cursor) as soon as
there is something to show — when you add a comment, and when you reopen a
review that already has some.

Comments are saved automatically, per branch, in
`<repo>/.git/pwnvim-review/<branch>.json`, and come back the next time you open
a review on that branch. There is no save/load step. Living inside `.git/` makes
them local by construction — git never tracks its own directory, so there is
nothing to gitignore, nothing in `git status`, and no way to commit them by
accident. Linked worktrees get their own; if `.git` isn't writable, or you're
outside a repo entirely, it falls back to `~/.local/share/nvim/review/`.

A branch whose name isn't filename-safe gets a digest so it can't collide with a
lookalike: `main` → `main.json`, but `feat/login` → `feat-login-<hash>.json`,
which is a different file from branch `feat-login`.

Switching branches in another terminal doesn't repaint the signs on its own —
any review command (or `:ReviewRefresh`) picks up the new branch.

#### Tuning
* `vim.g.pwnvim_review_autolist = false` — don't open the comment list
  automatically (it opens by default)
* `vim.g.pwnvim_review_virt_text = false` — signs only, no virtual text
* `vim.g.pwnvim_review_virt_width = 60` — truncate virtual text at N columns
* `vim.g.pwnvim_review_signcolumn = "yes:3"` (or `false` to leave it alone) —
  review panes widen to `yes:2` so a review sign and a git hunk sign both fit
* `vim.g.pwnvim_review_sign_priority = 100` — review signs sit above gitsigns
  (6) and marks (8); lower it to let those win the gutter instead

### Plugin: Sidekick (AI agent CLI launcher)

Launches AI command-line tools (iris, claude, codex, gemini) in a right-split
terminal and pipes buffer/selection/diagnostics into them. NES (Next Edit
Suggestion) is disabled — Copilot is not required. Iris is the primary tool
(a wrapper around `claude`).

* `,csi` toggle **Iris** (primary AI CLI)
* `,css` pick a tool from the list
* `,csl` toggle Claude
* `,csg` toggle Gemini
* `,csx` toggle Codex
* `,csa` toggle whichever CLI was last used
  * `ctrl-alt-\` will also toggle the last used
* `,csq` close/detach current CLI session
* `,csf` focus the CLI window
* `,cst` send current line (normal) or selection (visual) to CLI
* `,csb` send entire buffer to CLI
* `,csv` send visual selection to CLI
* `,csp` open saved-prompt picker
* `,csd` send LSP diagnostics to CLI

Inside the CLI terminal: `q` hide, `<C-z>` blur, `<C-p>` insert prompt,
`<C-b>` buffer picker, `<C-f>` file picker, `<C-h/j/k/l>` window navigation.

### Plugin: Agentic (ACP AI chat sidebar)

A structured in-editor agent chat that talks the Agent Client Protocol (ACP),
as opposed to Sidekick's raw terminal CLIs. Providers and their connector CLIs
(all supplied by the flake): **Claude** (`claude-agent-acp`), **Codex**
(`codex-acp`), **Gemini** (`gemini --acp`), **OpenCode** (`opencode acp`).
Claude is the default provider and is routed through the `iris` PAI wrapper
(via `CLAUDE_CODE_EXECUTABLE`) so its settings, MCP config, plugins, and
private-mode routing all apply. Switch providers mid-session with `,cap`.

* `,cat` toggle the chat sidebar
* `,cao` open the chat sidebar (stay open if already visible)
* `,caq` close the chat sidebar
* `,can` new session
* `,car` restore a previous session from the provider
* `,cap` switch ACP provider (claude/codex/gemini/opencode)
* `,caf` add current file to context
* `,cav` add visual selection to context
* `,cax` stop the current generation
* `,caL` rotate window layout

Inside the chat widget: `<CR>` or `<C-s>` submit, `<S-Tab>` switch agent mode,
`<localLeader>s` switch provider, `<localLeader>m` switch model,
`<localLeader>p` paste image, `q` close.
