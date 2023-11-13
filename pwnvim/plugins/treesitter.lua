require("nvim-treesitter.configs").setup({
  sync_install = false,
  modules = {},
  disable = {},
  ensure_installed = {},
  ignore_install = { "all" },
  auto_install = false,
  autotag = { enable = true },
  highlight = {
    enable = true,
    disable = {},

    additional_vim_regex_highlighting = false
  },
  indent = { enable = true, disable = { "yaml", "markdown", "dbout" } },
  incremental_selection = {
    enable = true,
    disable = {},
    is_supported = function()
      -- disable in command window
      local mode = vim.api.nvim_get_mode().mode
      return mode ~= "c"
    end
  },
  context_commentstring = {
    enable = true,
    disable = { "dbout" },
  },
  matchup = {
    enable = true,
    disable = { "dbout" },
    include_match_words = true
  },
  textobjects = {
    disable = {},
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = { query = "@function.outer", desc = "Select outer function" },
        ["if"] = { query = "@function.inner", desc = "Select inner function" },
        ["ac"] = { query = "@class.outer", desc = "Select outer class" },
        ["ic"] = { query = "@class.inner", desc = "Select inner class" },
        ["im"] = { query = "@block.inner", desc = "Select inner block" },
        ["am"] = { query = "@block.outer", desc = "Select outer block" }
        -- ["il"] = { query = "@list.inner", desc = "Select inner list" },
        -- ["al"] = { query = "@list.outer", desc = "Select outer list" },
        -- ["ih"] = { query = "@section.inner", desc = "Select inner section" },
        -- ["ah"] = { query = "@section.outer", desc = "Select outer section" },
      }
    },
    move = {
      enable = true,
      set_jumps = true, -- khether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = { query = "@class.outer", desc = "Next class start" }
      },
      goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer"
      },
      goto_previous_end = { ["[M"] = "@function.outer", ["[]"] = "@class.outer" }
    },
    lsp_interop = {
      enable = true,
      border = "none",
      floating_preview_opts = {},
      peek_definition_code = {
        ["<leader>df"] = "@function.outer",
        ["<leader>dF"] = "@class.outer"
      }
    }
  }
})
require("treesitter-context").setup({
  enable = true,
  trim_scope = "outer",
  zindex = 20,
  mode = "cursor",
  multiline_threshold = 2,
  min_window_height = 0,
  line_numbers = true,
  max_lines = 4, -- no max window height
  patterns = { markdown = { "atx_heading" } }
})
