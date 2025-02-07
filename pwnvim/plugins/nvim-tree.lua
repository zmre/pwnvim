require("oil").setup({
  -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
  -- Set to false if you still want to use netrw.
  default_file_explorer = true,
  skip_confirm_for_simple_edits = true,
  keymaps = {
    ["q"] = "actions.close",
    ["gd"] = function()
      require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
    end,
    ["<leader>ff"] = {
      function()
        require("telescope.builtin").find_files({
          cwd = require("oil").get_current_dir()
        })
      end,
      mode = "n",
      nowait = true,
      desc = "Find files in the current directory"
    },
    ["<leader>fg"] = {
      function()
        require("telescope.builtin").live_grep({
          cwd = require("oil").get_current_dir()
        })
      end,
      mode = "n",
      nowait = true,
      desc = "Find files in the current directory"
    },
  },
  -- Id is automatically added at the beginning, and name at the end
  columns = {
    "icon",
    -- "permissions",
    -- "size",
    -- "mtime",
  },
  win_options = {
    wrap = false,
    signcolumn = "no",
    cursorcolumn = false,
    foldcolumn = "0",
    spell = false,
    list = false,
    conceallevel = 3,
    concealcursor = "nvic",
  },
  lsp_file_methods = {
    -- Enable or disable LSP file operations
    enabled = true,
    -- Time to wait for LSP file operations to complete before skipping
    timeout_ms = 1000,
    -- Set to true to autosave buffers that are updated with LSP willRenameFiles
    -- Set to "unmodified" to only save unmodified buffers
    autosave_changes = false,
  },
  -- Can be "fast", true, or false. "fast" will turn it off for large directories.
  natural_order = true,
  -- Sort file and directory names case insensitive
  case_insensitive = true,
})
