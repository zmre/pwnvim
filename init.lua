-- Neovide needs this defined very early
if vim.fn.has('mac') == 1 then
  vim.opt.guifont = "Hasklug Nerd Font:h18"
else
  vim.opt.guifont = "Hasklug Nerd Font:h9"
end
vim.g.loaded_matchit = 1 -- disable early
require('impatient')
require('impatient').enable_profile()
require('pwnvim.filetypes').config()
require('pwnvim.options').defaults()
if vim.g.neovide then
  require('pwnvim.options').colors_onedark()
else
  require('pwnvim.options').colors_cat()
end
require('pwnvim.options').gui()
require('pwnvim.mappings').config()
require('pwnvim.abbreviations')
require('pwnvim.plugins').ui()
require('pwnvim.plugins').diagnostics()
require('pwnvim.plugins').telescope()
require('pwnvim.plugins').completions()
require('pwnvim.plugins').llms()
require('pwnvim.plugins').notes()
require('pwnvim.plugins').misc()
