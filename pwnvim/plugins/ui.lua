----------------------- UI --------------------------------
-- Oil file browser, GitSigns, Colorizer, lualine, treesitter

return function()
  require("pwnvim.plugins.oil")
  require("pwnvim.plugins.outline")

  local surround_defaults = require("nvim-surround.config").default_opts
  require("nvim-surround").setup({
    aliases = {
      ["e"] = "**", -- e for emphasis -- bold in markdown
      ["a"] = ">",
      ["b"] = ")",
      ["B"] = "}",
      ["r"] = "]",
      ["q"] = { '"', "'", "`" },
      ["s"] = { "}", "]", ")", ">", '"', "'", "`" },
    },
    --[[ keymaps = {
      insert = "<C-g>s",
      insert_line = "<C-g>S",
      normal = "ys",
      -- normal_cur = "yss",
      normal_line = "yS",
      -- normal_cur_line = "ySS",
      visual = "S",
      visual_line = "gS",
      delete = "ds",
      change = "cs",
      change_line = "cS",
    }, ]]
    surrounds = surround_defaults.surrounds,
    highlight = { duration = 1 },
    move_cursor = "begin",
    indent_lines = surround_defaults.indent_lines
  })
  -- Show which-key hints for surround targets (ys/ds/cs) using the labels and
  -- aliases above -- must run after nvim-surround setup
  require("nvim-surround-wk").setup()

  require("pwnvim.plugins.gitsigns")
  require("pwnvim.plugins.review").init() -- defines :Review / :ReviewSidekick
  vim.g.git_worktree = {
    change_directory_command = "lcd",
    update_on_change = true,
    update_on_change_command = "e .",
    confirm_telescope_deletions = true,
    clearjumps_on_change = true,
    autopush = false
  }


  if not SimpleUI then
    require("colorizer").setup({})
    require("dressing").setup({
      input = {
        enabled = true, -- Set to false to disable the vim.ui.input implementation
        default_prompt = "Input:",
        prefer_width = 50,
        relative = "win",
        insert_only = true,     -- When true, <Esc> will close the modal
        start_in_insert = true, -- ready for input immediately
      },
      select = {
        -- Set to false to disable - snacks handles vim.ui.select now
        enabled = false,
      }

    })
    require('marks').setup {
      -- whether to map keybinds or not. default true
      default_mappings = false,
      -- which builtin marks to show. default {}
      builtin_marks = { "<", ">", "^", ";", "'" },
      -- whether movements cycle back to the beginning/end of buffer. default true
      cyclic = true,
      -- whether the shada file is updated after modifying uppercase marks. default false
      force_write_shada = false,
      -- how often (in ms) to redraw signs/recompute mark positions.
      -- higher values will have better performance but may cause visual lag,
      -- while lower values may cause performance penalties. default 150.
      refresh_interval = 250,
      -- sign priorities for each type of mark - builtin marks, uppercase marks, lowercase
      -- marks, and bookmarks.
      -- can be either a table with all/none of the keys, or a single number, in which case
      -- the priority applies to all marks.
      -- default 10.
      sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
      -- disables mark tracking for specific filetypes. default {}
      excluded_filetypes = {},
      -- marks.nvim allows you to configure up to 10 bookmark groups, each with its own
      -- sign/virttext. Bookmarks can be used to group together positions and quickly move
      -- across multiple buffers. default sign is '!@#$%^&*()' (from 0 to 9), and
      -- default virt_text is "".
      -- bookmark_0 = {
      -- sign = "⚑",
      -- virt_text = "hello world",
      -- explicitly prompt for a virtual line annotation when setting a bookmark from this group.
      -- defaults to false.
      -- annotate = false,
      -- },
      mappings = {
        -- delete_line = "dm-",
        -- delete = "dm",
        preview = "m:",
        next = "]'",
        prev = "['"
      }
    }
  end

  require("pwnvim.plugins.lualine")
  require("pwnvim.plugins.treesitter")
  require("flash").setup({
    modes = {
      char = {
        enabled = false, -- actually slowing me down :(
        jump_labels = true,
        autohide = true,
        keys = { "f", "F", "t", "T", ";" }, -- needed to remove "," as that is our mapleader
        highlight = { backdrop = false },
        char_actions = function(motion)
          return {
            [";"] = "next", -- set to `right` to always go right
            -- [","] = "prev", -- set to `left` to always go left
            [motion:lower()] = "next",
            [motion:upper()] = "prev"
          }
        end
      }
    }
  })

  -- Replacement for barbecue provides breadcrumbs in top line
  -- catppuccin green #a6da95
  -- catppuccin red #ed8796
  -- catppuccin mauve #c6a0f6
  vim.api.nvim_set_hl(0, 'DropBarKindFile', { fg = '#c6a0f6', italic = false, bold = true })
  vim.api.nvim_set_hl(0, 'DropBarFileNameDirty', { fg = '#ed8796', italic = true, bold = true })
  require("dropbar").setup({
    bar = {
      -- below adds dropbar to oil windows
      enable = function(buf, win, _)
        if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win)
            or vim.fn.win_gettype(win) ~= ''
            or vim.wo[win].winbar ~= ''
            or vim.bo[buf].ft == 'help'
        then
          return false
        end

        local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
        if stat and stat.size > 1024 * 1024 then
          return false
        end

        return vim.bo[buf].ft == 'markdown'
            or vim.bo[buf].ft == 'oil'      -- enable in oil buffers
            or vim.bo[buf].ft == 'fugitive' -- enable in fugitive buffers
            or pcall(vim.treesitter.get_parser, buf)
            or not vim.tbl_isempty(vim.lsp.get_clients({
              bufnr = buf,
              method = 'textDocument/documentSymbol',
            }))
      end,
      truncate = false,
      update_debounce = 50,
      update_events = {
        buf = {
          'BufModifiedSet',
          'FileChangedShellPost',
          'TextChanged',
          --'ModeChanged', -- Don't know why modechanged is needed
        }
      },
    },

    sources = {
      path = {
        max_depth = 7,
        modified = function(sym)
          if sym ~= nil then
            return sym:merge({
              name = sym.name .. ' [+]',
              -- icon = ' ',
              icon = '',
              name_hl = 'DropBarFileNameDirty',
              icon_hl = 'DropBarFileNameDirty',
            })
          end
        end,
      }
    }
  })
end -- UI setup
