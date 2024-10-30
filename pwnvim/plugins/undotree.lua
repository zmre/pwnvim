require("undotree").setup({
  -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
  -- Set to false if you still want to use netrw.
  default_file_explorer = true,
  dependencies = "nvim-lua/plenary.nvim",
  skip_confirm_for_simple_edits = true,
  keymaps = {
    ["u"] = "<cmd>lua require('undotree').toggle()<cr>"
  }
})
