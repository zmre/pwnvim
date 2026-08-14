----------------------- DIAGNOSTICS --------------------------------
-- LSP servers, formatters (conform), linters (nvim-lint), trouble, folds (ufo)

local signs = require("pwnvim.signs")

return function()
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
      mapleadernlocal("ld", function() Snacks.picker.lsp_definitions() end, "Go to definition")
      -- override standard tag jump c-] for go to definition
      mapnlocal("<c-]>", function() Snacks.picker.lsp_definitions() end, "Go to definition")
    end

    if client.server_capabilities.codeActionProvider then
      mapleadernlocal("lf", vim.lsp.buf.code_action, "Fix code actions")
      -- range parameter is automatically populated in visual mode
      mapleadervlocal("lf", vim.lsp.buf.code_action, "Fix code actions (range)")
    end

    if client.server_capabilities.implementationProvider then
      mapleadernlocal("lD", function() Snacks.picker.lsp_implementations() end, "Implementation")
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
    end

    if client.server_capabilities.documentRangeFormattingProvider then
      -- range parameter is automatically populated in visual mode
      mapleadervlocal("l=", vim.lsp.buf.format, "Format range")
    end

    if client.server_capabilities.references or client.server_capabilities.referencesProvider then
      mapleadernlocal("lr", function() Snacks.picker.lsp_references() end, "References")
    end

    if client.server_capabilities.documentSymbolProvider then
      require("nvim-navic").attach(client, bufnr)    -- setup context showing header line
      require("nvim-navbuddy").attach(client, bufnr) -- setup popup for browsing symbols
      -- mapleadernlocal("lsd", builtin.lsp_document_symbols, "Find symbol in document")
      mapleadernlocal("lsd", require("nvim-navbuddy").open, "Find symbol in document")
      if vim.bo[bufnr].filetype ~= "markdown" then
        -- Sometimes other LSPs attach to markdown (like tailwindcss) and so we have a race to see which F7 will win...
        -- Markdown gets its own <F7> from pwnvim.markdown (outline.nvim), which works without an LSP, so leave it alone.
        mapnviclocal("<F7>", require("nvim-navbuddy").open, "Browse document symbols")
      end
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

  -- Custom linter: run `hledger check` on save for *.journal files. hledger
  -- writes errors to stderr (exit 1) in one of three location formats:
  --   /path:LINE:        (bare line)
  --   /path:LINE:COL:    (parse error with column)
  --   /path:LINE-LINE:   (a transaction spanning a line range)
  -- followed by an excerpt + message. We parse all three into diagnostics so
  -- the offending lines get underlined/signed just like LSP errors.
  require('lint').linters.hledger = {
    name = "hledger",
    cmd = "hledger",
    -- append_fname (default true) tacks the buffer path on the end, yielding
    -- `hledger check accounts commodities ordereddates balanced -f <file>`.
    args = { "check", "accounts", "commodities", "ordereddates", "balanced", "-f" },
    stdin = false,
    stream = "stderr",
    ignore_exitcode = true, -- non-zero exit just means it found problems
    parser = function(output, _)
      local diagnostics = {}
      if not output or output == "" then return diagnostics end
      -- Split on the "Error:" markers. A trailing sentinel lets the final
      -- (and usually only) block be captured by the non-greedy match.
      for block in (output .. "\nError:"):gmatch("Error:(.-)\nError:") do
        local header, body = block:match("^([^\n]*)\n(.*)$")
        header = header or block
        body = body or ""
        local file, loc = header:match("^%s*(.-):(%d[%d:%-]*):?%s*$")
        if file and loc then
          loc = loc:gsub(":$", "") -- the class above greedily eats the trailing ":"
          local lnum, col, end_lnum
          local l1, l2 = loc:match("^(%d+)%-(%d+)$") -- "1-3" line range
          if l1 then
            lnum, end_lnum = tonumber(l1), tonumber(l2)
          else
            local ln, cl = loc:match("^(%d+):(%d+)$") -- "3:1" line:col
            if ln then
              lnum, col = tonumber(ln), tonumber(cl)
            else
              lnum = tonumber(loc:match("^(%d+)")) -- "2" bare line
            end
          end
          if lnum then
            local msg = body:gsub("^%s+", ""):gsub("%s+$", "")
            if msg == "" then msg = "hledger check failed" end
            table.insert(diagnostics, {
              lnum = lnum - 1,
              col = (col or 1) - 1,
              end_lnum = (end_lnum or lnum) - 1,
              end_col = 0,
              severity = vim.diagnostic.severity.ERROR,
              source = "hledger",
              message = msg
            })
          end
        end
      end
      return diagnostics
    end
  }

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
      },
      ["hledger-fmt"] = {
        -- hledger CSV import rules (*.rules) share the "ledger" filetype but
        -- use a different DSL; hledger-fmt is a journal formatter and mangles
        -- them, so never run it on rules files (auto- or manual format).
        condition = function(_, ctx)
          return not ctx.filename:match("%.rules$")
        end
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
      nix = { "alejandra" },
      -- hledger/ledger journals: use the fast rust hledger-fmt instead of the
      -- hledger-lsp formatter, which is synchronous and very slow on large files.
      -- "hledger-fmt" is a conform built-in (args: --no-diff --exit-zero-on-changes -).
      ledger = { "hledger-fmt" }
    }
  })
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function() require("lint").try_lint() end
  })
  -- hledger check on save, scoped to *.journal by pattern (not filetype) so it
  -- never runs on *.rules files, which share the "ledger" filetype but aren't
  -- valid journals. Runs async like all nvim-lint linters.
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = "*.journal",
    callback = function() require("lint").try_lint("hledger") end
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
  -- hledger journals (filetype "ledger" set in filetypes.lua). Provides account/payee/
  -- commodity/tag/date completion (via blink.cmp), balance+syntax diagnostics, hover
  -- account balances, goto-def/find-refs/rename across includes.
  -- NOTE: formatting is intentionally handled by conform + hledger-fmt (see
  -- formatters_by_ft above), not the LSP. The LSP's whole-file formatting is
  -- synchronous and painfully slow on large journals, so we strip its
  -- formatting capabilities on attach to keep ,l=, formatexpr (gq), and
  -- format-on-save all routed through the fast rust formatter.
  vim.lsp.config.hledger_lsp = {
    cmd = { "hledger-lsp" },
    filetypes = { "ledger" },
    root_markers = { ".git", "*.journal" },
    single_file_support = true,
    on_attach = function(client, bufnr)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
      attached(client, bufnr)
      -- attached() only maps ,l= when the LSP advertises formatting (now off),
      -- so wire the manual format key straight to conform/hledger-fmt instead.
      require("pwnvim.mappings").makelocalmap(bufnr, require("pwnvim.mappings").mapleadern)("l=",
        function() require("conform").format({ async = true, lsp_format = "never" }) end, "Format file")
    end,
    capabilities = capabilities
  }
  vim.lsp.enable("hledger_lsp")
end -- Diagnostics setup
