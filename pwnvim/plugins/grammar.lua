-- Grammar check via vim-grammarous; bound to ,ng and :StartGrammar2

return function()
  vim.cmd("packadd vim-grammarous")
  local opts = { noremap = false, silent = true }
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(0, ...) end

  buf_set_keymap("n", "<leader>gf", "<Plug>(grammarous-fixit)", opts)
  buf_set_keymap("n", "<leader>gx", "<Plug>(grammarous-remove-error)", opts)
  buf_set_keymap("n", "]g", "<Plug>(grammarous-move-to-next-error)", opts)
  buf_set_keymap("n", "[g", "<Plug>(grammarous-move-to-previous-error)", opts)
  vim.cmd("GrammarousCheck")
end
