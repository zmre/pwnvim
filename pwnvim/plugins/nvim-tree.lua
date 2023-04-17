local signs = require("pwnvim.signs")
require 'nvim-tree'.setup {
  renderer = {
    icons = {
      webdev_colors = true,
      git_placement = "before",
      padding = " ",
      symlink_arrow = " ➛ ",
      show = {
        file = not SimpleUI,
        folder = true,
        folder_arrow = true,
        git = true
      },
      glyphs = {
        default = SimpleUI and "🖹" or "",
        symlink = SimpleUI and "🔗" or "",
        git = {
          unstaged = SimpleUI and "•" or "",
          staged = "✓",
          unmerged = SimpleUI and "⚡︎" or "",
          renamed = "➜",
          deleted = SimpleUI and "⌦" or "",
          untracked = "U",
          ignored = "◌"
        },
        folder = {
          default = SimpleUI and "📁" or "",
          open = SimpleUI and "📂" or "",
          empty = SimpleUI and "🗀" or "",
          empty_open = SimpleUI and "🗁" or "",
          symlink = SimpleUI and "🔗" or ""
        }
      }
    }
  },
  -- disables netrw completely
  disable_netrw = true,
  -- hijack netrw window on startup
  hijack_netrw = true,
  update_cwd = true,
  -- update_to_buf_dir = { enable = true, auto_open = true },
  update_focused_file = { enable = true, update_cwd = true },
  -- show lsp diagnostics in the signcolumn
  diagnostics = {
    enable = true,
    icons = { hint = signs.hint, info = signs.info, warning = signs.warn, error = signs.error }
  },
  git = {
    enable = true,
    timeout = 400 -- (in ms)
  },
  view = {
    width = 30,
    -- height = 30,
    hide_root_folder = false,
    side = "left",
    -- auto_resize = true,
    mappings = {
      custom_only = false,
      list = {
        { key = { "l", "<CR>", "o" }, action = "edit" },
        { key = "h",                  action = "close_node" },
        {
          key = "<F10>",
          action = "quicklook",
          action_cb = function(node) vim.cmd("silent !qlmanage -p '" .. node.absolute_path .. "'") end
        },
        { key = "v", action = "vsplit" }
      }
    },
    number = false,
    relativenumber = false
  }
}
