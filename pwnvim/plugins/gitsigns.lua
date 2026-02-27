require("gitsigns").setup {
  signs = {
    add = {
      -- hl = 'GitSignsAdd',
      text = '✚',
      -- numhl = 'GitSignsAddNr',
      -- linehl = 'GitSignsAddLn'
    },
    change = {
      -- hl = 'GitSignsChange',
      text = '│',
      -- numhl = 'GitSignsChangeNr',
      -- linehl = 'GitSignsChangeLn'
    },
    delete = {
      -- hl = 'GitSignsDelete',
      text = '_',
      -- numhl = 'GitSignsDeleteNr',
      -- linehl = 'GitSignsDeleteLn'
    },
    topdelete = {
      -- hl = 'GitSignsDelete',
      text = '‾',
      -- numhl = 'GitSignsDeleteNr',
      -- linehl = 'GitSignsDeleteLn'
    },
    changedelete = {
      -- hl = 'GitSignsChange',
      text = '~',
      -- numhl = 'GitSignsChangeNr',
      -- linehl = 'GitSignsChangeLn'
    }
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local mapnlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapn)
    local mapoxlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapox)
    local mapleadernvlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleadernv)
    local mapleadernlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleadern)
    local mapleadervlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleaderv)

    -- Navigation
    mapnlocal(']c', function()
      -- if we're in a diff view, use built-in behavior
      if vim.wo.diff then return ']c' end
      -- otherwise use git signs to go to the next hunk
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, "Next hunk", { expr = true })
    mapnlocal('[c', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, "Prev hunk", { expr = true })

    -- DO NOT USE gs, gb, gc, gw as these are more global and not gitsigns specific
    -- Git toggles
    mapleadernvlocal("gtb", gs.toggle_current_line_blame, "Toggle current line blame")
    mapleadernvlocal("gtd", gs.toggle_deleted, "Toggle deleted")
    -- Actions -- normal mode
    mapleadernlocal("g-", gs.reset_hunk, "Reset hunk")
    mapleadernlocal("g+", gs.stage_hunk, "Stage hunk")
    mapleadervlocal("g-", function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Reset hunk")
    mapleadervlocal("g+", function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Stage hunk")
    mapleadernvlocal("gu", gs.undo_stage_hunk, "Undo stage hunk")
    mapleadernvlocal("gS", gs.stage_buffer, "Stage buffer")
    mapleadernvlocal("gR", gs.reset_buffer, "Reset buffer")
    mapleadernlocal("gp", gs.preview_hunk, "Preview hunk")
    mapleadernvlocal("gB", function() gs.blame_line { full = true } end, "Blame hunk popup")
    mapleadernlocal("gd", gs.diffthis, "Diff this to index")
    mapleadernlocal("gD", function() gs.diffthis('~') end, "Diff this to previous")
    -- text object for hunks
    mapoxlocal("ih", ':<C-U>Gitsigns select_hunk<CR>', "Select git hunk")
  end
}
