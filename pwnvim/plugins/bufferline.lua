require 'bufferline'.setup {
  options = {
    numbers = "none",                    -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
    close_command = "Bdelete! %d",       -- can be a string | function, see "Mouse actions"
    right_mouse_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
    left_mouse_command = "buffer %d",    -- can be a string | function, see "Mouse actions"
    middle_mouse_command = nil,          -- can be a string | function, see "Mouse actions"
    indicator = {
      style = "icon",
      icon = "▎",
    },
    -- buffer_close_icon = '',
    modified_icon = "●",
    close_icon = SimpleUI and "x" or "",
    -- close_icon = '',
    -- hover doesn't work in tmux
    -- hover = {
    --   enabled = true,
    --   delay = 200,
    --   reveal = { 'close' }
    -- },
    left_trunc_marker = SimpleUI and "⬅️" or "",
    right_trunc_marker = SimpleUI and "➡️" or "",
    max_name_length = 40,
    max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
    tab_size = 20,
    -- name_formatter = function(buf) -- buf contains a "name", "path" and "bufnr"
    --   -- remove extension from markdown files for example
    --   if buf.name:match('%.md') then
    --     return vim.fn.fnamemodify(buf.name, ':t:r')
    --   end
    -- end,
    diagnostics = false, -- | "nvim_lsp" | "coc",
    diagnostics_update_in_insert = false,
    offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
    show_buffer_close_icons = true,
    show_close_icon = true,
    show_buffer_icons = not SimpleUI,
    get_element_icon = function(elem)
      if SimpleUI then
        return "", ""
      else
        local icon, hl = require('nvim-web-devicons').get_icon_by_filetype(elem.filetype, { default = false })
        return icon, hl
      end
    end,
    color_icons = not SimpleUI,
    buffer_close_icon = SimpleUI and "x" or "",
    show_tab_indicators = true,
    persist_buffer_sort = false, -- whether or not custom sorted buffers should persist
    -- can also be a table containing 2 custom separators
    -- [focused and unfocused]. eg: { '|', '|' }
    separator_style = "thick",    -- | "thick" | "thin" | { 'any', 'any' },
    enforce_regular_tabs = false, -- if true, all tabs same width
    always_show_bufferline = true
  },
  highlights = {
    indicator_selected = {
      fg = {
        attribute = "fg",
        highlight = "LspDiagnosticsDefaultHint"
      },
      bg = { attribute = "bg", highlight = "Normal" }
    }
  }
}
