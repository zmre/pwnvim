# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pwnvim is a Nix flake-based, portable Neovim configuration. All plugins and dependencies are declared in `flake.nix` and managed through Nix, ensuring reproducible builds across machines. The configuration is self-contained and doesn't rely on `~/.config/nvim`.

## Build Commands

```bash
# Run directly from GitHub (ephemeral)
nix run github:zmre/pwnvim

# Build locally (creates ./result symlink)
nix build

# Development shell with all dependencies
nix develop

# Update dependencies, build, push to cachix, and show diff
./update.sh
```

### Package Variants
- **pwnvim** (default): Standard config without Python
- **pwnvim-python**: Includes Python3, Jupyter/molten-nvim, and image rendering

## CI/Testing

GitHub Actions runs on push/PR to main:
- Builds on both `ubuntu-latest` and `macos-latest`
- Uses cachix for binary caching (zmre cache)
- No automated Neovim-specific tests currently exist (see README TODO)

## Architecture

### Entry Point Flow
`flake.nix` → `init.lua` → loads modules in order:
1. `pwnvim/filetypes.lua` - Filetype detection, autocmds for programming mode
2. `pwnvim/options.lua` - Vim settings, colorschemes (catppuccin/onedark), Neovide GUI config
3. `pwnvim/mappings.lua` - All keybindings (leader is `,`)
4. `pwnvim/abbreviations.lua` - Text abbreviations
5. `pwnvim/plugins.lua` - Plugin configurations organized as:
   - `M.ui()` - File tree (oil.nvim), git signs, status line, breadcrumbs
   - `M.diagnostics()` - LSP, formatters (conform.nvim), linters (nvim-lint)
   - `M.picker()` - Fuzzy finder via snacks.picker
   - `M.completions()` - blink.cmp completion engine
   - `M.llms()` - CodeCompanion AI integration
   - `M.notes()` - Zettelkasten/zk, grammar checking
   - `M.misc()` - Autopairs, yazi file manager
   - snacks.nvim features: dashboard, bigfile, quickfile, bufdelete, indent, scroll, terminal, zen, gitbrowse, gh

### Key Patterns

**Dependencies in flake.nix**: All external tools (LSPs, formatters, linters) are declared in the `dependencies` list and made available via `extraMakeWrapperArgs` PATH prefix.

**Plugin Management**: Plugins split into `requiredPlugins` (always loaded) and `optionalPlugins` (lazy-loaded via `packadd`).

**SimpleUI Mode**: Detects limited terminals (`SIMPLEUI=1`, Apple Terminal, linux console) and falls back to 16-color ir_black theme without nerd fonts.

**Paths injected from Nix**: `flake.nix` injects paths as Lua globals in `customRC`:
- `rustsrc_path` - Rust library source for rust-analyzer
- `prettier_path` - Prettier binary
- `lldb_path_base` - LLDB debugger for Rust DAP
- `rustanalyzer_path` - rust-analyzer binary

### Language Support

Full IDE experience for: Rust, TypeScript/Svelte, Nix, Lua, Python, Markdown/Zettelkasten

Key LSP configs in `plugins.lua` under `M.diagnostics()`:
- Rust: rustaceanvim with rust-analyzer, clippy, lldb debugging
- TypeScript: ts_ls + eslint_d + prettier
- Nix: nixd + alejandra formatter + statix linter
- Python: pyright + black + mypy/ruff

### Notable Files

- `pwnvim/markdown.lua` - Custom markdown features: fold expressions, URL title fetching, daily/meeting notes, zk integration
- `pwnvim/signs.lua` - Diagnostic sign configuration
- `cheatsheet.md` - Comprehensive keybinding reference

## Key Bindings

Leader key: `,` (comma). Press and wait for which-key popup.

Common prefixes:
- `,f` - Fuzzy finding (snacks.picker)
- `,l` - LSP operations
- `,g` - Git operations (gs=status, gb=branches, gm=commits, gB=browse, gi=issues, gp=PRs)
- `,n` - Notes/writing
- `,r` - Rust-specific commands
- `,d` - Debugging (DAP)
- `Ctrl-\` or `Ctrl-'` - Toggle terminal (snacks.terminal)

Function keys: F2 (file browser), F3 (grep), F7 (outline), F9 (zen mode)
