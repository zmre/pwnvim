----------------------- COMPLETIONS --------------------------------
-- blink.cmp completion engine

return function()
  require("blink.cmp").setup({
    keymap = {
      preset = 'super-tab',
      --['<CR>'] = { 'accept', 'fallback' }, -- i have muscle memory for accepting with enter, but on second thought, that sometimes annoys
    },
    cmdline = { enabled = true },
    appearance = {
      nerd_font_variant = 'mono'
    },
    completion = { documentation = { auto_show = true } },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' }
    },
  })
end -- completions
