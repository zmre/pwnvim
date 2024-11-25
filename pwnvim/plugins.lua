-- This is a mega file. Rather than make each plugin have its own config file,
-- which is how I managed my packer-based nvim config prior to Nix, I'm
-- putting everything in here in sections and themed functions. It just makes it
-- easier for me to quickly update things and it's cleaner when there's
-- interdependencies between plugins. We'll see how it goes.
local M = {}

local signs = require("pwnvim.signs")

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
  require("git-worktree").setup({
    change_directory_command = "lcd",
    update_on_change = true,
    update_on_change_command = "e .",
    clearjumps_on_change = true,
    autopush = false
  })

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
        -- Set to false to disable the vim.ui.select implementation
        enabled = true,
        backend = { "telescope", "nui", "builtin" },
        telescope = require('telescope.themes').get_dropdown()
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
  require("barbecue").setup({
    attach_navic = false, -- we'll attach when lsp attaches if it supports symbols
    show_modified = true,
  })
  require("pwnvim.plugins.indent-blankline")
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
  require("lsp_lines").setup()

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
          ["cmp.entry.get_documentation"] = true
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
            trigger = true,  -- Automatically show signature help when typing a trigger character from the LSP
            luasnip = false, -- Will open signature help when jumping to Luasnip insert nodes
            throttle = 50    -- Debounce lsp signature help request by 50ms
          },
          view = nil,        -- when nil, use defaults from documentation
          ---@type NoiceViewOptions
          opts = {}          -- merged with defaults from documentation
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
    signs = { active = { signs.signs } },
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
    auto_close = true,
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

    local builtin = require("telescope.builtin")

    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
    vim.api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.vim.lsp.tagfunc")

    mapleadernlocal("le", vim.diagnostic.open_float, "Show Line Diags")
    -- mapleadernlocal("lf", vim.lsp.buf.code_action, "Fix code actions")
    mapleadernvlocal("ll", require("lsp_lines").toggle, "Toggle virtual text lines")

    if vim.bo[bufnr].filetype == "rust" then
      local rt = require("rust-tools")
      mapleadernlocal("rr", rt.runnables.runnables, "Runnables")
      mapleadernlocal("re", rt.expand_macro.expand_macro, "Expand macro")
      mapleadernlocal("rh", rt.hover_actions.hover_actions, "Rust hover actions")
      mapleadernlocal("ra", rt.code_action_group.code_action_group, "Rust code actions")
    end

    -- Set some keybinds conditional on server capabilities
    if client.server_capabilities.definitionProvider or client.server_capabilities.typeDefinitionProvider then
      mapleadernlocal("ld", vim.lsp.buf.definition, "Go to definition")
      -- override standard tag jump c-] for go to definition
      mapnlocal("<c-]>", vim.lsp.buf.definition, "Go to definition")
    end

    if client.server_capabilities.codeActionProvider then
      mapleadernlocal("lf", "CodeActionMenu", "Fix code actions")
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
      mapleadernlocal("lr", builtin.lsp_references, "References")
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
      mapleadernlocal("lsw", builtin.lsp_workspace_symbols, "Find symbol in workspace")
    end

    if client.server_capabilities.implementationProvider or client.server_capabilities.implementation then
      mapleadernlocal("lI", require("telescope.builtin").lsp_implementations, "Implementations")
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

  local lspconfig = require("lspconfig")
  local cmp_nvim_lsp = require("cmp_nvim_lsp")

  local capabilities = vim.tbl_extend("keep", vim.lsp.protocol
    .make_client_capabilities(),
    cmp_nvim_lsp.default_capabilities())
  -- Add client folding capability, which is provided by nvim-ufo
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true
  }

  require("rust-tools").setup({
    server = {
      on_attach = attached,
      capabilities = capabilities,
      standalone = true,
      settings = {
        ["rust-analyzer"] = { files = { excludeDirs = { ".direnv" } } }
      }
    },
    tools = {
      autoSetHints = true,
      inlay_hints = { auto = true, only_current_line = true },
      runnables = { use_telescope = true }
    }
  })
  require("cmp-npm").setup({})

  lspconfig.marksman.setup({
    capabilities = capabilities,
    on_attach = attached,
    -- root_dir = lspconfig.util.root_pattern('nope'), -- this is a temp fix for an error in the lspconfig for this LS
    single_file_support = true,
  })
  -- lspconfig.markdown_oxide.setup({
  --   capabilities = capabilities,
  --   on_attach = attached,
  --   root_dir = lspconfig.util.root_pattern('nope'), -- this is a temp fix for an error in the lspconfig for this LS
  --   single_file_support = true,
  -- })
  lspconfig.yamlls.setup {
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
          ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = "*gitlab-ci*.{yml,yaml}",
          ["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
          ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "*api*.{yml,yaml}",
          ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "*flow*.{yml,yaml}",
          ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
          ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = "azure-pipelines.yml",
          ["kubernetes"] = "*.y{a,}ml"
        },
      },
    }
  }
  lspconfig.ts_ls
      .setup({ capabilities = capabilities, on_attach = attached, init_options = { preferences = { disableSuggestions = true, } } })

  lspconfig.lua_ls.setup({
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
  })
  lspconfig.svelte.setup({ on_attach = attached, capabilities = capabilities })
  lspconfig.tailwindcss.setup({
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
  })
  -- nil_ls is a nix lsp
  --[[ lspconfig.nil_ls.setup({
    on_attach = attached,
    capabilities = capabilities,
    settings = { ["nil"] = { nix = { flake = { autoArchive = false } } } }
  }) ]]
  lspconfig.nixd.setup({
    on_attach = attached,
    capabilities = capabilities
  })
  lspconfig.cssls.setup({
    on_attach = attached,
    capabilities = capabilities,
    settings = { css = { lint = { unknownAtRules = "ignore" } } }
  })
  lspconfig.eslint.setup({
    on_attach = attached,
    capabilities = capabilities,
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue", "astro" } -- no svelte
  })
  lspconfig.html.setup({ on_attach = attached, capabilities = capabilities })
  lspconfig.bashls.setup({ on_attach = attached, capabilities = capabilities })
  -- TODO: investigate nvim-metals and remove line below
  lspconfig.metals.setup({ on_attach = attached, capabilities = capabilities }) -- for scala
  lspconfig.pyright.setup({
    on_attach = attached,
    capabilities = capabilities,
    filetypes = { "python" }
  }) -- for python
  lspconfig.jsonls.setup({
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
  })
  require("nvim-lightbulb").setup({
    autocmd = { enabled = true },
    sign = { enabled = false },
    virtual_text = { enabled = true, },
    float = { enabled = false }
  })
end -- Diagnostics setup

----------------------- TELESCOPE --------------------------------
M.telescope = function()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local function quicklook_selected_entry(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    -- actions.close(prompt_bufnr)
    vim.cmd("silent !qlmanage -p '" .. entry.value .. "'")
  end

  local function yank_selected_entry(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    -- Put it in the unnamed buffer and the system clipboard both
    vim.api.nvim_call_function("setreg", { '"', entry.value })
    vim.api.nvim_call_function("setreg", { "*", entry.value })
  end

  local function system_open_selected_entry(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    os.execute("open '" .. entry.value .. "'")
  end

  local trouble = require("trouble.sources.telescope")
  require("telescope").setup({
    file_ignore_patterns = {
      "*.bak", ".git/", "node_modules", ".zk/", "Caches/", "Backups/"
    },
    prompt_prefix = SimpleUI and ">" or " ",
    selection_caret = SimpleUI and "↪" or " ",
    -- path_display = { "smart" },
    defaults = {
      winblend = 30, -- small transparency for telescope popups -- should only matter in neovide
      path_display = function(_, path)
        local tail = require("telescope.utils").path_tail(path)
        return string.format("%s (%s)", tail,
          require("telescope.utils").path_smart(
            path:gsub("/Users/[^/]*/", "~/"):gsub(
              "/[^/]*$", ""):gsub(
              "/Library/Containers/co.noteplan.NotePlan3/Data/Library/Application Support/co.noteplan.NotePlan3",
              "/NotePlan")))
      end,
      -- path_display = { "truncate" },
      mappings = {
        n = {
          ["<c-t>"] = trouble.open,
          ["<C-y>"] = yank_selected_entry,
          ["<C-o>"] = system_open_selected_entry,
          ["<F10>"] = quicklook_selected_entry,
          ["dd"] = require("telescope.actions").delete_buffer,
          ["q"] = require("telescope.actions").close
        },
        i = {
          ["<c-t>"] = trouble.open,
          ["<c-h>"] = "which_key",
          ["<C-y>"] = yank_selected_entry,
          ["<F10>"] = quicklook_selected_entry,
          ["<C-o>"] = system_open_selected_entry
        }
      },
      vimgrep_arguments = {
        "rg", "--color=never", "--no-heading", "--with-filename",
        "--line-number", "--column", "--smart-case"
      },
      -- Telescope smart history
      history = {
        path = "~/.local/share/nvim/databases/telescope_history.sqlite3",
        limit = 100
      },
      layout_strategy = "flex",
      layout_config = {
        horizontal = { prompt_position = "bottom", preview_width = 0.55 },
        vertical = { mirror = false },
        width = 0.87,
        height = 0.80,
        preview_cutoff = 1
      },
      color_devicons = not SimpleUI,
      set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
      file_previewer = require("telescope.previewers").vim_buffer_cat.new,
      grep_previewer = require("telescope.previewers").vim_buffer_vimgrep
          .new,
      qflist_previewer = require("telescope.previewers").vim_buffer_qflist
          .new
    },

    extensions = {
      fzy_native = {
        override_generic_sorter = true,
        override_file_sorter = true
      },
      frecency = {
        ignore_patterns = { "*.git/*", "*/tmp/*", ".*ignore", "*.DS_Store*", "Caches", "Backups", "/Applications",
          "/bin", "*/.localized" },
        -- show the tail for "LSP", "CWD" and "FOO"
        show_filter_column = { "LSP", "CWD" },
        show_scores = true,
        show_unindexed = false,
        use_sqlite = false
      }
    }
  })
  require("telescope").load_extension("fzy_native")
  require("telescope").load_extension("zk")
  if not SimpleUI then
    require("telescope").load_extension("noice")
  end
  -- require("telescope").load_extension("frecency")
  require("telescope").load_extension("git_worktree")
  if vim.fn.has("mac") ~= 1 then
    -- doesn't currently work on mac
    require("telescope").load_extension("media_files")
  end
end -- telescope

----------------------- COMPLETIONS --------------------------------
-- cmp, luasnip
M.completions = function()
  -- require("luasnip/loaders/from_vscode").lazy_load()
  -- local luasnip = require("luasnip")
  local check_backspace = function()
    local col = vim.fn.col(".") - 1
    return col == 0 or
        vim.fn.getline(vim.fn.line(".")):sub(col, col):match("%s")
  end
  local cmp = require("cmp")
  cmp.setup({
    enabled = function()
      local context = require("cmp.config.context")
      local buftype = vim.api.nvim_buf_get_option(0, "buftype")
      -- prevent completions in prompts like telescope prompt
      if buftype == "prompt" then return false end
      -- allow completions in command mode
      if vim.api.nvim_get_mode().mode == "c" then return true end
      -- forbid completions in comments
      return not context.in_treesitter_capture("comment") and
          not context.in_syntax_group("Comment")
    end,
    mapping = {
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<C-n>"] = cmp.mapping.select_next_item(),
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete({}),
      ["<C-e>"] = cmp.mapping.close(),
      ["<CR>"] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = false
      }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
          -- elseif luasnip.expandable() then
          --   luasnip.expand({})
          -- elseif luasnip.expand_or_jumpable() then
          --   luasnip.expand_or_jump()
        elseif check_backspace() then
          fallback()
        else
          cmp.mapping.complete({})
          -- fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
          -- elseif luasnip.jumpable(-1) then
          --   luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" })
    },
    -- window = { documentation = cmp.config.window.bordered() },
    sources = {
      { name = "nvim_lsp" },
      -- { name = "nvim_lsp_signature_help" },
      { name = "nvim_lua" }, { name = "emoji" },
      -- { name = "luasnip" },
      { name = "path" }, { name = "crates" },
      { name = "npm",    keyword_length = 3 },
      { name = "buffer", keyword_length = 3 }
    },
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, vim_item)
        -- Kind icons
        vim_item.kind = string.format("%s",
          signs.kind_icons[vim_item.kind])
        vim_item.menu = ({
          nvim_lsp = "[LSP]",
          nvim_lsp_signature_help = "[LSPS]",
          -- luasnip = "[Snippet]",
          buffer = "[Buffer]",
          path = "[Path]"
        })[entry.source.name]
        return vim_item
      end
    },
    -- snippet = { expand = function(args) luasnip.lsp_expand(args.body) end }
  })
  --[[ cmp.setup.cmdline("/", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = { { name = "buffer" } }
  })
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({ { name = "path" } }, {
      { name = "cmdline", option = { ignore_cmds = { "Man", "!" } } }
    })
  }) ]]
end -- completions


----------------------- NOTES --------------------------------
-- zk (zettelkasten lsp), taskwiki, focus mode, grammar
M.notes = function()
  require("zk").setup({
    picker = "telescope",
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
          mapleadernlocal("nr", require("telescope.builtin").lsp_references, "References to this note")
          mapleadernlocal("lr", require("telescope.builtin").lsp_references, "References to this note") -- for muscle memory
          mapleadernlocal("li", vim.lsp.buf.hover, "Info hover")
          -- mapleadernlocal("lf", vim.lsp.buf.code_action, "Fix code actions")
          mapleadernlocal("lf", "CodeActionMenu", "Fix code actions")
          mapleadernlocal("le", vim.diagnostic.open_float, "Show line diags")
          mapleadernvlocal("ll", require("lsp_lines").toggle, "Toggle virtual text lines")
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

  -- Focus mode dimming of text out of current block
  --[[ require("twilight").setup {
    dimming = {
      alpha = 0.25, -- amount of dimming
      -- we try to get the foreground from the highlight groups or fallback color
      color = { "Normal", "#ffffff" },
      term_bg = "#000000", -- if guibg=NONE, this will be used to calculate text color
      inactive = true -- when true, other windows will be fully dimmed (unless they contain the same buffer)
    },
    context = 12, -- amount of lines we will try to show around the current line
    treesitter = true, -- use treesitter when available for the filetype
    -- treesitter is used to automatically expand the visible text,
    -- but you can further control the types of nodes that should always be fully expanded
    expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
      "function", "method", "table", "if_statement"
    },
    exclude = {} -- exclude these filetypes
  } ]]
  -- Focus mode / centering
  require("true-zen").setup({
    -- your config goes here
    -- or just leave it empty :)
    modes = {
      -- configurations per mode
      ataraxis = {
        shade = "dark", -- if `dark` then dim the padding windows, otherwise if it's `light` it'll brighten said windows
        backdrop = 0,   -- percentage by which padding windows should be dimmed/brightened. Must be a number between 0 and 1. Set to 0 to keep the same background color
        minimum_writing_area = {
          -- minimum size of main window
          width = 70,
          height = 44
        },
        quit_untoggles = true, -- type :q or :qa to quit Ataraxis mode
        padding = {
          -- padding windows
          left = 52,
          right = 52,
          top = 0,
          bottom = 0
        },
        callbacks = {
          -- run functions when opening/closing Ataraxis mode
          open_pre = function()
            vim.opt.scrolloff = 999 -- keep cursor in vertical middle of screen
          end,
          open_pos = nil,
          close_pre = nil,
          close_pos = function()
            vim.opt.scrolloff = 8
          end
        }
      },
      minimalist = {
        ignored_buf_types = { "nofile" }, -- save current options from any window except ones displaying these kinds of buffers
        options = {
          -- options to be disabled when entering Minimalist mode
          number = false,
          relativenumber = false,
          showtabline = 0,
          signcolumn = "no",
          statusline = "",
          cmdheight = 1,
          laststatus = 0,
          showcmd = false,
          showmode = false,
          ruler = false,
          numberwidth = 1
        },
        callbacks = {
          -- run functions when opening/closing Minimalist mode
          open_pre = nil,
          open_pos = nil,
          close_pre = nil,
          close_pos = nil
        }
      },
      narrow = {
        --- change the style of the fold lines. Set it to:
        --- `informative`: to get nice pre-baked folds
        --- `invisible`: hide them
        --- function() end: pass a custom func with your fold lines. See :h foldtext
        folds_style = "informative",
        run_ataraxis = true, -- display narrowed text in a Ataraxis session
        callbacks = {
          -- run functions when opening/closing Narrow mode
          open_pre = nil,
          open_pos = nil,
          close_pre = nil,
          close_pos = nil
        }
      },
      focus = {
        callbacks = {
          -- run functions when opening/closing Focus mode
          open_pre = nil,
          open_pos = nil,
          close_pre = nil,
          close_pos = nil
        }
      }
    },
    integrations = {
      tmux = false, -- hide tmux status bar in (minimalist, ataraxis)
      kitty = {
        -- increment font size in Kitty. Note: you must set `allow_remote_control socket-only` and `listen_on unix:/tmp/kitty` in your personal config (ataraxis)
        enabled = false, -- disabled 2023-03-20 because it doesn't reset the font size on exit
        font = "+2"
      },
      twilight = false, -- enable twilight text dimming outside cursor block
      lualine = true    -- hide nvim-lualine (ataraxis)
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
-- rooter, kommentary, autopairs, toggleterm, matchup, yazi
M.misc = function()
  vim.g.lf_map_keys = 0              -- lf.vim disable default keymapping
  vim.g.matchup_surround_enabled = 0 -- disallows ds type selections
  vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  vim.g.matchup_matchparen_deferred = 1
  vim.g.matchup_motion_override_Npercent = 100
  vim.g.matchup_text_obj_linewise_operators = { 'd', 'y', 'c', 'v' }

  -- Change project directory using local cd only
  -- vim.g.rooter_cd_cmd = 'lcd'
  -- Look for these files/dirs as hints
  -- vim.g.rooter_patterns = {
  --     '.git', '_darcs', '.hg', '.bzr', '.svn', 'Makefile', 'package.json',
  --     '.zk', 'Cargo.toml', 'build.sbt', 'Package.swift', 'Makefile.in'
  -- }


  require("nvim-autopairs").setup({})

  vim.g.tmux_navigator_no_mappings = 1

  require("toggleterm").setup({
    open_mapping = [[<c-\>]],
    shade_terminals = true,
    insert_mappings = true, -- from normal or insert mode
    terminal_mappings = false,
    start_in_insert = true,
    hide_numbers = true,
    direction = "vertical",
    size = function(_) return vim.o.columns * 0.3 end,
    close_on_exit = true
  })
  -- vim.api.nvim_set_keymap("t", [[<C-\>]], "<Cmd>ToggleTermToggleAll<cr>", { noremap = true })
  vim.api.nvim_set_keymap("t", [[<C-\>]],
    "<Cmd>exe v:count1 . 'ToggleTerm'<cr>",
    { noremap = true })

  require("project_nvim").setup({
    active = true,
    on_config_done = nil,
    manual_mode = false,
    detection_methods = { "lsp", "pattern" },
    exclude_dirs = { "/nix/store/*" },
    scope_chdir = "tab",
    patterns = {
      ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json",
      ".zk", "build.sbt", "Package.swift", "Makefile.in", "README.md",
      "flake.nix"
    },
    show_hidden = false,
    silent_chdir = true,
    ignore_lsp = {}
  })
  require("telescope").load_extension("projects")
  require("yazi").setup({
    open_for_directories = false
  })
end -- misc

M.telescope_get_folder_common_folders = function(search_folders, depth, callback)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local sorters = require "telescope.sorters"
  local themes = require "telescope.themes"
  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"
  local Job = require 'plenary.job'

  local entry = function(a)
    local value = vim.env.HOME .. "/" .. a
    local display = "~/" .. a -- (string.gsub(a, vim.env.HOME, '~'))
    return {
      value = value,
      display = display,
      ordinal = a
    }
  end

  local full_path_folders = search_folders
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
    -- on_exit = function(job,code)
    --
    -- end
  }):sync() -- or start()

  local finder = finders.new_table({
    results = full_path_folders,
    entry_maker = entry
  })
  pickers.new({}, {
    cwd = vim.env.HOME,
    prompt_title = "Pick Folder",
    finder = finder,
    sorter = sorters.fuzzy_with_index_bias(),
    theme = themes.get_dropdown(),
    attach_mappings =
        function(prompt_bufnr)
          actions.select_default:replace(function()
            local folder = action_state.get_selected_entry()
            -- print(vim.inspect(folder))
            if folder ~= nil then
              actions.close(prompt_bufnr)
              callback(folder["value"])
            end
          end)
          return true
        end
  }):find()
end


return M
