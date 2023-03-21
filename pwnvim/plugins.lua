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
  -- following options are the default
  -- each of these are documented in `:help nvim-tree.OPTION_NAME`
  -- local nvim_tree_config = require("nvim-tree.config")
  -- local tree_cb = nvim_tree_config.nvim_tree_callback
  require("pwnvim.plugins.nvim-tree")

  require("nvim-surround").setup({
    aliases = {
      ["e"] = "**" -- e for emphasis -- bold in markdown
    }
  })

  require("pwnvim.plugins.todo-comments")
  require("pwnvim.plugins.gitsigns")
  require("diffview").setup {}

  if not SimpleUI then require("colorizer").setup({}) end

  require("pwnvim.plugins.lualine")
  require("pwnvim.plugins.treesitter")
  require("pwnvim.plugins.bufferline")
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
  require "fidget".setup {} -- shows status of lsp clients as they issue updates
  vim.diagnostic.config({
    virtual_text = false,
    signs = { active = { signs.signs } },
    update_in_insert = true,
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
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { border = "rounded" })

  vim.lsp.handlers["textDocument/signatureHelp"] =
      vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

  require("trouble").setup {
    group = true, -- group results by file
    icons = true,
    auto_preview = true,
    signs = {
      error = signs.error,
      warning = signs.warn,
      hint = signs.hint,
      information = signs.info,
      other = "﫠"
    }
  }

  local function attached(client, bufnr)
    local function buf_set_keymap(...)
      vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    local opts = { noremap = true, silent = false }
    if client.name == "tsserver" or client.name == "jsonls" or client.name ==
        "nil" or client.name == "eslint" or client.name == "html" or
        client.name == "cssls" or client.name == "tailwindcss" then
      -- Most of these are being turned off because prettier handles the use case better
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    else
      client.server_capabilities.documentFormattingProvider = true
      client.server_capabilities.documentRangeFormattingProvider = true
      require("lsp-format").on_attach(client)
    end

    print("LSP attached " .. client.name)

    vim.api.nvim_buf_set_option(bufnr, "formatexpr",
      "v:lua.vim.lsp.formatexpr()")
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
    vim.api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.vim.lsp.tagfunc")

    local which_key = require("which-key")
    local local_leader_opts = {
      mode = "n",     -- NORMAL mode
      prefix = "<leader>",
      buffer = bufnr, -- Local mappings.
      silent = true,  -- use `silent` when creating keymaps
      noremap = true, -- use `noremap` when creating keymaps
      nowait = true   -- use `nowait` when creating keymaps
    }
    local local_leader_opts_visual = {
      mode = "v",     -- VISUAL mode
      prefix = "<leader>",
      buffer = bufnr, -- Local mappings.
      silent = true,  -- use `silent` when creating keymaps
      noremap = true, -- use `noremap` when creating keymaps
      nowait = true   -- use `nowait` when creating keymaps
    }

    require("symbols-outline").setup({
      keymaps = { close = { "<Esc>", "q", "#7" } }
    })

    local leader_mappings = {
      ["q"] = { "<cmd>TroubleToggle<CR>", "Show Trouble list" },
      l = {
        name = "Local LSP",
        s = { "<cmd>SymbolsOutline<CR>", "Show Symbols" },
        d = {
          "<Cmd>lua vim.lsp.buf.definition()<CR>", "Go to definition"
        },
        D = {
          "<cmd>lua vim.lsp.buf.implementation()<CR>",
          "Implementation"
        },
        i = { "<Cmd>lua vim.lsp.buf.hover()<CR>", "Info hover" },
        I = {
          "<Cmd>Telescope lsp_implementations<CR>", "Implementations"
        },
        r = { "<cmd>Telescope lsp_references<CR>", "References" },
        f = { "<cmd>Lspsaga code_action<CR>", "Fix Code Actions" },
        t = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature" },
        e = {
          "<cmd>lua vim.diagnostic.open_float()<CR>",
          "Show Line Diags"
        }
      },
      f = {
        ["sd"] = {
          "<cmd>Telescope lsp_document_symbols<CR>",
          "Find symbol in document"
        },
        ["sw"] = {
          "<cmd>Telescope lsp_workspace_symbols<CR>",
          "Find symbol in workspace"
        }
      }
    }
    which_key.register(leader_mappings, local_leader_opts)
    -- Create a new note after asking for its title.
    buf_set_keymap('', "#7", "<cmd>SymbolsOutline<CR>", opts)
    buf_set_keymap('!', "#7", "<cmd>SymbolsOutline<CR>", opts)
    buf_set_keymap('', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    -- override standard tag jump
    buf_set_keymap('', 'C-]', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('!', 'C-]', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)

    -- Set some keybinds conditional on server capabilities
    if client.server_capabilities.document_formatting then
      which_key.register({
        l = {
          ["="] = {
            "<cmd>lua vim.lsp.buf.formatting_sync()<CR>", "Format"
          }
        }
      }, local_leader_opts)
      -- vim.cmd([[
      --       augroup LspFormatting
      --           autocmd! * <buffer>
      --           autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
      --       augroup END
      --       ]])
    end
    if client.server_capabilities.implementation then
      which_key.register({
        l = {
          ["I"] = {
            "<cmd>Telescope lsp_implementations<CR>",
            "Implementations"
          }
        }
      }, local_leader_opts)
    end
    if client.server_capabilities.document_range_formatting then
      which_key.register({
        l = {
          ["="] = {
            "<cmd>lua vim.lsp.buf.range_formatting()<CR>",
            "Format Range"
          }
        }
      }, local_leader_opts_visual)
    end
    if client.server_capabilities.rename then
      which_key.register({
        l = { ["R"] = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" } }
      }, local_leader_opts)
    end
  end

  -- LSP stuff - minimal with defaults for now
  local null_ls = require("null-ls")

  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
  local formatting = null_ls.builtins.formatting
  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
  local diagnostics = null_ls.builtins.diagnostics
  local codeactions = null_ls.builtins.code_actions

  require("lsp-format").setup {}

  null_ls.setup {
    debug = false,
    sources = {
      -- formatting.lua_format,
      formatting.alejandra, -- for nix
      formatting.prismaFmt, -- for node prisma db orm
      formatting.prettier.with {

        -- extra_args = {
        --     "--use-tabs", "--single-quote", "--jsx-single-quote"
        -- },
        -- Disable markdown because formatting on save conflicts in weird ways
        -- with the taskwiki (roam-task) stuff.
        filetypes = {
          "javascript", "javascriptreact", "typescript",
          "typescriptreact", "vue", "scss", "less", "html", "css",
          "json", "jsonc", "yaml", "graphql", "handlebars", "svelte"
        },
        disabled_filetypes = { "markdown" }
      }, diagnostics.eslint_d.with {
      args = {
        "-f", "json", "--stdin", "--stdin-filename", "$FILENAME"
      }
    },                                                                -- diagnostics.vale,
      codeactions.eslint_d, codeactions.gitsigns, codeactions.statix, -- for nix
      diagnostics.statix,                                             -- for nix
      null_ls.builtins.hover.dictionary, codeactions.shellcheck,
      diagnostics.shellcheck
      -- removed formatting.rustfmt since rust_analyzer seems to do the same thing
    },
    on_attach = attached
  }
  local lspconfig = require("lspconfig")
  local cmp_nvim_lsp = require("cmp_nvim_lsp")

  local capabilities = vim.tbl_extend('keep', vim.lsp.protocol
    .make_client_capabilities(),
    cmp_nvim_lsp.default_capabilities());

  require('rust-tools').setup({
    server = {
      on_attach = attached,
      capabilities = capabilities,
      standalone = false
    },
    tools = {
      autoSetHints = true,
      inlay_hints = { auto = true, only_current_line = true },
      runnables = { use_telescope = true }
    }
  })
  require('crates').setup {}
  require('cmp-npm').setup({})
  lspconfig.tsserver.setup { capabilities = capabilities, on_attach = attached }
  lspconfig.lua_ls.setup {
    on_attach = attached,
    capabilities = capabilities,
    filetypes = { "lua" },
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = 'LuaJIT'
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = { 'vim', "string", "require" }
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = { enable = false },
        completion = { enable = true, callSnippet = "Replace" }
      }
    }
  }
  lspconfig.svelte.setup { on_attach = attached, capabilities = capabilities }
  lspconfig.tailwindcss.setup {
    on_attach = attached,
    capabilities = capabilities,
    settings = {
      files = { exclude = { "**/.git/**", "**/node_modules/**", "**/*.md" } }
    }
  }
  -- nil_ls is a nix lsp
  lspconfig.nil_ls.setup { on_attach = attached, capabilities = capabilities }
  lspconfig.cssls.setup {
    on_attach = attached,
    capabilities = capabilities,
    settings = { css = { lint = { unknownAtRules = "ignore" } } }
  }
  lspconfig.eslint.setup { on_attach = attached, capabilities = capabilities }
  lspconfig.html.setup { on_attach = attached, capabilities = capabilities }
  lspconfig.bashls.setup { on_attach = attached, capabilities = capabilities }
  -- TODO: investigate nvim-metals and remove line below
  lspconfig.metals.setup { on_attach = attached, capabilities = capabilities } -- for scala
  lspconfig.pylsp.setup { on_attach = attached, capabilities = capabilities }  -- for python
  lspconfig.jsonls.setup {
    on_attach = attached,
    settings = {
      json = {
        schemas = require('schemastore').json.schemas(),
        validate = { enable = true }
      }
    },
    setup = {
      commands = {
        Format = {
          function()
            vim.lsp.buf.range_formatting({}, { 0, 0 },
              { vim.fn.line "$", 0 })
          end
        }
      }
    },
    capabilities = capabilities
  }

  require 'lspsaga'.init_lsp_saga({
    use_saga_diagnostic_sign = not SimpleUI,
    use_diagnostic_virtual_text = false,
    code_action_prompt = {
      enable = true,
      sign = false,
      sign_priority = 20,
      virtual_text = true
    }
    -- TODO: re-enable this at next update - getting error 2022-08-02
    -- code_action_lightbulb = {
    --   enable = false,
    --   sign = true,
    --   enable_in_insert = true,
    --   sign_priority = 20,
    --   virtual_text = false,
    -- },
  })
end -- Diagnostics setup

----------------------- TELESCOPE --------------------------------
M.telescope = function()
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

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

  require('telescope').setup {
    file_ignore_patterns = {
      "*.bak", ".git/", "node_modules", ".zk/", "Caches/"
    },
    prompt_prefix = SimpleUI and ">" or " ",
    selection_caret = SimpleUI and "↪" or " ",
    -- path_display = { "smart" },
    defaults = {
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
          ["<C-y>"] = yank_selected_entry,
          ["<C-o>"] = system_open_selected_entry,
          ["<F10>"] = quicklook_selected_entry,
          ["q"] = require("telescope.actions").close
        },
        i = {
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
        path = '~/.local/share/nvim/databases/telescope_history.sqlite3',
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
      }
    }
  }
  require 'telescope'.load_extension('fzy_native')
  require("telescope").load_extension("zk")
  if vim.fn.has('mac') ~= 1 then
    -- doesn't currently work on mac
    require 'telescope'.load_extension('media_files')
  end
end -- telescope

----------------------- COMPLETIONS --------------------------------
-- cmp, luasnip
M.completions = function()
  require("luasnip/loaders/from_vscode").lazy_load()
  local luasnip = require("luasnip")
  local check_backspace = function()
    local col = vim.fn.col "." - 1
    return col == 0 or
        vim.fn.getline(vim.fn.line(".")):sub(col, col):match "%s"
  end
  local cmp = require 'cmp'
  cmp.setup {
    enabled = function()
      local context = require 'cmp.config.context'
      local buftype = vim.api.nvim_buf_get_option(0, "buftype")
      -- prevent completions in prompts like telescope prompt
      if buftype == "prompt" then return false end
      -- allow completions in command mode
      if vim.api.nvim_get_mode().mode == 'c' then return true end
      -- forbid completions in comments
      return not context.in_treesitter_capture("comment") and
          not context.in_syntax_group("Comment")
    end,
    mapping = {
      ['<C-p>'] = cmp.mapping.select_prev_item(),
      ['<C-n>'] = cmp.mapping.select_next_item(),
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete({}),
      ['<C-e>'] = cmp.mapping.close(),
      ['<CR>'] = cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Replace,
        select = false
      },
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expandable() then
          luasnip.expand({})
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
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
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" })
    },
    window = { documentation = cmp.config.window.bordered() },
    sources = {
      { name = 'nvim_lsp' }, { name = 'nvim_lsp_signature_help' },
      { name = 'nvim_lua' }, { name = 'emoji' }, { name = 'luasnip' },
      { name = 'path' }, { name = "crates" },
      { name = 'npm',    keyword_length = 3 },
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
          luasnip = "[Snippet]",
          buffer = "[Buffer]",
          path = "[Path]"
        })[entry.source.name]
        return vim_item
      end
    },
    snippet = { expand = function(args) luasnip.lsp_expand(args.body) end }
  }
  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = { { name = 'buffer' } }
  })
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({ { name = 'path' } }, {
      { name = 'cmdline', option = { ignore_cmds = { 'Man', '!' } } }
    })
  })
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
          print("ZK attached")

          local which_key = require("which-key")
          local local_leader_opts = {
            mode = "n",     -- NORMAL mode
            prefix = "<leader>",
            buffer = bufnr, -- Local mappings.
            silent = true,  -- use `silent` when creating keymaps
            noremap = true, -- use `noremap` when creating keymaps
            nowait = true   -- use `nowait` when creating keymaps
          }
          local local_leader_opts_visual = {
            mode = "v",     -- VISUAL mode
            prefix = "<leader>",
            buffer = bufnr, -- Local mappings.
            silent = true,  -- use `silent` when creating keymaps
            noremap = true, -- use `noremap` when creating keymaps
            nowait = true   -- use `nowait` when creating keymaps
          }

          local leader_mappings = {
            K = { "<Cmd>lua vim.lsp.buf.hover()<CR>", "Info preview" },
            n = {
              -- Create the note in the same directory as the current buffer after asking for title
              p = {
                "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>",
                "New peer note (same dir)"
              },
              l = { "<Cmd>ZkLinks<CR>", "Show note links" },
              -- the following duplicate with the ,l_ namespace on purpose because of programming muscle memory
              r = {
                "<cmd>Telescope lsp_references<CR>",
                "References to this note"
              }
            },
            l = {
              name = "Local LSP",
              -- Open notes linking to the current buffer.
              r = {
                "<cmd>Telescope lsp_references<CR>",
                "References to this note"
              },
              i = {
                "<Cmd>lua vim.lsp.buf.hover()<CR>",
                "Info preview"
              },
              f = {
                "<cmd>Lspsaga code_action<CR>",
                "Fix Code Actions"
              },
              e = {
                "<cmd>lua vim.diagnostic.open_float()<CR>",
                "Show Line Diags"
              }
            }
          }
          which_key.register(leader_mappings, local_leader_opts)
          local leader_mappings_visual = {
            n = {
              p = {
                ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>",
                "New peer note (same dir) selection for title"
              }
              -- Create a new note in the same directory as the current buffer, using the current selection for title.
            }
          }
          which_key.register(leader_mappings_visual,
            local_leader_opts_visual)

          local opts = { noremap = true, silent = true }

          -- TODO: Make <CR> magic...
          --   in normal mode, if on a link, it should open the link (note or url)
          --   in visual mode, it should prompt for folder, create a note, and make a link
          -- Meanwhile, just go to definition
          vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>",
            "<Cmd>lua vim.lsp.buf.definition()<CR>",
            opts)
          -- Preview a linked note.
          vim.api.nvim_buf_set_keymap(bufnr, "", "K",
            "<Cmd>lua vim.lsp.buf.hover()<CR>",
            opts)

          require('pwnvim.options').tabindent()
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
  require("true-zen").setup {
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
  }

  -- Grammar
  vim.g["grammarous#disabled_rules"] = {
    ['*'] = {
      'WHITESPACE_RULE', 'EN_QUOTES', 'ARROWS', 'SENTENCE_WHITESPACE',
      'WORD_CONTAINS_UNDERSCORE', 'COMMA_PARENTHESIS_WHITESPACE',
      'EN_UNPAIRED_BRACKETS', 'UPPERCASE_SENTENCE_START',
      'ENGLISH_WORD_REPEAT_BEGINNING_RULE', 'DASH_RULE', 'PLUS_MINUS',
      'PUNCTUATION_PARAGRAPH_END', 'MULTIPLICATION_SIGN', 'PRP_CHECKOUT',
      'CAN_CHECKOUT', 'SOME_OF_THE', 'DOUBLE_PUNCTUATION', 'HELL',
      'CURRENCY', 'POSSESSIVE_APOSTROPHE', 'ENGLISH_WORD_REPEAT_RULE',
      'NON_STANDARD_WORD'
    }
  }
  -- Grammar stuff
  vim.cmd(
    [[command StartGrammar2 lua require('pwnvim.plugins').grammar_check()]])
end -- notes

M.grammar_check = function()
  vim.cmd('packadd vim-grammarous')
  local opts = { noremap = false, silent = true }
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(0, ...) end

  buf_set_keymap('', '<leader>gf', '<Plug>(grammarous-fixit)', opts)
  buf_set_keymap('', '<leader>gx', '<Plug>(grammarous-remove-error)', opts)
  buf_set_keymap('', ']g', '<Plug>(grammarous-move-to-next-error)', opts)
  buf_set_keymap('', '[g', '<Plug>(grammarous-move-to-previous-error)', opts)
  vim.cmd('GrammarousCheck')
end

----------------------- MISC --------------------------------
-- rooter, kommentary, autopairs, tmux, toggleterm
M.misc = function()
  vim.g.lf_map_keys = 0 -- lf.vim disable default keymapping

  -- Change project directory using local cd only
  -- vim.g.rooter_cd_cmd = 'lcd'
  -- Look for these files/dirs as hints
  -- vim.g.rooter_patterns = {
  --     '.git', '_darcs', '.hg', '.bzr', '.svn', 'Makefile', 'package.json',
  --     '.zk', 'Cargo.toml', 'build.sbt', 'Package.swift', 'Makefile.in'
  -- }
  require('project_nvim').setup({
    active = true,
    on_config_done = nil,
    manual_mode = false,
    detection_methods = { "pattern", "lsp" },
    patterns = {
      ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json",
      ".zk", "build.sbt", "Package.swift", "Makefile.in", "README.md",
      "flake.nix"
    },
    show_hidden = false,
    silent_chdir = true,
    ignore_lsp = {}
  })
  require('telescope').load_extension('projects')

  require('Comment').setup()
  require("which-key").register({
    ["<leader>c<space>"] = {
      '<Plug>(comment_toggle_linewise_current)', "Toggle comments"
    },
    ["g/"] = { '<Plug>(comment_toggle_linewise_current)', "Toggle comments" }
  }, { mode = "n", silent = true, norewrap = true })
  require("which-key").register({
    ["<leader>c<space>"] = {
      '<Plug>(comment_toggle_linewise_visual)', "Toggle comments"
    },
    ["g/"] = { '<Plug>(comment_toggle_linewise_visual)', "Toggle comments" }
  }, { mode = "v", silent = true, norewrap = true })

  require('nvim-autopairs').setup({})

  vim.g.tmux_navigator_no_mappings = 1

  require("toggleterm").setup {
    open_mapping = [[<c-\>]],
    insert_mappings = true, -- from normal or insert mode
    start_in_insert = true,
    hide_numbers = true,
    direction = 'vertical',
    size = function(_) return vim.o.columns * 0.3 end,
    close_on_exit = true
  }
  vim.api.nvim_set_keymap('t', [[<C-\]], "<Cmd>ToggleTermToggleAll<cr>",
    { noremap = true })
end -- misc

return M
