----------------------- OUTLINE ----------------------------
-- Symbol / table-of-contents drawer bound to <F7>.
--
-- The main reason this exists alongside nvim-navbuddy: the zk LSP used for
-- markdown does not implement textDocument/documentSymbol, so navbuddy has
-- nothing to show in notes. outline.nvim ships its own non-LSP markdown
-- provider that walks the headings directly, so markdown gets a real outline
-- while code files keep using LSP symbols.

require("outline").setup({
  outline_window = {
    position = "right",
    width = 25,
    relative_width = true, -- width above is a percentage of total columns
    auto_close = true,     -- picking a heading jumps to it and closes the drawer
    show_numbers = false,
    show_relative_numbers = false,
  },
  outline_items = {
    -- For markdown headings the detail column is just noise
    show_symbol_details = false,
  },
  symbol_folding = {
    -- Default is 1, which collapses a markdown doc down to just its H1s -- not
    -- much of a table of contents. false disables autofolding entirely so the
    -- whole heading tree is visible on open; h/l/<tab> still fold manually.
    autofold_depth = false,
    -- Default markers are nerd font glyphs, so fall back to ascii in SimpleUI.
    -- nil leaves the key unset so the plugin's own defaults apply.
    markers = SimpleUI and { "+", "-" } or nil,
  },
  keymaps = {
    -- Mirrors the trouble config: whatever opened it can also close it
    close = { "<Esc>", "q", "<F7>" },
  },
  providers = {
    -- lsp first so code files still get real symbols; markdown provider is the
    -- fallback that makes notes work with no LSP at all
    priority = { "lsp", "markdown", "man" },
  },
  symbols = {
    -- The markdown provider emits every heading as kind 15 (String -- see
    -- lua/outline/providers/markdown.lua). Listing it here as an inclusive
    -- filter for markdown documents that headings must never be filtered out.
    -- (outline.nvim's config.should_include_symbol also short-circuits to true
    -- for ft=markdown, so this is belt and braces.) No `default` key means all
    -- kinds continue to show for every other filetype.
    filter = { markdown = { "String" } },
    -- icon_source only understands "lspkind", so icons are suppressed by way of
    -- a fetcher that returns an empty string (icon_from_kind honors "").
    icon_fetcher = SimpleUI and function() return "" end or nil,
  },
})
