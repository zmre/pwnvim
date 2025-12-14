-- Luacheck configuration for pwnvim
-- https://luacheck.readthedocs.io/en/stable/config.html

-- Neovim globals
globals = {
  "vim",
}

-- Read-only globals (set by flake.nix or plugins)
read_globals = {
  -- Injected by flake.nix
  "rustsrc_path",
  "prettier_path",
  "lldb_path_base",
  "rustanalyzer_path",
  -- Set by options.lua
  "SimpleUI",
  -- Plugins that expose globals
  "Snacks",
}

-- Don't warn about unused self arguments
self = false

-- Allow max line length of 120 (reasonable for modern screens)
max_line_length = 120

-- Ignore some common patterns
ignore = {
  "212", -- Unused argument (common in callbacks)
  "213", -- Unused loop variable
  "631", -- Line too long (we set max above, but allow some flexibility)
}

-- Files to exclude
exclude_files = {
  ".luacheckrc",
  "test/",  -- Test files may have different patterns
}

-- Neovim-specific standard library
std = "luajit+builtins"
