local signs = require("pwnvim.signs")
-- Unfortunately, todo-comments is currently plaguing me with a nasty bug that has an unmerged fix for ages.
-- https://github.com/folke/todo-comments.nvim/pull/381
-- https://github.com/folke/todo-comments.nvim/issues/380
-- I might need to disable this plugin :(
require("todo-comments").setup {
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
  signs = false, -- show icons in the signs column
  keywords = {
    FIX = {
      icon = " ", -- icon used for the sign, and in search results
      color = "error", -- can be a hex color, or a named color (see below)
      alt = { "ERROR", "FIXME", "BUG", "FIXIT", "ISSUE", "!!!", "URGENT" }, -- a set of other keywords that all map to this FIX keywords
      -- signs = false, -- configure signs for some keywords individually
    },
    TODO = { icon = " ", color = "info", alt = { "PWTODO", "TK", "TODO" } },
    HACK = { icon = " ", color = "warning" },
    WARN = { icon = signs.warn, color = "warning", alt = { "WARNING", "XXX" } },
    PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
    NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
    TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
  },
  merge_keywords = true, -- when true, custom keywords will be merged with the defaults
  -- highlighting of the line containing the todo comment
  -- * before: highlights before the keyword (typically comment characters)
  -- * keyword: highlights of the keyword
  -- * after: highlights after the keyword (todo text)
  highlight = {
    multiline = false,
    before = "",               -- "fg" or "bg" or empty
    keyword = "wide",          -- "fg", "bg", "wide" or empty. (wide is the same as bg, but will also highlight surrounding characters)
    after = "fg",              -- "fg" or "bg" or empty
    pattern = [[<(KEYWORDS)]], -- pattern or table of patterns, used for highlightng (vim regex)
    -- override this to false in markdown files
    comments_only = true,      -- uses treesitter to match keywords in comments only
    max_line_len = 400,        -- ignore lines longer than this
    exclude = {},              -- list of file types to exclude highlighting
  },
  -- list of named colors where we try to extract the guifg from the
  -- list of hilight groups or use the hex color if hl not found as a fallback
  colors = {
    error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
    warning = { "DiagnosticWarning", "WarningMsg", "#FBBF24" },
    info = { "DiagnosticInfo", "#2563EB" },
    hint = { "DiagnosticHint", "#10B981" },
    default = { "Identifier", "#7C3AED" },
  },
  search = {
    command = "rg",
    args = {
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
    },
    -- regex that will be used to match keywords.
    -- don't replace the (KEYWORDS) placeholder
    pattern = [[\b(KEYWORDS)]], -- match without the extra colon. You'll likely get false positives
  },
}

-- todo-comments ships `:TodoTelescope` (see its plugin/todo.vim), which shells out to
-- `Telescope todo-comments todo`. We dropped telescope in favor of snacks, so that command is
-- dead on arrival (E492: Not an editor command: Telescope). Override it here to use the picker.
--
-- Two gotchas that dictate the implementation below:
--  1. todo-comments registers its snacks source as `Snacks.picker.sources.todo_comments`
--     (todo-comments/config.lua), but its own `todo-comments.snacks`.pick() asks for a source
--     named `todo`, which nothing ever registers. So we call the registered name directly
--     instead of using that helper.
--  2. The source's `search` expects `keywords` as a LIST, while the plugin's own `-nargs=*`
--     convention (`keywords=TODO,FIX`) is a comma separated STRING, so we split it.
--
-- This runs after `packadd todo-comments.nvim` at both call sites (pwnvim/options.lua and
-- pwnvim/markdown.lua), so plugin/todo.vim has already defined its version and ours replaces it.
local function todo_picker(args)
  -- todo-comments defers the guts of setup() to a timer when we're still starting up
  -- (config.lua checks v:vim_did_enter), and the picker source is only registered at the
  -- end of that deferred work. Without this, `nvim file.lua -c TodoTelescope` opens a
  -- picker with no finder and silently reports "No results found".
  local Config = require("todo-comments.config")
  if not Config.loaded then
    Config._setup()
  end

  local opts = {}
  local keywords = args and args:match("keywords=(%S*)")
  if keywords and keywords ~= "" then
    opts.keywords = vim.split(keywords, ",", { trimempty = true })
  end
  local cwd = args and args:match("cwd=(%S*)")
  if cwd and cwd ~= "" then
    opts.cwd = cwd
  end
  if Snacks and Snacks.picker then
    Snacks.picker.pick("todo_comments", opts)
  else
    -- Should not happen (snacks is a required plugin), but degrade to the quickfix list
    -- rather than throwing if the picker ever goes missing.
    vim.notify("snacks.picker unavailable; falling back to TodoQuickFix", vim.log.levels.WARN)
    require("todo-comments.search").setqflist(args)
  end
end

for _, name in ipairs({ "TodoTelescope", "TodoSnacks" }) do
  vim.api.nvim_create_user_command(name, function(o)
    todo_picker(o.args)
  end, {
    nargs = "*",
    desc = "Find todo comments with snacks picker (e.g. keywords=TODO,FIX)",
  })
end
