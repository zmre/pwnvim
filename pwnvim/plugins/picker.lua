----------------------- SNACKS PICKER --------------------------------
-- snacks.nvim setup: picker plus bigfile, quickfile, bufdelete, indent,
-- image, dashboard, terminal, zen, gitbrowse, gh

-- Detect if neovim was launched by page pager (I60R/page)
-- Checks if any argv contains /tmp/neovim-page/ pattern
local is_page_pager = (function()
  return vim.b.page_alternate_bufnr ~= nil
end)()

return function()
  local trouble_actions = require("trouble.sources.snacks").actions

  -- Custom actions for snacks picker
  local function quicklook_action(picker)
    local item = picker:current()
    if item and item.file then
      vim.cmd("silent !qlmanage -p '" .. item.file .. "'")
    end
  end

  local function yank_action(picker)
    local item = picker:current()
    if item then
      local value = item.file or item.text or ""
      vim.fn.setreg('"', value)
      vim.fn.setreg('*', value)
      picker:close()
    end
  end

  local function system_open_action(picker)
    local item = picker:current()
    if item and item.file then
      os.execute("open '" .. item.file .. "'")
      picker:close()
    end
  end
  require("snacks").setup({
    -- Performance features
    bigfile = { enabled = true },   -- disables LSP, treesitter, etc for big files
    quickfile = { enabled = true }, -- render file before plugins load

    -- Buffer/window management
    bufdelete = { enabled = true }, -- delete buffers without messing layout

    -- UI features
    indent = {
      enabled = not SimpleUI,
      char = "▏",
      scope = { enabled = false },
      exclude = {
        buftypes = { "terminal", "help", "nofile", "quickfix", "prompt" },
        filetypes = { "help", "markdown", "nofile", "packer", "Trouble", "dashboard", "NvimTree" },
      },
    },
    image = {
      enabled = not SimpleUI,
      doc = {
        enabled = true,
        inline = false, -- disable inline rendering
        float = true,   -- show images in floating window instead
        max_width = 80,
        max_height = 40,
      },
      convert = {
        notify = false,
        mermaid = function()
          -- local theme = vim.o.background == "light" and "neutral" or "dark"
          -- we're using https://github.com/1jehuang/mermaid-rs-renderer
          -- which doesn't yet support options like theme and scale
          return { "-i", "{src}", "-o", "{file}", "-e", "png" } -- , "-t", theme, "-s", "{scale}" }
        end,
      },
      math = {
        enabled = true,
      },
    },
    dashboard = {
      -- disable in SimpleUI, nested neovim ($NVIM set), page pager, or no tty input
      --enabled = not SimpleUI and not vim.env.NVIM and not is_page_pager and vim.fn.has('ttyin') == 1,
      enabled = false, -- i like it, but no matter what i do it messes up "page"
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.smart()" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
          { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
          { icon = "󰒲 ", key = "z", desc = "Notes", action = ":lua require('zk.commands').get('ZkNotes')({ sort = { 'modified' } })" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        header = [[
 ██████╗ ██╗    ██╗███╗   ██╗██╗   ██╗██╗███╗   ███╗
 ██╔══██╗██║    ██║████╗  ██║██║   ██║██║████╗ ████║
 ██████╔╝██║ █╗ ██║██╔██╗ ██║██║   ██║██║██╔████╔██║
 ██╔═══╝ ██║███╗██║██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║     ╚███╔███╔╝██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝      ╚══╝╚══╝ ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝]],
      },
      sections = {
        { section = "header" },
        { section = "keys",         gap = 1,    padding = 1 },
        { section = "recent_files", cwd = true, limit = 8,  padding = 1 },
      },
    },
    scroll = {
      enabled = false,
      animate = {
        duration = { step = 15, total = 150 },
        easing = "linear",
      },
    },
    terminal = {
      enabled = true,
      win = { style = "terminal" },
    },
    zen = {
      enabled = true,
      toggles = { dim = false, git_signs = true, diagnostics = false },
      on_open = function()
        vim.opt.scrolloff = 999 -- keep cursor in vertical middle
        vim.g.oldfoldcolumn = vim.wo.foldcolumn
        vim.wo.foldcolumn = "0"
      end,
      on_close = function()
        vim.opt.scrolloff = 8
        vim.wo.foldcolumn = vim.g.oldfoldcolumn or "auto:5"
      end,
      zoom = {
        toggles = { dim = false, git_signs = true },
        win = { width = 0.85 },
      },
    },
    gitbrowse = { enabled = true },
    gh = { enabled = true },
    notifier = { enabled = false },

    -- Picker
    picker = {
      prompt = SimpleUI and "> " or " ",
      ui_select = true, -- replace vim.ui.select with snacks picker
      layout = {
        cycle = true,
        preset = function()
          return vim.o.columns >= 120 and "default" or "vertical"
        end,
      },
      matcher = {
        fuzzy = true,
        smartcase = true,
        sort_empty = true, -- sort even before searching
        filename_bonus = true,
        history_bonus = true,
        cwd_bonus = false,
      },
      sort = {
        fields = { "score:desc", "text", "#text", "idx" },
      },
      formatters = {
        file = {
          filename_first = true, -- show filename before path like telescope did
          truncate = 80,
        },
      },
      sources = {
        files = {
          hidden = true,
          ignored = false,
          exclude = { "*.bak", ".git/", "node_modules", ".zk/", "Caches/", "Backups/" },
        },
        grep = {
          hidden = true,
          ignored = false,
          exclude = { "*.bak", ".git/", "node_modules", ".zk/", "Caches/", "Backups/" },
        },
        projects = {
          dev = { "~/src", "~/Documents", "~/Notes" },
          patterns = { ".git", ".mbr", "flake.nix", "Cargo.toml", "package.json", ".project" },
        },
      },
      win = {
        input = {
          keys = {
            ["<c-t>"] = { "trouble_open", mode = { "n", "i" } },
            ["<C-y>"] = { "yank_path", mode = { "n", "i" } },
            ["<C-o>"] = { "system_open", mode = { "n", "i" } },
            ["<F10>"] = { "quicklook", mode = { "n", "i" } },
            ["<c-h>"] = { "toggle_help", mode = { "i" } },
          },
        },
        list = {
          keys = {
            ["<c-t>"] = "trouble_open",
            ["<C-y>"] = "yank_path",
            ["<C-o>"] = "system_open",
            ["<F10>"] = "quicklook",
            ["dd"] = "bufdelete",
            ["q"] = "close",
          },
        },
      },
      actions = vim.tbl_extend("force", trouble_actions, {
        quicklook = quicklook_action,
        yank_path = yank_action,
        system_open = system_open_action,
      }),
    },

    -- Style overrides
    styles = {
      snacks_image = {
        relative = "editor", -- position relative to editor, not cursor
        row = 3,             -- near top of screen
        -- col not set = horizontally centered
        border = "rounded",
      },
    },
  })
end -- picker
