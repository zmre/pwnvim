require("gitsigns").setup {
  signs = {
    add = {
      hl = 'GitSignsAdd',
      text = '✚',
      numhl = 'GitSignsAddNr',
      linehl = 'GitSignsAddLn'
    },
    change = {
      hl = 'GitSignsChange',
      text = '│',
      numhl = 'GitSignsChangeNr',
      linehl = 'GitSignsChangeLn'
    },
    delete = {
      hl = 'GitSignsDelete',
      text = '_',
      numhl = 'GitSignsDeleteNr',
      linehl = 'GitSignsDeleteLn'
    },
    topdelete = {
      hl = 'GitSignsDelete',
      text = '‾',
      numhl = 'GitSignsDeleteNr',
      linehl = 'GitSignsDeleteLn'
    },
    changedelete = {
      hl = 'GitSignsChange',
      text = '~',
      numhl = 'GitSignsChangeNr',
      linehl = 'GitSignsChangeLn'
    }
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then return ']c' end
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, { expr = true })

    map('n', '[c', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, { expr = true })

    -- Actions -- normal mode
    require("which-key").register(
      {
        ["ih"] = { ':<C-U>Gitsigns select_hunk<CR>', "Select git hunk" },
        ["<leader>"] = {
          h = {
            name = "hunk (git)",
            s = { ':Gitsigns stage_hunk<CR>', "Stage hunk" },
            r = { ':Gitsigns reset_hunk<CR>', "Reset hunk" },
            S = { gs.stage_buffer, "Stage buffer" },
            u = { gs.undo_stage_hunk, "Undo stage hunk" },
            R = { gs.reset_buffer, "Reset buffer" },
            p = { gs.preview_hunk, "Preview hunk" },
            b = { function() gs.blame_line { full = true } end, "Blame hunk" },
            d = { gs.diffthis, "Diff this to index" },
            D = { function() gs.diffthis('~') end, "Diff this to previous" },
          },
          t = {
            name = "git toggles",
            b = { gs.toggle_current_line_blame, "Toggle current line blame" },
            d = { gs.toggle_deleted, "Toggle deleted" },
          }
        }
      }, { mode = "n", buffer = bufnr, silent = true, norewrap = true }
    )
    -- Actions -- visual and select mode
    require("which-key").register(
      {
        ["ih"] = { ':<C-U>Gitsigns select_hunk<CR>', "Select git hunk" },
        ["<leader>"] = {
          h = {
            name = "hunk (git)",
            s = { ':Gitsigns stage_hunk<CR>', "Stage hunk" },
            r = { ':Gitsigns reset_hunk<CR>', "Reset hunk" },
          }
        }
      }, { mode = "v", buffer = bufnr, silent = true, norewrap = true }
    )
    -- Actions -- operator pending mode
    require("which-key").register(
      {
        ["ih"] = { ':<C-U>Gitsigns select_hunk<CR>', "Select git hunk" }
      }, { mode = "o", buffer = bufnr, silent = true, norewrap = true }
    )
  end
}
