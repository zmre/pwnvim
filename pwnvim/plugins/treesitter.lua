-- nvim-treesitter 1.0 configuration
-- The module framework has been removed - plugins now handle their own setup

local M = require("pwnvim.mappings")

-- nvim-treesitter core setup
-- Parsers are bundled via withAllGrammars in flake.nix
require("nvim-treesitter").setup({
  auto_install = false,                   -- Parsers are managed by Nix
  install_dir = treesitter_grammars_path, -- Fixes issues with preinstalled grammars
  indent = {
    enable = true,
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true,
  },
})

-- nvim-treesitter-textobjects (standalone setup)
require("nvim-treesitter-textobjects").setup({
  select = {
    lookahead = true,
  },
  move = {
    set_jumps = true,
  },
})

-- treesitter isn't getting started automatically anymore (2026-03-02) and I'm not sure why
-- but making an autocommand for all filetypes and then checking to see if it is a supported
-- one does the trick fine
vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function(ev)
    -- local ft = vim.bo[ev.buf].filetype -- this works, but below is more direct
    local ft = ev.match
    if vim.list_contains(require("nvim-treesitter").get_installed(), ft) then
      print("starting treesitter")
      if ft ~= "markdown" then
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      end
      vim.treesitter.start(ev.buf)
      -- vim.wo.foldmethod = "expr" -- zi toggles this
    else
      -- print("no treesitter for current filetype: " .. ft)
      -- vim.cmd('syn on')
      -- vim.wo.foldmethod = "syntax"
    end
  end,
})


-- Textobjects keymaps - select (visual + operator-pending)
local select = require("nvim-treesitter-textobjects.select").select_textobject
M.mapox("af", function() select("@function.outer", "textobjects") end, "Select outer function")
M.mapox("if", function() select("@function.inner", "textobjects") end, "Select inner function")
M.mapox("ac", function() select("@class.outer", "textobjects") end, "Select outer class")
M.mapox("ic", function() select("@class.inner", "textobjects") end, "Select inner class")
M.mapox("am", function() select("@block.outer", "textobjects") end, "Select outer block")
M.mapox("im", function() select("@block.inner", "textobjects") end, "Select inner block")

-- Textobjects keymaps - move (normal + visual + operator-pending)
local move = require("nvim-treesitter-textobjects.move")
M.map({ "n", "x", "o" }, "]m", function() move.goto_next_start("@function.outer", "textobjects") end,
  "Next function start")
M.map({ "n", "x", "o" }, "]M", function() move.goto_next_end("@function.outer", "textobjects") end, "Next function end")
M.map({ "n", "x", "o" }, "]]", function() move.goto_next_start("@class.outer", "textobjects") end, "Next class start")
M.map({ "n", "x", "o" }, "][", function() move.goto_next_end("@class.outer", "textobjects") end, "Next class end")
M.map({ "n", "x", "o" }, "[m", function() move.goto_previous_start("@function.outer", "textobjects") end,
  "Prev function start")
M.map({ "n", "x", "o" }, "[M", function() move.goto_previous_end("@function.outer", "textobjects") end,
  "Prev function end")
M.map({ "n", "x", "o" }, "[[", function() move.goto_previous_start("@class.outer", "textobjects") end, "Prev class start")
M.map({ "n", "x", "o" }, "[]", function() move.goto_previous_end("@class.outer", "textobjects") end, "Prev class end")

-- nvim-ts-autotag (standalone setup)
require("nvim-ts-autotag").setup({
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = false,
  },
})

-- vim-matchup treesitter integration
-- Note: vim-matchup vars are set in plugins.lua M.misc()
-- Treesitter integration is enabled automatically when the plugin detects
-- nvim-treesitter is available. No additional config needed in 1.0.
