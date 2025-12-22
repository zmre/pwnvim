-- This is a mega file. Rather than make each plugin have its own config file,
-- which is how I managed my packer-based nvim config prior to Nix, I'm
-- putting everything in here in sections and themed functions. It just makes it
-- easier for me to quickly update things and it's cleaner when there's
-- interdependencies between plugins. We'll see how it goes.
local M = {}

local signs = require("pwnvim.signs")

-- Detect if neovim was launched by page pager (I60R/page)
-- Checks if any argv contains /tmp/neovim-page/ pattern
local is_page_pager = (function()
  return vim.b.page_alternate_bufnr ~= nil
end)()

----------------------- UI --------------------------------
-- Tree, GitSigns, Indent markers, Colorizer, bufferline, lualine, treesitter
M.ui = function()
  require("pwnvim.plugins.nvim-tree")

  -- dadbod-ui
  -- vim.g.db_ui_use_nerd_fonts = not SimpleUI
  -- vim.g.db_ui_use_nvim_notify = true

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
    keymaps = {
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
    },
    surrounds = surround_defaults.surrounds,
    highlight = { duration = 1 },
    move_cursor = "begin",
    indent_lines = surround_defaults.indent_lines
  })

  require("pwnvim.plugins.gitsigns")
  require("diffview").setup({})
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
  -- require("pwnvim.plugins.bufferline")
  -- indent guides now handled by snacks.indent
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
              -- icon = ' ',
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


----------------------- DIAGNOSTICS --------------------------------
M.diagnostics = function()
  -- IMPORTANT: make sure to setup neodev BEFORE lspconfig
  require("neodev").setup({
    -- help for neovim lua api
    override = function(root_dir, library)
      if string.match(root_dir, "neovim") or
          string.match(root_dir, "pwnvim") or
          string.match(root_dir, "lua") then
        library.enabled = true
        library.plugins = true
        library.types = true
        library.runtime = true
      end
    end,
    lspconfig = true
  })

  if not SimpleUI then
    require("notify").setup({
      stages = "static",
      timeout = 5000,
    })
    require("noice").setup({
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          -- ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = false,
          -- ["cmp.entry.get_documentation"] = true
        },
        progress = {
          enabled = true,
          -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
          -- See the section on formatting for more details on how to customize.
          --- @type NoiceFormat|string
          format = "lsp_progress",
          --- @type NoiceFormat|string
          format_done = "lsp_progress_done",
          throttle = 1000 / 30, -- frequency to update lsp progress message
          view = "mini"
        },
        hover = {
          enabled = true,
          silent = false, -- set to true to not show a message if hover is not available
          view = nil,     -- when nil, use defaults from documentation
          ---@type NoiceViewOptions
          opts = {}       -- merged with defaults from documentation
        },
        documentation = {
          view = "hover",
        },
        signature = {
          enabled = true,
          auto_open = {
            enabled = true,
            trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
            luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
            throttle = 50   -- Debounce lsp signature help request by 50ms
          },
          view = nil,       -- when nil, use defaults from documentation
          ---@type NoiceViewOptions
          opts = {}         -- merged with defaults from documentation
        },
        message = {
          -- Messages shown by lsp servers
          enabled = true,
          view = "notify",
          opts = {}
        }
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = true,         -- use a classic bottom cmdline for search
        command_palette = false,      -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false,           -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true         -- add a border to hover docs and signature help
      },
      cmdline = { enabled = true, view = "cmdline", format = { conceal = false } },
      messages = {
        enabled = true,
        view = "mini",
        view_error = "notify",
        view_warn = "notify",
        view_history = "messages", -- view for :messages
        view_search = "virtualtext"
      },
      popupmenu = { enabled = true, backend = "nui" },
      notify = {
        -- Noice can be used as `vim.notify` so you can route any notification like other messages
        -- Notification messages have their level and other properties set.
        -- event is always "notify" and kind can be any log level as a string
        -- The default routes will forward notifications to nvim-notify
        -- Benefit of using Noice for this is the routing and consistent history view
        enabled = true,
        view = "notify"
      },
      routes = {
        {
          filter = { event = "msg_show", kind = "search_count" },
          opts = { skip = true },
        },
        -- always route any messages with more than 20 lines to the split view
        {
          view = "split",
          filter = { event = "msg_show", min_height = 20 },
        },
        -- suppress "E36: Not enough room" error
        { filter = { event = "msg_show", find = "E36" },                 opts = { skip = true } },
        -- suppress "semantic_tokens.lua" error
        { filter = { event = "msg_show", find = "semantic_tokens.lua" }, opts = { skip = true } }
      },
    })
  end

  vim.diagnostic.config({
    virtual_text = false,
    signs = signs.signs,
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = ""
    }
  })
  -- off with noice on instead now
  -- vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  --   vim.lsp.handlers.hover,
  --   { border = "rounded" })

  -- vim.lsp.handlers["textDocument/signatureHelp"] =
  --     vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

  require("trouble").setup({
    group = true, -- group results by file
    --icons = true,
    auto_preview = true,
    auto_close = false,
    preview = {
      type = "float",
      relative = "editor",
      border = "rounded",
      title = "Preview",
      title_pos = "center",
      position = { 0, -2 },
      size = { width = 0.3, height = 0.3 },
      zindex = 200,
    },
    modes = {
      mydiags = {
        mode = "diagnostics", -- inherit from diagnostics mode
        filter = {
          any = {
            buf = 0,                                    -- current buffer
            {
              severity = vim.diagnostic.severity.ERROR, -- errors only
              -- limit to files in the current project
              function(item)
                return item.filename:find((vim.loop or vim.uv).cwd(), 1, true)
              end,
            },
          },
        },
      },
      cascade = {
        mode = "diagnostics", -- inherit from diagnostics mode
        filter = function(items)
          local severity = vim.diagnostic.severity.HINT
          for _, item in ipairs(items) do
            severity = math.min(severity, item.severity)
          end
          return vim.tbl_filter(function(item)
            return item.severity == severity
          end, items)
        end,
      },
    },
    signs = {
      error = signs.error,
      warning = signs.warn,
      hint = signs.hint,
      information = signs.info,
      other = "﫠"
    },
    action_keys = {
      close = { "q", "<F7>" }
    }
  })

  local function attached(client, bufnr)
    local mapleadernvlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleadernv)
    local mapleadernlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleadern)
    local mapleadervlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleaderv)
    local mapnviclocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapnvic)
    local mapnlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapn)

    vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", { buf = bufnr })
    vim.api.nvim_set_option_value("tagfunc", "v:lua.vim.lsp.tagfunc", { buf = bufnr })

    mapleadernlocal("le", vim.diagnostic.open_float, "Show Line Diags")
    --
    -- There should be a check on this for server_capabilities.inlayHint, but that doesn't exist and
    -- I should probably differentiate between inline hints and inline diagnostics, but for now,
    -- either all on or all off
    mapleadernvlocal("ll", function()
      -- the scope filter is supported in diagnostics, but not yet in inlay hints as far as I know, but
      -- i'm adding it so things will improve when nvim does
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), { bufnr = 0, scope = "line" })
      vim.diagnostic.config({ virtual_text = vim.lsp.inlay_hint.is_enabled() })
    end, "Toggle virtual text lines")

    if vim.bo[bufnr].filetype == "rust" then
      mapleadernlocal("rr", "RustLsp runnables", "Runnables")
      mapleadernlocal("rt", "RustLsp testables", "Testables")
      mapleadernlocal("re", "RustLsp explainError", "Explain error")
      mapleadernlocal("rh", "RustLsp hover actions", "Rust hover actions")
      mapleadervlocal("rh", "RustLsp hover range", "Rust hover")
      mapleadernlocal("ra", "RustLsp codeAction", "Rust code actions")
      mapleadernlocal("rd", "RustLsp openDocs", "Rust docs for symbol under cursor")
    end

    -- Set some keybinds conditional on server capabilities
    if client.server_capabilities.definitionProvider or client.server_capabilities.typeDefinitionProvider then
      mapleadernlocal("ld", vim.lsp.buf.definition, "Go to definition")
      -- override standard tag jump c-] for go to definition
      mapnlocal("<c-]>", vim.lsp.buf.definition, "Go to definition")
    end

    if client.server_capabilities.codeActionProvider then
      mapleadernlocal("lf", vim.lsp.buf.code_action, "Fix code actions")
      -- range parameter is automatically populated in visual mode
      mapleadervlocal("lf", vim.lsp.buf.code_action, "Fix code actions (range)")
    end

    if client.server_capabilities.implementationProvider then
      mapleadernlocal("lD", vim.lsp.buf.implementation, "Implementation")
    end

    if client.server_capabilities.signatureHelpProvider then
      mapleadernlocal("lt", vim.lsp.buf.signature_help, "Signature")
    end

    if client.server_capabilities.hoverProvider or client.server_capabilities.hover then
      mapleadernlocal("li", vim.lsp.buf.hover, "Info hover")
      mapnlocal("K", vim.lsp.buf.hover, "Info hover")
    end

    if client.server_capabilities.documentFormattingProvider then
      mapleadernlocal("l=", vim.lsp.buf.format, "Format file")
      vim.bo.formatexpr = 'v:lua.vim.lsp.formatexpr(#{timeout_ms:500})'
      -- vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr(#{timeout_ms:500})')
    end

    if client.server_capabilities.documentRangeFormattingProvider then
      -- range parameter is automatically populated in visual mode
      mapleadervlocal("l=", vim.lsp.buf.format, "Format range")
    end

    if client.server_capabilities.references or client.server_capabilities.referencesProvider then
      mapleadernlocal("lr", function() Snacks.picker.lsp_references() end, "References")
    end

    if client.server_capabilities.documentSymbolProvider then
      -- print("GOT documentSymbolProvider")
      require("nvim-navic").attach(client, bufnr)    -- setup context showing header line
      require("nvim-navbuddy").attach(client, bufnr) -- setup popup for browsing symbols
      -- mapleadernlocal("lsd", builtin.lsp_document_symbols, "Find symbol in document")
      mapleadernlocal("lsd", require("nvim-navbuddy").open, "Find symbol in document")
      -- if vim.bo[bufnr].filetype ~= "markdown" then
      -- Sometimes other LSPs attach to markdown (like tailwindcss) and so we have a race to see which F7 will win...
      mapnviclocal("<F7>", require("nvim-navbuddy").open, "Browse document symbols")
      -- end
    end

    if client.server_capabilities.workspaceSymbolProvider then
      mapleadernlocal("lsw", function() Snacks.picker.lsp_workspace_symbols() end, "Find symbol in workspace")
    end

    if client.server_capabilities.implementationProvider or client.server_capabilities.implementation then
      mapleadernlocal("lI", function() Snacks.picker.lsp_implementations() end, "Implementations")
    end

    if client.server_capabilities.renameProvider or client.server_capabilities.rename then
      mapleadernlocal("lR", vim.lsp.buf.rename, "Rename")
    end

    -- Below is only possible because of nvim-ufo
    -- Not supported in neovim yet; see https://github.com/neovim/neovim/pull/14306
    if client.server_capabilities.foldingRangeProvider and vim.bo[bufnr].filetype ~= "markdown" then
      mapnlocal('zR', require("ufo").openAllFolds, "Open all folds")
      mapnlocal('zM', require("ufo").closeAllFolds, "Close all folds")
      mapnlocal('zr', require('ufo').openFoldsExceptKinds, "Fold less")
      mapnlocal('zm', require('ufo').closeFoldsWith, "Fold more")
    end

    require("which-key").add({
      mode = { "n", "v" },
      { "<leader>ls", group = "symbols" },
      { "<leader>lc", group = "change" },
    })
  end

  -- Allow LSP based folding, then fall back to treesitter and indent
  -- Special handling for markdown for now
  require('ufo').setup({
    provider_selector = function(bufnr, filetype, _)
      local ufoFt = {
        markdown = "", -- no ufo for markdown
        [""] = ""      -- no ufo for blank docs
      }
      local function customizeSelector()
        local function handleFallbackException(err, providerName)
          if type(err) == 'string' and err:match('UfoFallbackException') then
            return require('ufo').getFolds(providerName, bufnr)
          else
            return require('promise').reject(err)
          end
        end

        return require('ufo').getFolds('lsp', bufnr):catch(function(err)
          return handleFallbackException(err, 'treesitter')
        end):catch(function(err)
          return handleFallbackException(err, 'indent')
        end)
      end
      return ufoFt[filetype] or customizeSelector
    end
  })

  require('lint').linters_by_ft = {
    markdown = { 'vale' },
    -- NOTE: prettier is no longer a stock option
    -- css = { 'prettier' },
    -- svelte = { 'eslint_d' },
    python = { "mypy", "ruff" },
    nix = { "statix" },
    bash = { "shellcheck" },
    -- typescript = { "eslint_d", "prettier" },
    -- javascript = { "eslint_d", "prettier" },
    -- rust = { "rustfmt" }
  }

  require("conform").setup({ -- use formatter.nvim instead?
    notify_on_error = true,
    format_on_save = {
      -- These options will be passed to conform.format()
      timeout_ms = 800,
      lsp_fallback = true -- if no defined or available formatter, try lsp formatter
    },
    formatters = {
      prettier = {
        -- below path set in init.lua which is made in flake.nix
        command = prettier_path,
        args = { "--stdin-filepath", "$FILENAME", "--tab-width", "2" }
      },
      lua_format = {
        command = "lua-format",
        args = { "-i", "--no-use-tab", "--indent-width=2" },
        stdin = true
      },
      alejandra = {
        command = "alejandra",
        args = { "-q", "-q" }
      }

    },
    formatters_by_ft = {
      -- lua = {{"lua_format", "stylua"}},
      python = { "black" },
      -- Use a sub-list to run only the first available formatter
      -- javascript = { "prettier", "eslint_d" }, -- handled by lsp
      -- javascriptreact = { "prettier", "eslint_d" }, -- handled by lsp
      -- typescript = { "prettier", "eslint_d" }, -- handled by lsp
      -- typescriptreact = { "prettier", "eslint_d" }, -- handled by lsp
      vue = { "prettier", "eslint_d" },
      scss = { "prettier", "eslint_d" },
      html = { "prettier", "eslint_d" },
      css = { "prettier", "eslint_d" },
      json = { "prettier", "eslint_d" },
      jsonc = { "prettier", "eslint_d" },
      yaml = { "prettier", "eslint_d" },
      -- svelte = { { "prettier", "eslint_d" } }, -- handled by lsp
      nix = { "alejandra" }
    }
  })
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function() require("lint").try_lint() end
  })

  -- local lspconfig = require("lspconfig")

  local capabilities = vim.tbl_extend("force", vim.lsp.protocol
    .make_client_capabilities(),
    require('blink.cmp').get_lsp_capabilities({}, false))
  capabilities = vim.tbl_deep_extend('force', capabilities, {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true
      }
    }
  })

  vim.g.rustaceanvim = (function()
    local uname = vim.uv.os_uname().sysname

    local codelldb_path = lldb_path_base .. "/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb"
    local codelldb_lib = lldb_path_base ..
        "/share/vscode/extensions/vadimcn.vscode-lldb/adapter/libcodelldb" .. (uname == "Linux" and ".so" or ".dylib")
    local cfg = require('rustaceanvim.config')

    -- capabilities = vim.tbl_deep_extend('force', capabilities, {
    --   workspace = {
    --     didChangeWatchedFiles = {
    --       dynamicRegistration = true
    --     }
    --   }
    -- })

    local logfile = vim.fn.tempname() .. '-rust-analyzer.log'

    return {
      dap = {
        adapter = cfg.get_codelldb_adapter(codelldb_path, codelldb_lib),
        autoload_configurations = true,
        configuration = {
          stopOnEntry = true,
        },
        load_rust_types = true,
      },
      tools = {
        -- test_executor = 'background'
      },
      server = {
        on_attach = attached,
        capabilities = capabilities,
        cmd = { rustanalyzer_path, "--log-file", logfile }, -- rustanalyzer_path is a global set in flake.nix
        logfile = logfile,
        default_settings = {
          -- below doesn't work -- wrong place?  check flake.nix for where these are set in the environment on startup
          -- extraEnv = {
          --   RA_LOG = "info",
          -- },
          files = {
            watcherExclude = {
              ["**/.git/**"] = true,
              ["**/.direnv/**"] = true,
              ["**/target/**"] = true,
              ["/nix/**"] = true,
            }
          },

          ["rust-analyzer"] = {
            files = {
              excludeDirs = {
                ".direnv",
                "_build",
                ".git",
                ".venv",
                "target"
              }
            },
            cargo = {
              allFeatures = false, -- compile with --features-all? no!
            },
            checkOnSave = true,
            check = {
              extraArgs = {
                "--no-deps"
              },
              -- "cargo check" shows only compiler issues whereas "cargo clippy" shows code suggestions as well
              command =
              "clippy" -- note: assuming here that this is calling "cargo clippy"; if not, we need "cargo-clippy" here
            },
            diagnostics = {
              enable = true,
              experimental = {
                enable = true,
              }
            }
          }
        }
      }
    }
  end)()

  -- Fix an issue with current rust analyzer by suppressing a bogus message
  -- See https://github.com/neovim/neovim/issues/30985
  for _, method in ipairs({ 'textDocument/diagnostic', 'workspace/diagnostic' }) do
    local default_diagnostic_handler = vim.lsp.handlers[method]
    vim.lsp.handlers[method] = function(err, result, context, config)
      if err ~= nil and err.code == -32802 then
        return
      end
      return default_diagnostic_handler(err, result, context, config)
    end
  end


  vim.lsp.config.marksman = {
    capabilities = capabilities,
    on_attach = attached,
    -- root_dir = lspconfig.util.root_pattern('nope'), -- this is a temp fix for an error in the lspconfig for this LS
    single_file_support = true,
  }
  vim.lsp.enable("marksman")
  -- lspconfig.markdown_oxide.setup({
  --   capabilities = capabilities,
  --   on_attach = attached,
  --   root_dir = lspconfig.util.root_pattern('nope'), -- this is a temp fix for an error in the lspconfig for this LS
  --   single_file_support = true,
  -- })
  vim.lsp.config.yamlls = {
    on_attach = attached,
    capabilities = capabilities,
    settings = {
      yaml = {
        format = { enable = true },
        schemaStore = {
          enable = true
        },
        schemas = {
          ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
          ["http://json.schemastore.org/ansible-playbook"] = "*play*.{yml,yaml}",
          ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
          ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
          ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
          ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
          ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
          ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
          ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] =
          "*gitlab-ci*.{yml,yaml}",
          ["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
          ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] =
          "*api*.{yml,yaml}",
          ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] =
          "*flow*.{yml,yaml}",
          ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] =
          "*docker-compose*.{yml,yaml}",
          ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] =
          "azure-pipelines.yml",
          ["https://raw.githubusercontent.com/GoogleContainerTools/skaffold/master/docs/content/en/schemas/v2beta26.json"] =
          "skaffold.yaml",
          ["https://raw.githubusercontent.com/rancher/k3d/main/pkg/config/v1alpha3/schema.json"] = "k3d.yaml",
          ["kubernetes"] = { 'k8s**.yaml', 'kube*/*.yaml' }
        },
      },
    }
  }
  vim.lsp.enable("yamlls")
  vim.lsp.config.ts_ls =
  { capabilities = capabilities, on_attach = attached, init_options = { preferences = { disableSuggestions = true, } } }
  vim.lsp.enable("ts_ls")

  vim.lsp.config.lua_ls = {
    on_attach = attached,
    capabilities = capabilities,
    filetypes = { "lua" },
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = "LuaJIT"
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = { "vim", "string", "require" }
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = { vim.env.VIMRUNTIME },
          checkThirdParty = false
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = { enable = false },
        completion = { enable = true, callSnippet = "Replace" }
      }
    }
  }
  vim.lsp.enable("lua_ls")
  vim.lsp.config.svelte = { on_attach = attached, capabilities = capabilities }
  vim.lsp.enable("svelte")
  -- lspconfig.jinja_lsp.setup({ filetypes = { 'jinja', 'jinja2', 'twig', 'html' } })
  vim.lsp.config.tailwindcss = {
    on_attach = attached,
    capabilities = capabilities,
    root_dir = require("lspconfig/util").root_pattern(
      "tailwind.config.js",
      "tailwind.config.ts",
      "tailwind.config.cjs"
    ),
    filetypes = { "css", "html", "svelte" },
    settings = {
      files = { exclude = { "**/.git/**", "**/node_modules/**", "**/*.md" } }
    }
  }
  vim.lsp.enable("tailwindcss")
  -- nil_ls is a nix lsp
  --[[ lspconfig.nil_ls.setup({
    on_attach = attached,
    capabilities = capabilities,
    settings = { ["nil"] = { nix = { flake = { autoArchive = false } } } }
  }) ]]
  vim.lsp.config.nixd = {
    on_attach = attached,
    capabilities = capabilities
  }
  vim.lsp.enable("nixd")
  vim.lsp.config.cssls = {
    on_attach = attached,
    capabilities = capabilities,
    settings = { css = { lint = { unknownAtRules = "ignore" } } }
  }
  vim.lsp.enable("cssls")
  vim.lsp.config.eslint = {
    on_attach = attached,
    capabilities = capabilities,
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue", "astro" } -- no svelte
  }
  vim.lsp.enable("eslint")
  vim.lsp.config.html = { on_attach = attached, capabilities = capabilities }
  vim.lsp.enable("html")
  vim.lsp.config.bashls = { on_attach = attached, capabilities = capabilities }
  vim.lsp.enable("bashls")
  -- TODO: investigate nvim-metals and remove line below
  vim.lsp.config.metals = { on_attach = attached, capabilities = capabilities } -- for scala
  vim.lsp.enable("metals")
  vim.lsp.config.pyright = {
    on_attach = attached,
    capabilities = capabilities,
    filetypes = { "python" }
  } -- for python
  vim.lsp.enable("pyright")
  vim.lsp.config.jsonls = {
    on_attach = attached,
    settings = {
      json = {
        schemas = require("schemastore").json.schemas(),
        validate = { enable = true }
      }
    },
    setup = {
      commands = {
        Format = {
          function()
            vim.lsp.buf.range_formatting({}, { 0, 0 },
              { vim.fn.line("$"), 0 })
          end
        }
      }
    },
    capabilities = capabilities
  }
  vim.lsp.enable("jsonls")
  -- require("nvim-lightbulb").setup({
  --   autocmd = { enabled = true },
  --   sign = { enabled = true },
  --   virtual_text = { enabled = false, },
  --   float = { enabled = false },
  --   action_kinds = { "quickfix", "source.fixAll" },
  --   hide_in_unfocused_buffer = true,
  -- })
end -- Diagnostics setup

M.llms = function()
  local constants = {
    LLM_ROLE = "llm",
    USER_ROLE = "user",
    SYSTEM_ROLE = "system",
  }
  local fmt = string.format

  -- status is true if the function ran without errors; isOllamaRunning is true if we had a successful connection
  -- the on_error function should avoid any errors propagating, but it seems that doesn't always work, hence the pcall
  -- local status, isOllamaRunning = pcall(function()
  --   return require("plenary.curl").get("http://localhost:11434", {
  --     timeout = 50,
  --     on_error = function(e) return { status = e.exit } end,
  --   }).status == 200
  -- end)

  --[[ if status and isOllamaRunning then
    vim.g.codecompanion_adapter = "ollamacode"
  else
    vim.g.codecompanion_adapter = "copilot"
  end ]]
  -- vim.g.codecompanion_adapter = "gptoss"
  vim.g.codecompanion_adapter = "openai"

  require("codecompanion").setup({
    ignore_warnings = true, -- they have some warning about breaking changes soon to suppress 2025-12-14
    -- action_palette = {
    --   provider = "telescope"
    -- },
    display = {
      chat = {
        render_headers = true,
        show_settings = false, -- can't change models when this is true
      }
    },
    opts = {
      log_level = "TRACE", -- TRACE|DEBUG|ERROR|INFO
      language = "English",
    },
    adapters = {
      acp = {
        gemini_cli = function()
          return require("codecompanion.adapters").extend("gemini_cli", {
            defaults = {
              auth_method = "gemini-api-key", -- "oauth-personal"|"gemini-api-key"|"vertex-ai"
            },
            env = {
              GEMINI_API_KEY = "cmd:security find-generic-password -l geminikey -g -w |tr -d '\n'",
            },
          })
        end,
      },
      http = {
        --[[ ollamacode = function()
        return require("codecompanion.adapters").extend("ollama", {
          name = "ollamacode",
          env = {
            url = "http://127.0.0.1:11434",
          },
          schema = {
            model = {
              default = "qwen2.5-coder:32b",
            },
          },
          headers = {
            ["Content-Type"] = "application/json",
          },
          parameters = {
            sync = true,
          },
        })
      end,
      ollamaprose = function()
        return require("codecompanion.adapters").extend("ollama", {
          name = "ollamaprose",
          env = {
            url = "http://127.0.0.1:11434",
          },
          schema = {
            model = {
              default = "llama3.2:3b",
            },
          },
          headers = {
            ["Content-Type"] = "application/json",
          },
          parameters = {
            sync = true,
          },
        })
      end, ]]
        -- copilot_o3 = function()
        --   return require("codecompanion.adapters").extend("copilot", {
        --     schema = {
        --       model = {
        --         default = "o3",
        --       },
        --     },
        --   })
        -- end,
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = "cmd:security find-generic-password -l anthropickey -g -w |tr -d '\n'",
            },
          })
        end,
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            -- schema = {
            -- model = {
            -- default = "o4-mini",
            -- },
            -- },
            env = {
              api_key = "cmd:security find-generic-password -l openaikey -g -w |tr -d '\n'"
            }
          })
        end,
        -- below definition is for llama-cpp
        --[[ gptoss = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          name = "gptoss",
          env = {
            url = "http://aironcore.savannah-basilisk.ts.net:8080", -- optional: default value is ollama url http://127.0.0.1:11434
            chat_url = "/v1/chat/completions",
            models_endpoint = "/v1/models",

          },
          schema = {
            model = {
              default = "/home/pwalsh/.cache/llama.cpp/ggml-org_gpt-oss-20b-GGUF_gpt-oss-20b-mxfp4.gguf",
              -- default = "gpt-oss-20b-GGUF", -- define llm model to be used
              -- default = "ggml-org_gpt-oss-20b-GGUF_gpt-oss-20b-mxfp4.gguf", -- define llm model to be used
            },
          }
        })
      end, ]]
        -- below definition is for ollama with gpgoss
        --[[ gptoss = function()
        return require("codecompanion.adapters").extend("ollama", {
          name = "gptoss",
          opts = {
            vision = false,
            stream = true,
          },
          env = {
            url = "http://aironcore.savannah-basilisk.ts.net:11434",
          },
          schema = {
            model = {
              default = "gpt-oss:20b",
            },
          },
          -- headers = {
          --   ["Content-Type"] = "application/json",
          -- },
          parameters = {
            sync = true,
          },
        })
      end, ]]
        opts = {
          allow_insecure = false, -- Allow insecure connections? yes if we're using ollama
          show_model_choices = true,
        },

      }
    },
    strategies = {
      chat = {
        adapter = "openai",
      },
      inline = {
        adapter = "openai",
      },
      agent = {
        adapter = "gemini_cli",
      },
    },
    prompt_library = {
      ["Summarize"] = {
        strategy = "chat",
        description = "Summarize some text",
        opts = {
          index = 3,
          is_default = true,
          modes = { "v" },
          short_name = "summarize",
          is_slash_cmd = false,
          auto_submit = true,
          user_prompt = false,
          stop_context_insertion = true,
        },
        prompts = {
          {
            role = constants.SYSTEM_ROLE,
            content =
            [[I want you to act as a senior editor at a newspaper whose job is to make short summaries of articles for search engines.]],
            opts = {
              visible = false,
              tag = "system_tag",
            },
          },
          {
            role = constants.USER_ROLE,
            content = function(context)
              local prose = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
              return fmt(
                [[Summarize the contents of the article that starts below the "---". Make your summary be 150 to 170 characters long to fit in a web page meta description:

                ---
                %s

                Summarize that in 150 characters.
                ]], prose
              )
            end
          }
        },
      }
    },
  })
  vim.cmd([[cab cc CodeCompanion]])
end

----------------------- SNACKS PICKER --------------------------------
M.picker = function()
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
      enabled = true,
      doc = {
        enabled = true,
        inline = false, -- disable inline rendering
        float = true,   -- show images in floating window instead
        max_width = 80,
        max_height = 40,
      },
      math = {
        enabled = true,
      },
    },
    dashboard = {
      -- disable in SimpleUI, nested neovim ($NVIM set), page pager, or no tty input
      enabled = not SimpleUI and not vim.env.NVIM and not is_page_pager and vim.fn.has('ttyin') == 1,
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
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

    -- Picker (already configured)
    picker = {
      prompt = SimpleUI and "> " or " ",
      ui_select = true, -- replace vim.ui.select with snacks picker
      layout = {
        cycle = true,
        preset = function()
          return vim.o.columns >= 120 and "default" or "vertical"
        end,
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
          dev = { "~/src", "~/.config/nixpkgs", "~/Documents", "~/Notes" },
          patterns = { ".git", "flake.nix", "Cargo.toml", "package.json", ".project" },
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


----------------------- COMPLETIONS --------------------------------
-- cmp, luasnip
M.completions = function()
  local check_backspace = function()
    local col = vim.fn.col(".") - 1
    return col == 0 or
        vim.fn.getline(vim.fn.line(".")):sub(col, col):match("%s")
  end
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


----------------------- NOTES --------------------------------
-- zk (zettelkasten lsp), taskwiki, focus mode, grammar
M.notes = function()
  require("zk").setup({
    picker = "snacks_picker", -- uses vim.ui.select which snacks handles
    -- picker_options = {
    --   snacks_picker = {
    --     layout = {
    --       preset = "ivy",
    --     }
    --   },
    -- },
    -- automatically attach buffers in a zk notebook that match the given filetypes
    lsp = {
      auto_attach = {
        enabled = true,
        filetypes = { "markdown", "vimwiki", "md" }
      },
      config = {
        on_attach = function(_, bufnr)
          -- print("ZK attached")
          local mapleadernvlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleadernv)
          local mapleadernlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleadern)
          local mapleadervlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleaderv)
          local mapnlocal = require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapn)

          mapnlocal("K", vim.lsp.buf.hover, "Info hover")
          -- Create the note in the same directory as the current buffer after asking for title
          mapleadernlocal("np", "ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }",
            "New peer note (same dir)")
          mapleadernlocal("nl", "ZkLinks", "Show note links")
          mapleadernlocal("nr", function() Snacks.picker.lsp_references() end, "References to this note")
          mapleadernlocal("lr", function() Snacks.picker.lsp_references() end, "References to this note") -- for muscle memory
          mapleadernlocal("li", vim.lsp.buf.hover, "Info hover")
          mapleadernlocal("lf", vim.lsp.buf.code_action, "Fix code actions")
          mapleadernlocal("le", vim.diagnostic.open_float, "Show line diags")
          mapleadernvlocal("ll", function()
            -- the scope filter is supported in diagnostics, but not yet in inlay hints as far as I know, but
            -- i'm adding it so things will improve when nvim does
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), { bufnr = 0, scope = "line" })
            vim.diagnostic.config({ virtual_text = vim.lsp.inlay_hint.is_enabled() })
          end, "Toggle virtual text lines")
          mapleadervlocal("np",
            function() require('zk.commands').get("ZkNewFromTitleSelection")({ dir = vim.fn.expand('%:p:h') }) end,
            "New peer note (same dir) selection for title")
          mapleadernlocal("nu", function()
            vim.cmd("normal yiW")
            require("pwnvim.markdown").pasteUrl()
          end, "Turn bare URL into link")
          mapleadervlocal("nu", function()
            vim.cmd("normal y")
            require("pwnvim.markdown").pasteUrl()
          end, "Turn bare URL into link")


          -- TODO: Make <CR> magic...
          --   in normal mode, if on a link, it should open the link (note or url)
          --   in visual mode, it should prompt for folder, create a note, and make a link
          -- Meanwhile, just go to definition
          -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>",
          --   "<Cmd>lua vim.lsp.buf.definition()<CR>",
          --   opts)
          -- Preview a linked note.

          require("pwnvim.options").tabindent()
        end
      }
    }
  })

  -- Grammar
  vim.g["grammarous#disabled_rules"] = {
    ["*"] = {
      "WHITESPACE_RULE", "EN_QUOTES", "ARROWS", "SENTENCE_WHITESPACE",
      "WORD_CONTAINS_UNDERSCORE", "COMMA_PARENTHESIS_WHITESPACE",
      "EN_UNPAIRED_BRACKETS", "UPPERCASE_SENTENCE_START",
      "ENGLISH_WORD_REPEAT_BEGINNING_RULE", "DASH_RULE", "PLUS_MINUS",
      "PUNCTUATION_PARAGRAPH_END", "MULTIPLICATION_SIGN", "PRP_CHECKOUT",
      "CAN_CHECKOUT", "SOME_OF_THE", "DOUBLE_PUNCTUATION", "HELL",
      "CURRENCY", "POSSESSIVE_APOSTROPHE", --"ENGLISH_WORD_REPEAT_RULE",
      "NON_STANDARD_WORD"
    }
  }
  vim.g["grammarous#languagetool_cmd"] = 'languagetool-commandline'
  vim.g["grammarous#use_location_list"] = 1
  vim.g["grammarous#enable_spell_check"] = 0
  vim.g["grammarous#show_first_error"] = 0
  -- Below is to make mapping easier for ,ng
  vim.cmd(
    [[command StartGrammar2 lua require('pwnvim.plugins').grammar_check()]])
end -- notes

M.grammar_check = function()
  vim.cmd("packadd vim-grammarous")
  local opts = { noremap = false, silent = true }
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(0, ...) end

  buf_set_keymap("n", "<leader>gf", "<Plug>(grammarous-fixit)", opts)
  buf_set_keymap("n", "<leader>gx", "<Plug>(grammarous-remove-error)", opts)
  buf_set_keymap("n", "]g", "<Plug>(grammarous-move-to-next-error)", opts)
  buf_set_keymap("n", "[g", "<Plug>(grammarous-move-to-previous-error)", opts)
  vim.cmd("GrammarousCheck")
end

----------------------- MISC --------------------------------
-- rooter, kommentary, autopairs, matchup, yazi
M.misc = function()
  vim.g.lf_map_keys = 0              -- lf.vim disable default keymapping
  vim.g.matchup_surround_enabled = 0 -- disallows ds type selections
  vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  vim.g.matchup_matchparen_deferred = 1
  vim.g.matchup_motion_override_Npercent = 100
  vim.g.matchup_text_obj_linewise_operators = { 'd', 'y', 'c', 'v' }

  require("nvim-autopairs").setup({})

  vim.g.tmux_navigator_no_mappings = 1


  -- require("project_nvim").setup({
  --   active = true,
  --   on_config_done = nil,
  --   manual_mode = false,
  --   detection_methods = { "lsp", "pattern" },
  --   exclude_dirs = { "/nix/store/*" },
  --   scope_chdir = "tab",
  --   patterns = {
  --     ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json",
  --     ".zk", "build.sbt", "Package.swift", "Makefile.in", "README.md",
  --     "flake.nix"
  --   },
  --   show_hidden = false,
  --   silent_chdir = true,
  --   ignore_lsp = {}
  -- })

  require("yazi").setup({
    open_for_directories = false
  })
end -- misc

-- Custom folder picker using snacks.picker
M.pick_folder = function(search_folders, depth, callback)
  local Job = require 'plenary.job'

  local full_path_folders = {}
  -- Add base search folders first
  for _, f in ipairs(search_folders) do
    table.insert(full_path_folders, f)
  end

  local args = { '--base-directory', vim.env.HOME, "--min-depth", 1, "--max-depth", depth, "-t", "d", "-L" }
  for _, f in ipairs(search_folders) do
    table.insert(args, "--search-path")
    table.insert(args, f)
  end

  Job:new({
    command = 'fd',
    args = args,
    cwd = vim.env.HOME,
    env = { ['PATH'] = vim.env.PATH },
    on_stderr = function(err, data)
      vim.notify("stderr err: " .. vim.inspect(err) .. " data: " .. vim.inspect(data))
    end,
    on_stdout = function(err, data)
      if (err ~= nil) then
        vim.notify("stdout err: " .. vim.inspect(err) .. " data: " .. vim.inspect(data))
      else
        table.insert(full_path_folders, data)
      end
    end,
  }):sync()

  -- Create items for snacks picker
  local items = {}
  for _, folder in ipairs(full_path_folders) do
    local full_path = vim.env.HOME .. "/" .. folder
    local display = "~/" .. folder
    table.insert(items, {
      text = display,
      file = full_path,
    })
  end

  Snacks.picker.pick({
    source = "custom",
    title = "Pick Folder",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        callback(item.file)
      end
    end,
  })
end


return M
