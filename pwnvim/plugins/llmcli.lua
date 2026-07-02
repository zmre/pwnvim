----------------------- SIDEKICK (AI CLI) --------------------------------

return function()
  require("sidekick").setup({
    nes = { enabled = false },
    cli = {
      watch = true,
      mux = { backend = "tmux", enabled = false },
      win = { layout = "right", split = { width = 90 } },
      tools = {
        iris = {
          cmd = { "iris" },
          is_proc = "\\<iris\\>",
          resume = { "--resume" },
          continue = { "--continue" },
        },
      },
    },
  })
end
