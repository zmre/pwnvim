-- Luacheck configuration for pwnvim
-- https://luacheck.readthedocs.io/en/stable/config.html

-- Neovim globals
globals = {
  "vim",
  "SimpleUI", -- Set in options.lua, read everywhere else
}

-- Read-only globals (set by flake.nix or plugins)
read_globals = {
  -- Injected by flake.nix
  "vim",
  "rustsrc_path",
  "prettier_path",
  "lldb_path_base",
  "rustanalyzer_path",
  -- Plugins that expose globals
  "Snacks",
}

cache = true

-- Don't warn about unused self arguments
self = false

-- Allow max line length of 120 (reasonable for modern screens)
max_line_length = 120

-- Ignore some common patterns
ignore = {
  "211", -- Unused local variable (includes unused local functions)
  "212", -- Unused argument (common in callbacks)
  "213", -- Unused loop variable
  "311", -- Value assigned to local variable is unused
  "631", -- Line too long (we set max above, but allow some flexibility)
}

-- Files to exclude
exclude_files = {
  ".luacheckrc",
  "test/", -- Test files may have different patterns
  ".direnv/",
  "result/",
}

-- Neovim-specific standard library
--std = "luajit+builtins"
stds.nvim = {
  read_globals = { "jit" },
}
std = "lua51+nvim"
