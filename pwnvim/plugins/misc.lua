----------------------- MISC --------------------------------
-- autopairs, matchup, yazi, tmux-navigator, lf

return function()
  vim.g.lf_map_keys = 0              -- lf.vim disable default keymapping
  vim.g.matchup_surround_enabled = 0 -- disallows ds type selections
  vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  vim.g.matchup_matchparen_deferred = 1
  vim.g.matchup_motion_override_Npercent = 100
  vim.g.matchup_text_obj_linewise_operators = { 'd', 'y', 'c', 'v' }

  require("nvim-autopairs").setup({
    check_ts = true
  })

  vim.g.tmux_navigator_no_mappings = 1


  require("yazi").setup({
    open_for_directories = false
  })
end -- misc
