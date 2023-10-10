if not SimpleUI then
  require('ibl').setup({ -- indent-blankline
    enabled = true,
    indent = {
      --char = '┊',
      char = '▏',
    },
    exclude = {
      buftypes = { 'terminal', 'help', 'markdown', 'nofile', 'help', 'quickfix', 'prompt' },
      filetypes = { 'help', 'markdown', 'nofile', 'help', 'packer', 'Trouble',
        "startify", "dashboard", "neogitstatus", "lspinfo", "checkhealth", "man", "", "NvimTree", "dbout"
      },

    },
    scope = {
      enabled = false,
      char = '▍',
      show_start = false,
      show_end = false,
      highlight = "VertSplit",
    },
  })
end
