----------------------- REVIEW (lazy) ----------------------
-- review.nvim is an *opt* plugin (see optionalPlugins in flake.nix) because its
-- setup() unconditionally registers TabEnter + User CodeDiffOpen/CodeDiffFileSelect
-- hooks with no way to disable them, and those hooks break plain `:CodeDiff`.
-- So we define a stand-in `:Review` here and only packadd on first use.
--
-- To revert: move review-nvim back to requiredPlugins in flake.nix and put the
-- require("review").setup({...}) call below back into pwnvim/plugins/ui.lua.

-- Mirrors the subcommands defined in review.nvim's own plugin/review.lua so
-- completion still works before the plugin is loaded.
local subcommand_names = {
  "open", "commits", "close", "export", "preview", "sidekick", "clear", "list", "toggle",
}

vim.api.nvim_create_user_command("Review", function(opts)
  -- Sourcing plugin/review.lua redefines the `Review` command, replacing this
  -- stand-in, so the forwarding call below reaches the real implementation and
  -- later invocations skip this function entirely.
  vim.cmd("packadd review.nvim")

  if not vim.g.loaded_review then
    -- Guard against forwarding back into ourselves and recursing forever.
    vim.notify("review.nvim failed to load", vim.log.levels.ERROR, { title = "pwnvim" })
    return
  end

  require("review").setup({
    keymaps = {
      add_comment      = ",cc",
      add_note         = ",cn",
      add_suggestion   = ",cs",
      add_issue        = ",ci",
      add_praise       = ",cp",
      add_file_comment = ",cf",
      delete_comment   = ",cd",
      edit_comment     = ",ce",
    },
    codediff = {
      readonly = true,
    },
  })

  vim.cmd({ cmd = "Review", args = opts.fargs })
end, {
  nargs = "*",
  complete = function(arg_lead, cmd_line)
    local parts = vim.split(cmd_line, "%s+", { trimempty = true })
    if #parts <= 2 then
      return vim.tbl_filter(function(c)
        return c:find(arg_lead, 1, true) == 1
      end, subcommand_names)
    end
    return {}
  end,
  desc = "Review commands (loads review.nvim on first use)",
})
