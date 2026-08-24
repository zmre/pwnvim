{
  description = "PW's Neovim (pwnvim) Configuration";
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://zmre.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "zmre.cachix.org-1:WIE1U2a16UyaUVr+Wind0JM6pEXBe43PQezdPKoDWLE="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      # Needed along with default.nix in root to allow nixd lsp to do completions
      # See: https://github.com/nix-community/nixd/tree/main/docs/examples/flake
      url = "github:inclyc/flake-compat";
      flake = false;
    };
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    # ekickx doesn't seem to be maintaing. postfen's fork worth using for now. TODO: revisit
    clipboard-image.url = "github:postfen/clipboard-image.nvim";
    clipboard-image.flake = false;
    # TODO: Remove after https://github.com/folke/todo-comments.nvim/pull/381 is merged
    todo-comments-nvim.url = "github:belltoy/todo-comments.nvim/main";
    todo-comments-nvim.flake = false;
    mbr.url = "github:zmre/mbr-markdown-browser";
    mbr.inputs.nixpkgs.follows = "nixpkgs";
    # keep mbr's rust-overlay from dragging a second, stale nixpkgs into the closure
    mbr.inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # nvim-treesitter-textobjects main branch for treesitter 1.0 compatibility
    nvim-treesitter-textobjects.url = "github:nvim-treesitter/nvim-treesitter-textobjects/main";
    nvim-treesitter-textobjects.flake = false;
    mermaid-rust-cli.url = "github:1jehuang/mermaid-rs-renderer/v0.2.1";
    mermaid-rust-cli.flake = false;
    sidekick-nvim.url = "github:folke/sidekick.nvim";
    sidekick-nvim.flake = false;
    # ACP-based AI chat sidebar (Claude/Codex/Gemini/OpenCode). Not in nixpkgs.
    agentic-nvim.url = "github:carlos-algms/agentic.nvim";
    agentic-nvim.flake = false;
    # which-key hints for nvim-surround targets (not in nixpkgs)
    nvim-surround-wk.url = "github:gregorias/nvim-surround-wk";
    nvim-surround-wk.flake = false;
    # LSP for hledger/ledger journals (account/payee completion, diagnostics, formatting)
    hledger-lsp.url = "github:juev/hledger-lsp";
    hledger-lsp.flake = false;
    # TODO: Remove once https://github.com/zk-org/zk/pull/745 is merged & released.
    # Builds zk from the PR branch so absolute (leading-slash) links resolve against
    # the notebook root instead of reporting bogus broken-link diagnostics.
    zk-src.url = "github:zmre/zk/fix/notebook-root-links";
    zk-src.flake = false;
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {allowUnfree = true;};
        overlays = [
          (self: super: {
            languagetool = super.languagetool.overrideAttrs (old: rec {
              version = "5.9"; # grammarous doesn't support 6+
              src = super.fetchzip {
                url = "https://www.languagetool.org/download/${old.pname}-${version}.zip";
                sha256 = "sha256-x4xGgYeMi7KbD2WGHOd/ixmZ+5EY5g6CLd7/CBYldNQ=";
              };
            });
            mermaid-cli = super.rustPlatform.buildRustPackage {
              pname = "mermaid-cli";
              name = "mermaid-cli";
              src = inputs.mermaid-rust-cli;
              cargoLock = {lockFile = "${inputs.mermaid-rust-cli}/Cargo.lock";};
              postInstall = ''
                ln -s $out/bin/mmdr $out/bin/mmdc
              '';
            };
            # TODO: Remove once https://github.com/zk-org/zk/pull/745 is merged & released.
            # Override zk with the PR branch (see zk-src input) so leading-slash links
            # resolve against the notebook root and stop emitting bogus broken-link errors.
            zk = super.zk.overrideAttrs (old: {
              version = "0.15.5-pr745";
              src = inputs.zk-src;
              vendorHash = "sha256-s22y/m09UBW5zqIIC0gWg7XX6166x/BR0Z0Tp5B74fk=";
            });
            # hledger-lsp isn't in nixpkgs (as of this writing); build from source.
            # NOTE: if `nix eval nixpkgs#hledger-lsp` resolves, delete this and just add
            # `hledger-lsp` to the dependencies list below instead.
            hledger-lsp = super.buildGoModule {
              pname = "hledger-lsp";
              version = "unstable";
              src = inputs.hledger-lsp;
              vendorHash = "sha256-imF6wCMC+5J94TQjZU0SXOwlw5SR/EB60GeYVS3O/iA=";
              subPackages = ["cmd/hledger-lsp"];
            };
          })
          (self: super: {
            vimPlugins =
              super.vimPlugins
              // {
                clipboard-image = super.vimUtils.buildVimPlugin {
                  name = "clipboard-image.nvim";
                  pname = "clipboard-image.nvim";
                  src = inputs.clipboard-image;
                };
                # TODO: Remove after https://github.com/folke/todo-comments.nvim/pull/381 is merged
                todo-comments-nvim = super.vimUtils.buildVimPlugin {
                  name = "todo-comments.nvim";
                  pname = "todo-comments.nvim";
                  src = inputs.todo-comments-nvim;
                  nvimSkipModule = [
                    "todo-comments.fzf"
                    "trouble.providers.todo"
                    "trouble.sources.todo"
                  ];
                };
                # Use main branch for nvim-treesitter 1.0 compatibility
                nvim-treesitter-textobjects = super.vimUtils.buildVimPlugin {
                  name = "nvim-treesitter-textobjects";
                  pname = "nvim-treesitter-textobjects";
                  src = inputs.nvim-treesitter-textobjects;
                };
                sidekick-nvim = super.vimUtils.buildVimPlugin {
                  name = "sidekick.nvim";
                  pname = "sidekick.nvim";
                  src = inputs.sidekick-nvim;
                  nvimSkipModule = [
                    "sidekick.docs"
                  ];
                };
                nvim-surround-wk = super.vimUtils.buildVimPlugin {
                  name = "nvim-surround-wk";
                  pname = "nvim-surround-wk";
                  src = inputs.nvim-surround-wk;
                  dependencies = [
                    super.vimPlugins.nvim-surround
                    super.vimPlugins.which-key-nvim
                  ];
                };
                # ACP AI chat sidebar; ACP connector CLIs are added to dependencies below.
                agentic-nvim = super.vimUtils.buildVimPlugin {
                  name = "agentic.nvim";
                  pname = "agentic.nvim";
                  src = inputs.agentic-nvim;
                };
              };
          })
        ];
      };

      dependencies = with pkgs;
        [
          fd
          ripgrep
          fzy
          zoxide
          bat # syntax-highlighting pager; no plugin uses it now (snacks previews in-editor)
          gh
          zk # lsp for markdown notes in zk folders
          #markdown-oxide # lsp for any markdown
          # marksman requires .NET and Swift to be built, which sucks
          #marksman # lsp for any markdown
          zsh # terminal requires it
          git
          curl # needed to fetch titles from urls
          # todo: research https://github.com/artempyanykh/marksman
          vale # linter for prose
          proselint # ditto
          luaformatter # ditto for lua
          luajitPackages.luacheck # linter for lua
          #prisma-engines # ditto for schema.prisma files # TODO: bring back when rust compile issues are fixed 2024-08-26
          # Nix language servers summary 2023-11-23
          # rnix-lsp -- seems abandoned
          # nil -- way better than rnix and generally great, but
          nixd # -- damn good at completions referencing back to nixpkgs, for example
          #         at least provided you do some weird gymnastics in flakes:
          #         https://github.com/nix-community/nixd/blob/main/docs/user-guide.md#faq
          #         using this one for now
          #nixfmt # nix formatter
          alejandra # better nix formatter alternative
          statix # linter for nix
          shellcheck
          languagetool # needed by grammarous, but must be v5.9 (see overlay)
          # luajitPackages.lua-lsp
          lua-language-server
          pyright # python lsp (written in node? so weird)
          vscode-langservers-extracted # lsp servers for json, html, css, eslint
          lazygit
          mermaid-cli # when mmdc is in the path, snacks previews mermaid diagrams. WARN: we aren't using standard mmdc (which needs chrome) but a rust alternative, mermaid-rs-renderer
          tectonic # when tectonic is installed, snacks will inline preview math
          eslint_d # js/ts code formatter and linter
          prettier # ditto
          #prisma # dependency prisma-engines not compiling right now 2024-08-26
          svelte-language-server
          diagnostic-languageserver
          typescript-language-server
          bash-language-server
          tailwindcss-language-server
          #nodePackages_latest.grammarly-languageserver # besides being a privacy issue if triggered, we have these issues:
          # https://github.com/znck/grammarly/issues/411 grammarly sdk deprecated
          # https://github.com/NixOS/nixpkgs/issues/293172 requires node16, which is EOL
          yaml-language-server
          # jinja-lsp # jinja is an html template language; i'm using zola right now which uses the tera language, which is a lot like jinja
          mypy # static typing for python used by null-ls
          ruff # python linter used by null-ls
          black # python formatter
          rust-analyzer # lsp for rust
          clippy
          # rust-analyzer is currently in a partially broken state as it cannot find rust sources so can't
          # help with native language things, which sucks. Here are some issues to track:
          # https://github.com/rust-lang/rust/issues/95736 - FIXED
          # https://github.com/rust-lang/rust-analyzer/issues/13393 - CLOSED NOT RESOLVED
          # https://github.com/mozilla/nixpkgs-mozilla/issues/238
          #                     - suggestion to do export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src" which is like what we're doing below in customRC, I think
          # https://github.com/rust-lang/cargo/issues/10096
          rustfmt
          cargo # have this as a fallback when a local flake isn't in place
          rustc # have this as a fallback when a local flake isn't in place
          vscode-extensions.vadimcn.vscode-lldb.adapter # for debugging rust
          (python3.withPackages (ps: with ps; [debugpy])) # required for debugging python, but better if that's per project installed since we don't have python

          tree-sitter
          hledger # plain-text accounting CLI; `hledger check` runs on save as a linter (nvim-lint)
          hledger-lsp # lsp for hledger/ledger journals
          hledger-fmt # fast (rust) formatter for hledger/ledger journals (used by conform)
          metals # lsp for scala
          yazi # my alt file manager triggered with ,-
          imagemagick # for image previews
          ghostscript # also for image previews

          inputs.mbr.packages.${system}.mbr-cli

          # ACP connector CLIs for agentic.nvim (matched to acp_providers in
          # pwnvim/plugins/agentic.lua). All resolve from nixpkgs.
          claude-agent-acp # provider "claude-agent-acp" -> `claude-agent-acp`
          codex-acp # provider "codex-acp" -> `codex-acp` (OpenAI)
          #gemini-cli # provider "gemini-acp" -> `gemini --acp` ... TODO: they've replaced gemini with antigravity-cli which isn't yet supported here; revisit
          opencode # provider "opencode-acp" -> `opencode acp`
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          ueberzug
          xclip # needed by vim clipboard-image plugin
          wl-clipboard # needed by vim clipboard-image plugin
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin
        [pngpaste]; # needed by vim clipboard-image plugin

      # 2026-03-02 need to add path to vim to see ts grammars
      grammarsPath = pkgs.symlinkJoin {
        name = "nvim-treesitter-grammars";
        paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
      };

      customRC =
        ''
          lua << EOF
            package.path = "${self}/?.lua;" .. package.path
            prettier_path = "${pkgs.prettier}/bin/prettier"
            zk_path = "${pkgs.zk}/bin/zk"
            lldb_path_base = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}"
            treesitter_grammars_path = "${grammarsPath}"
            rustanalyzer_path = "${pkgs.rust-analyzer}/bin/rust-analyzer"
            vim.g.loaded_python3_provider = 0
        ''
        + pkgs.lib.readFile ./init.lua
        + ''
          EOF
        '';

      requiredPlugins = with pkgs.vimPlugins; [
        # Common dependencies of other plugins
        popup-nvim # dependency of some other plugins
        plenary-nvim # Library for lua plugins; used by many plugins here

        # Syntax / Language Support ##########################
        rustaceanvim # lsp stuff and more for rust; replaces rust-tools-nvim which is now archived
        nvim-lspconfig # setup LSP for intelligent coding
        nvim-lint # replace null-ls for linting bits
        conform-nvim # replace null-ls and lsp-format-nvim for formatting
        trouble-nvim # navigate all warnings and errors in quickfix-like window
        nvim-dap # debugging functionality used by rust-tools-nvim
        nvim-dap-ui # ui for debugging
        nvim-dap-python
        nvim-nio # needed by dap-ui
        neotest
        neotest-rust
        neodev-nvim # help for neovim lua api
        SchemaStore-nvim # json schemas
        vim-matchup # replaces built-in matchit and matchparen with better matching and faster

        # UI #################################################
        onedarkpro-nvim # colorscheme
        catppuccin-nvim # colorscheme
        ir_black # colorscheme for basic terminals
        snacks-nvim # folke's swiss army knife - using for picker (replaces telescope)
        dressing-nvim # dresses up vim.ui.input (snacks handles vim.ui.select)
        nvim-colorizer-lua # color over CSS like #00ff00
        nvim-web-devicons # makes things pretty; used by many plugins below
        oil-nvim # file navigator
        gitsigns-nvim # git status in gutter
        lualine-nvim # nice status bar at bottom ; TODO 2025-06-09 time to find an alternative? tons of undealt with deprecations
        dropbar-nvim # replacing the now archived barbecue (sad!)
        nvim-navbuddy # use same lsp symbols to navigate in popup
        outline-nvim # symbol/TOC drawer; has a native markdown provider so it gives an outline without an LSP
        nvim-ufo # allow use of lsp as source for folding
        promise-async # required by nvim-ufo
        nvim-treesitter-textobjects # jump around and select based on syntax (class, function, etc.)
        lf-vim
        nui-nvim # needed by noice
        nvim-notify # needed by noice
        noice-nvim # show progress and add other UI improvements
        marks-nvim # show marks in the gutter
        yazi-nvim # another file manager which i've started using; not replacing oil yet so side by side for now

        # Editor Features ####################################
        vim-abolish # better abbreviations / spelling fixer
        nvim-surround # .... updated lua-based alternative to tpope's surround
        nvim-surround-wk # which-key hints for surround targets when you forget the keys
        vim-unimpaired # bunch of convenient navigation key mappings
        vim-repeat # supports all of the above so you can use .
        vim-eunuch # brings cp/mv type commands. :Rename and :Move are particularly handy
        vim-speeddating # allows ctrl-x and ctrl-a to increment/decrement dates
        flash-nvim

        # Autocompletion
        blink-cmp
        codecompanion-nvim # llm access in context; TODO 2025-06-09 find an alternative? riddled with deprecated function calls
        sidekick-nvim # AI CLI launcher (claude, iris, codex, gemini, etc.) - NES disabled
        agentic-nvim # ACP AI chat sidebar (claude/codex/gemini/opencode)
        nvim-autopairs # balances parens as you type
        nvim-ts-autotag # balance or rename html
        vim-emoji # TODO: redundant now?

        # writing
        zk-nvim # lsp for a folder of notes for searching/linking/etc.

        # Misc
        vim-fugitive # git management
        codediff-nvim # side-by-side diff renderer; also the review flow's UI (:CodeDiff, see pwnvim/plugins/review.lua)
        vim-tmux-navigator # navigate vim and tmux panes together
        impatient-nvim # speeds startup times by caching lua bytecode
        which-key-nvim
        vim-startuptime

        # Something was obliterating rtp and making grammars disappear. Putting this on the bottom of the list
        # fixes the issue for me 2024-09-10.
        nvim-treesitter.withAllGrammars
      ];
      optionalPlugins = with pkgs.vimPlugins; [
        # grammar check
        vim-grammarous
        direnv-vim # auto-execute nix direnv setups -- currently my slowest plugin; enabled by programming filetype
        clipboard-image # only loaded in markdown files
        comment-nvim # code commenter
        crates-nvim # inline intelligence for Cargo.toml
        todo-comments-nvim # highlight comments like NOTE
        render-markdown-nvim # prettier markdown files
      ];
    in rec {
      # Validation checks for the configuration
      checks.default =
        pkgs.runCommand "pwnvim-check" {
          nativeBuildInputs = [
            packages.pwnvim
            pkgs.luajitPackages.luacheck
          ];
          src = self;
        } ''
          cd $src
          echo "Running luacheck..."
          # --no-cache: the sandbox has no writable HOME for luacheck's cache
          luacheck . --no-color --no-cache

          echo "Testing neovim startup..."
          # io.stdout:write, not print: noice.nvim swallows print output when loaded
          nvim --headless -c "lua vim.defer_fn(function() io.stdout:write('STARTUP_OK\n') vim.cmd('qa!') end, 100)" 2>&1 | grep -q "STARTUP_OK" || (echo "Startup test failed"; exit 1)

          echo "All checks passed"
          touch $out
        '';

      packages.pwnvim = (pkgs.wrapNeovim pkgs.neovim-unwrapped {
          viAlias = true;
          vimAlias = true;
          withNodeJs = false;
          withPython3 = false;
          withRuby = false;
          extraLuaPackages = ps: [ps.lua-curl];

          extraMakeWrapperArgs = ''--prefix PATH : "${pkgs.lib.makeBinPath dependencies}" --prefix RA_LOG : "info,salsa::derived::slot=warn,chalk_recursive=warn,hir_ty::traits=warn,flycheck=trace,rust_analyzer::main_loop=warn,ide_db::apply_change=warn,project_model=debug,proc_macro_api=debug,hir_expand::db=error,ide_assists=debug,ide=debug" --set CLICOLOR_FORCE 0 --prefix RUST_SRC_PATH : "${pkgs.rustPlatform.rustLibSrc}"'';
          # make sure impatient is loaded before everything else to speed things up
          configure = {
            inherit customRC;
            packages.myPlugins = {
              start = requiredPlugins;
              opt = optionalPlugins;
            };
          };
        }
        // {buildInputs = dependencies;}) # this last line is needed so neovide can pull in same ones
        .overrideAttrs (old: {
        name = "pwnvim";
        __intentionallyOverridingVersion = true;
        version = old.version + "-" + self.lastModifiedDate;
      });
      apps.pwnvim =
        flake-utils.lib.mkApp {
          drv = packages.pwnvim;
          name = "pwnvim";
          exePath = "/bin/nvim";
        }
        // {
          meta = {
            description = "PW's Neovim configuration";
            mainProgram = "nvim";
          };
        };
      packages.default = packages.pwnvim;
      apps.default = apps.pwnvim;
      devShells.default = pkgs.mkShell {
        buildInputs = [packages.pwnvim] ++ dependencies;
        shellHook = ''
          # Set up git hooks from tracked .githooks directory
          if [ -d .git ]; then
            git config core.hooksPath .githooks
          fi
        '';
      };
    });
}
