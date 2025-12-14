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
    # Note: dfendr's fork could also be one to use.
    # clipboard-image.url = "github:ekickx/clipboard-image.nvim";
    clipboard-image.url = "github:postfen/clipboard-image.nvim";
    clipboard-image.flake = false;
    # conform-nvim.url = "github:stevearc/conform.nvim";
    # conform-nvim.flake = false;
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
          })
          (self: super: {
            vimPlugins =
              super.vimPlugins
              // {
                clipboard-image = super.vimUtils.buildVimPlugin {
                  name = "clipboard-image.nvim";
                  pname = "clipboard-image.nvim";
                  src = inputs.clipboard-image;
                  # buildInputs = [ super.curl ];
                };
                # conform-nvim = super.vimUtils.buildVimPlugin {
                #   name = "conform-nvim";
                #   pname = "conform-nvim";
                #   src = inputs.conform-nvim;
                # };
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
          bat # previewer for telescope for now
          gh
          zk # lsp for markdown notes in zk folders
          #markdown-oxide # lsp for any markdown
          marksman # lsp for any markdown
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
          nodePackages.eslint_d # js/ts code formatter and linter
          nodePackages.prettier # ditto
          #nodePackages.prisma # dependency prisma-engines not compiling right now 2024-08-26
          nodePackages.svelte-language-server
          nodePackages.diagnostic-languageserver
          nodePackages.typescript-language-server
          nodePackages.bash-language-server
          nodePackages."@tailwindcss/language-server"
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

          metals # lsp for scala
          yazi # my alt file manager triggered with ,-
          # imagemagick # for image-nvim plugin
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
          ueberzug
          xclip # needed by vim clipboard-image plugin
          wl-clipboard # needed by vim clipboard-image plugin
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin
        [pngpaste]; # needed by vim clipboard-image plugin

      # I don't think the vim.env.whatever = value stuff below actually works
      customRC =
        ''
          lua << EOF
            package.path = "${self}/?.lua;" .. package.path
            rustsrc_path = "${pkgs.rustPlatform.rustLibSrc}/core/Cargo.toml"
            prettier_path = "${pkgs.nodePackages.prettier}/bin/prettier"
            lldb_path_base = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}"
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
        # Removing 2022-11-30 as it is slow and treesitter generally does the same thing
        # Reinstating 2024-09-10 so I get fallbacks again
        # Removing again 2024-12-12 because it isn't respecting the ftdetect disable and is overriding my detections
        #vim-polyglot # lazy load all the syntax plugins for all the languages
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
        #nvim-lightbulb # show code actions available ; 2025-06-09 removing due to huge number of deprecations that have been ignored for a long time

        # UI #################################################
        onedarkpro-nvim # colorscheme
        catppuccin-nvim # colorscheme
        ir_black # colorscheme for basic terminals
        #zephyr-nvim # alternate colorscheme
        snacks-nvim # folke's swiss army knife - using for picker (replaces telescope)
        dressing-nvim # dresses up vim.ui.input (snacks handles vim.ui.select)
        nvim-colorizer-lua # color over CSS like #00ff00
        nvim-web-devicons # makes things pretty; used by many plugins below
        oil-nvim # file navigator
        gitsigns-nvim # git status in gutter
        # symbols-outline-nvim # navigate the current file better
        lualine-nvim # nice status bar at bottom ; TODO 2025-06-09 time to find an alternative? tons of undealt with deprecations
        # vim-bbye replaced by snacks.bufdelete
        # bufferline-nvim # tabs at top
        dropbar-nvim # replacing the now archived barbecue (sad!)
        nvim-navbuddy # use same lsp symbols to navigate in popup
        nvim-ufo # allow use of lsp as source for folding
        promise-async # required by nvim-ufo
        # indent-blankline-nvim replaced by snacks.indent
        # toggleterm-nvim replaced by snacks.terminal
        playground # treesitter playground
        nvim-treesitter-textobjects # jump around and select based on syntax (class, function, etc.)
        nvim-treesitter-textsubjects # adds "smart" text objects
        lf-vim
        nui-nvim # needed by noice
        nvim-notify # needed by noice
        noice-nvim # show progress and add other UI improvements
        marks-nvim # show marks in the gutter
        yazi-nvim # another file manager which i've started using; not replacing oil yet so side by side for now

        # Editor Features ####################################
        vim-abolish # better abbreviations / spelling fixer
        nvim-surround # .... updated lua-based alternative to tpope's surround
        vim-unimpaired # bunch of convenient navigation key mappings
        vim-repeat # supports all of the above so you can use .
        #nvim-ts-context-commentstring # makes kommentary contextual for embedded languages
        vim-eunuch # brings cp/mv type commands. :Rename and :Move are particularly handy
        vim-speeddating # allows ctrl-x and ctrl-a to increment/decrement dates
        flash-nvim

        # Database interactions
        # vim-dadbod
        # vim-dadbod-ui
        # vim-dadbod-completion

        # Autocompletion
        #nvim-cmp # generic autocompleter
        #cmp-nvim-lsp # use lsp as source for completions
        #cmp-nvim-lua # makes vim config editing better with completions
        #cmp-buffer # any text in open buffers
        #cmp-path # complete paths
        #cmp-cmdline # completing in :commands
        #cmp-emoji # complete :emojis:
        #cmp-nvim-lsp-signature-help # help complete function call by showing args
        #cmp-npm # complete node packages in package.json
        blink-cmp
        codecompanion-nvim # llm access in context; TODO 2025-06-09 find an alternative? riddled with deprecated function calls
        nvim-autopairs # balances parens as you type
        nvim-ts-autotag # balance or rename html
        vim-emoji # TODO: redundant now?
        #luasnip # snippets driver
        #cmp_luasnip # snippets completion
        #friendly-snippets # actual library of snippets used by luasnip

        # writing
        zk-nvim # lsp for a folder of notes for searching/linking/etc.
        # zen-mode-nvim replaced by snacks.zen
        # twilight-nvim # dim text outside of current scope

        # Misc
        vim-fugitive # git management
        diffview-nvim
        vim-tmux-navigator # navigate vim and tmux panes together
        impatient-nvim # speeds startup times by caching lua bytecode
        which-key-nvim
        vim-startuptime

        # Something was obliterating rtp and making grammars disappear. Putting this on the bottom of the list
        # fixes the issue for me 2024-09-10.
        nvim-treesitter.withAllGrammars
        #(nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars)) # better code coloring
      ];
      optionalPlugins = with pkgs.vimPlugins; [
        # grammar check
        vim-grammarous
        # see note about hologram in markdown.lua file. commented out 2023-01-19
        #hologram-nvim # images inline for markdown (only in terminal)
        direnv-vim # auto-execute nix direnv setups -- currently my slowest plugin; enabled by programming filetype
        clipboard-image # only loaded in markdown files
        comment-nvim # code commenter
        crates-nvim # inline intelligence for Cargo.toml
        todo-comments-nvim # highlight comments like NOTE
        render-markdown-nvim # prettier markdown files
        # image-nvim
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
          luacheck . --no-color || echo "Luacheck found issues (non-blocking for now)"

          echo "Testing neovim startup..."
          nvim --headless -c "lua vim.defer_fn(function() print('STARTUP_OK') vim.cmd('qa!') end, 100)" 2>&1 | grep -q "STARTUP_OK" || (echo "Startup test failed"; exit 1)

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

          # vim.env.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}"
          # vim.env.RA_LOG = "info,salsa::derived::slot=warn,chalk_recursive=warn,hir_ty::traits=warn,flycheck=trace,rust_analyzer::main_loop=warn,ide_db::apply_change=warn,project_model=debug,proc_macro_api=debug,hir_expand::db=error,ide_assists=debug,ide=debug"
          # --vim.env.RA_LOG = "info"
          # --vim.env.RA_PROFILE = "*>50"

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
      apps.pwnvim = flake-utils.lib.mkApp {
        drv =
          packages.pwnvim;
        name = "pwnvim";
        exePath = "/bin/nvim";
      };
      packages.default = packages.pwnvim;
      apps.default = apps.pwnvim;
      devShell = pkgs.mkShell {
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
