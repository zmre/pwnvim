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

-- Repo root for a buffer, falling back to the buffer's dir. Memoized per
-- buffer: vim.fs.root walks the filesystem upward and this runs on each '/'
-- typed, which hitches on iCloud dirs
local function repo_root(ctx)
  local root = vim.b[ctx.bufnr].pwnvim_repo_root
  if root == nil then
    root = vim.fs.root(ctx.bufnr, require('pwnvim.markdown').root_markers) or false
    vim.b[ctx.bufnr].pwnvim_repo_root = root
  end
  return root or vim.fn.expand(('#%d:p:h'):format(ctx.bufnr))
end

return function()
  -- Markdown path completion (repo_path provider) wraps blink's cached
  -- path lib dirname for two reasons blink has no hooks for:
  --  * './' and '../' resolve from the buffer's dir (blink default get_cwd)
  --    while a root-anchored '/' resolves from the repo root rather than the
  --    filesystem root. blink uses a single get_cwd for both, so swap it here
  --  * blink resolves the typed path literally, so '](/my%20docs/' would scan
  --    a nonexistent dir; uri-decode the result
  local pathlib = require('blink.cmp.sources.path.lib')
  if not pathlib._pwnvim_wrapped then
    pathlib._pwnvim_wrapped = true
    local blink_dirname = pathlib.dirname
    local regex = require('blink.cmp.sources.path.regex')
    pathlib.dirname = function(opts, ctx)
      if vim.bo[ctx.bufnr].filetype ~= 'markdown' then
        return blink_dirname(opts, ctx)
      end
      if opts.ignore_root_slash then
        -- same prefix computation as blink's lib.dirname
        local line = ctx.line:sub(1, ctx.bounds.start_col - (ctx.bounds.length == 0 and 1 or 0))
        local s = regex.PATH:match_str(line)
        local prefix = s and line:sub(1, s + 1) or ''
        if prefix:match('/$') and not prefix:match('%./$') and not prefix:match('~/$') then
          opts = vim.tbl_extend('force', opts, { get_cwd = repo_root })
        end
      end
      local dirname = blink_dirname(opts, ctx)
      return dirname and vim.uri_decode(dirname)
    end
  end

  require("blink.cmp").setup({
    keymap = {
      preset = 'super-tab',
      ['<C-k>'] = false, -- preset binds signature help here; insert-mode <c-k> is cursor up (see mappings.lua)
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
        -- markdown swaps 'path' for 'repo_path': ./ completes from the file's
        -- dir, /folder from the repo root rather than the filesystem root
        markdown = { inherit_defaults = false, 'lsp', 'repo_path', 'snippets', 'buffer' },
      },
      providers = {
        repo_path = {
          module = 'blink.cmp.sources.path',
          name = 'Path',
          score_offset = 3, -- same as the stock path provider
          opts = {
            ignore_root_slash = true,
            -- get_cwd left at blink's default (buffer dir) for './'; the
            -- dirname wrapper above swaps in repo_root for root-anchored '/'
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
