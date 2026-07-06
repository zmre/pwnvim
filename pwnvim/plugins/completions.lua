----------------------- COMPLETIONS --------------------------------
-- blink.cmp completion engine

-- Percent-encode everything outside RFC 3986 unreserved chars (plus '/') so
-- completed markdown link destinations are valid strict CommonMark even with
-- spaces, parens, or '#' in file names. gf decodes these (markdown.resolveMdLink).
-- Hand-rolled because vim.uri_encode leaves parens and '#' unencoded; decode
-- side uses the vim.uri_decode builtin
local function urlencode(str)
  return (str:gsub("[^%w%-%._~/]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

return function()
  -- blink resolves the typed path portion literally when scanning for
  -- candidates, so '](/my%20docs/' would scan a nonexistent dir. blink has no
  -- hook there; wrap the cached module's dirname to decode in markdown buffers
  local pathlib = require('blink.cmp.sources.path.lib')
  if not pathlib._pwnvim_wrapped then
    pathlib._pwnvim_wrapped = true
    local blink_dirname = pathlib.dirname
    pathlib.dirname = function(opts, ctx)
      local dirname = blink_dirname(opts, ctx)
      if dirname and vim.bo[ctx.bufnr].filetype == 'markdown' then
        return vim.uri_decode(dirname)
      end
      return dirname
    end
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
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      per_filetype = {
        -- markdown swaps 'path' for 'repo_path' so typing /folder completes
        -- from the repo root rather than the filesystem root
        markdown = { inherit_defaults = false, 'lsp', 'repo_path', 'snippets', 'buffer' },
      },
      providers = {
        repo_path = {
          module = 'blink.cmp.sources.path',
          name = 'Path',
          score_offset = 3, -- same as the stock path provider
          opts = {
            ignore_root_slash = true,
            get_cwd = function(ctx)
              -- memoized per buffer: vim.fs.root walks the filesystem upward
              -- and this runs on each '/' typed, which hitches on iCloud dirs
              local root = vim.b[ctx.bufnr].pwnvim_repo_root
              if root == nil then
                root = vim.fs.root(ctx.bufnr, require('pwnvim.markdown').root_markers)
                vim.b[ctx.bufnr].pwnvim_repo_root = root
              end
              return root or vim.fn.expand(('#%d:p:h'):format(ctx.bufnr))
            end,
          },
          -- insert url-encoded names (label stays readable for fuzzy matching)
          transform_items = function(_, items)
            for _, item in ipairs(items) do
              if item.insertText then item.insertText = urlencode(item.insertText) end
              if item.textEdit then item.textEdit.newText = urlencode(item.textEdit.newText) end
            end
            return items
          end,
        },
      },
    },
  })
end -- completions
