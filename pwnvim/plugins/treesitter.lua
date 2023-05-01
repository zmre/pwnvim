require 'nvim-treesitter.configs'.setup {
  auto_install = false,
  autotag = { enable = true },
  highlight = {
    enable = true,
    disable = { "bash", "c_sharp", "erlang", "gdscript", "java", "kotlin", "ruby", "scala", "sql" }, -- 2023-04-26 failing in :checkhealth nvim-treesitter
    additional_vim_regex_highlighting = false
  },
  indent = { enable = true, disable = { "yaml" } },
  incremental_selection = { enable = true },
  context_commentstring = {
    enable = true,
  },
  textobjects = {
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
        ["am"] = { query = "@block.outer", desc = "Select outer block" },
        -- ["il"] = { query = "@list.inner", desc = "Select inner list" },
        -- ["al"] = { query = "@list.outer", desc = "Select outer list" },
        -- ["ih"] = { query = "@section.inner", desc = "Select inner section" },
        -- ["ah"] = { query = "@section.outer", desc = "Select outer section" },
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = { query = "@class.outer", desc = "Next class start" },
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
    },
  }
}
require 'treesitter-context'.setup {
  max_lines = 0, -- no max window height
  patterns = {
    markdown = { "atx_heading" }
  },
}
