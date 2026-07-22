----------------------- NOTES --------------------------------
-- zk (zettelkasten lsp), render-markdown, grammar settings

return function()
  -- render-markdown: one-time setup (not per-buffer) to avoid nil config
  -- errors when snacks picker previews markdown files
  vim.cmd('packadd render-markdown.nvim')
  require('render-markdown').setup({
    file_types = { 'markdown', 'codecompanion', 'AgenticChat' },
    completions = { lsp = { enabled = false } },
    render_modes = { 'n', 'c', 't' },
    anti_conceal = { enabled = true },
    -- Don't hide HTML comments (<!-- ... -->); leave them visible and syntax-colored
    html = { comment = { conceal = false } },
  })

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
        cmd = { zk_path, "lsp" },
        on_attach = function(client, bufnr)
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
          if client.server_capabilities.implementationProvider then
            mapleadernlocal("lD", function() Snacks.picker.lsp_implementations() end, "Implementation")
          end
          if client.server_capabilities.definitionProvider or client.server_capabilities.typeDefinitionProvider then
            mapleadernlocal("ld", function() Snacks.picker.lsp_definitions() end, "Go to definition")
            -- override standard tag jump c-] for go to definition
            mapnlocal("<c-]>", function() Snacks.picker.lsp_definitions() end, "Go to definition")
          end

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
