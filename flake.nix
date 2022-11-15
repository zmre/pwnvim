{
  description = "PW's Neovim (pwnvim) Configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    #nixpkgs-stable.url = "github:nixos/nixpkgs/nixpkgs-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    zk-nvim = {
      url = "github:mickael-menu/zk-nvim";
      flake = false;
    };
    telescope-media-files = {
      url = "github:nvim-telescope/telescope-media-files.nvim";
      flake = false;
    };
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (self: super: {
              vimPlugins = super.vimPlugins // {
                zk-nvim = super.vimUtils.buildVimPlugin {
                  name = "zk-nvim";
                  pname = "zk-nvim";
                  src = inputs.zk-nvim;
                };
                telescope-media-files = super.vimUtils.buildVimPlugin {
                  name = "telescope-media-files";
                  pname = "telescope-media-files";
                  src = inputs.telescope-media-files;
                };
              };
            })
          ];
        };

        recursiveMerge = attrList:
          let
            f = attrPath:
              pkgs.lib.zipAttrsWith (n: values:
                if pkgs.lib.tail values == [ ] then
                  pkgs.lib.head values
                else if pkgs.lib.all pkgs.lib.isList values then
                  pkgs.lib.unique (pkgs.lib.concatLists values)
                else if pkgs.lib.all pkgs.lib.isAttrs values then
                  f (attrPath ++ [ n ]) values
                else
                  pkgs.lib.last values);
          in f [ ] attrList;

      in rec {
        dependencies = with pkgs;
          [
            fd
            ripgrep
            fzy
            zoxide
            zk
            vale
            proselint
            nixfmt
            luaformatter
            rnix-lsp
            sumneko-lua-language-server
            nodePackages.vscode-langservers-extracted # lsp servers for json, html, css
            nodePackages.svelte-language-server
            nodePackages.diagnostic-languageserver
            nodePackages.typescript-language-server
            nodePackages."@tailwindcss/language-server"
            rust-analyzer
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ ueberzug ];
        neovim-augmented = recursiveMerge [
          pkgs.neovim-unwrapped
          { buildInputs = dependencies; }
        ];
        packages.pwnvim = pkgs.wrapNeovim neovim-augmented {
          #packages.pwnvim = pkgs.neovim.override {
          viAlias = false;
          vimAlias = false;
          withNodeJs = false;
          withPython3 = false;
          withRuby = false;
          extraPython3Packages = false;
          extraMakeWrapperArgs =
            ''--suffix PATH : "${pkgs.lib.makeBinPath dependencies}"'';
          configure = {
            customRC = ''
              lua << EOF
                package.path = "${self}/?.lua;" .. package.path
                require('pwnvim.options').defaults()
                require('pwnvim.options').gui()
                require('pwnvim.mappings')
                require('pwnvim.abbreviations')
                require('pwnvim.filetypes').config()
                require('pwnvim.plugins').ui()
                require('pwnvim.plugins').diagnostics()
                require('pwnvim.plugins').telescope()
                require('pwnvim.plugins').completions()
                require('pwnvim.plugins').notes()
                require('pwnvim.plugins').misc()
              EOF
            '';
            packages.myPlugins = with pkgs.vimPlugins; {
              start = with pkgs.vimPlugins; [
                # Common dependencies of other plugins
                popup-nvim # dependency of some other plugins
                plenary-nvim # Library for lua plugins; used by many plugins here

                # Syntax / Language Support ##########################
                vim-polyglot # lazy load all the syntax plugins for all the languages
                rust-tools-nvim # lsp stuff and more for rust
                crates-nvim # inline intelligence for Cargo.toml
                nvim-lspconfig # setup LSP for intelligent coding
                # nvim-lsp-ts-utils for inlays
                null-ls-nvim # formatting and linting via lsp system
                trouble-nvim # navigate all warnings and errors in quickfix-like window
                lspsaga-nvim
                lsp-format-nvim
                todo-comments-nvim
                #copilot-vim # github copilot

                # UI #################################################
                onedarkpro-nvim # colorscheme
                zephyr-nvim # alternate colorscheme
                telescope-nvim # da best popup fuzzy finder
                telescope-fzy-native-nvim # but fzy gives better results
                telescope-frecency-nvim # and frecency comes in handy too
                telescope-media-files # only works on linux, but image preview
                dressing-nvim # dresses up vim.ui.input and vim.ui.select and uses telescope
                nvim-colorizer-lua # color over CSS like #00ff00
                nvim-web-devicons # makes things pretty; used by many plugins below
                nvim-tree-lua # file navigator
                gitsigns-nvim # git status in gutter
                symbols-outline-nvim # navigate the current file better
                lualine-nvim # nice status bar at bottom
                vim-bbye # fix bdelete buffer stuff needed with bufferline
                bufferline-nvim
                indent-blankline-nvim # visual indent
                toggleterm-nvim # better terminal management
                nvim-treesitter.withAllGrammars # better code coloring
                playground # treesitter playground
                nvim-treesitter-textobjects
                nvim-treesitter-context # keep current block header (func defn or whatever) on first line

                # Editor Features ####################################
                vim-abolish # better abbreviations / spelling fixer
                #vim-surround # most important plugin for quickly handling brackets
                nvim-surround # .... updated lua-based alternative to tpope's surround
                vim-unimpaired # bunch of convenient navigation key mappings
                vim-repeat # supports all of the above so you can use .
                vim-rsi # brings keyline bindings to editing (like ctrl-e for end of line when in insert mode)
                vim-visualstar # press * or # on a word to find it
                kommentary # code commenter
                nvim-ts-context-commentstring # makes kommentary contextual for embedded languages
                vim-eunuch # brings cp/mv type commands. :Rename and :Move are particularly handy

                # Autocompletion
                nvim-cmp # generic autocompleter
                cmp-nvim-lsp # use lsp as source for completions
                cmp-nvim-lua # makes vim config editing better with completions
                cmp-buffer # any text in open buffers
                cmp-path # complete paths
                cmp-cmdline # completing in :commands
                cmp-emoji # complete :emojis:
                nvim-autopairs # balances parens as you type
                vim-emoji # TODO: redundant now?
                luasnip # snippets driver
                cmp_luasnip # snippets completion
                friendly-snippets # actual library of snippets used by luasnip

                # Notes
                # 2022-08-30 I have quite liked taskwiki and vim-roam-task, but both use a #ab12ff
                # style of tagging tasks that confuses the hell out of markdown editors
                # that are tag aware. As I'm using NotePlan now to collect tasks, I'm
                # removing this. 
                #vim-roam-task # a clone of taskwiki that doesn't require vimwiki
                zk-nvim # lsp for a folder of notes for searching/linking/etc.
                true-zen-nvim # distraction free, width constrained writing mode
                twilight-nvim # dim text outside of current scope

                # Misc
                vim-fugitive # git management
                project-nvim
                vim-tmux-navigator # navigate vim and tmux panes together
                FixCursorHold-nvim # remove this when neovim #12587 is resolved
                impatient-nvim # speeds startup times by caching lua bytecode
                which-key-nvim
                direnv-vim # auto-execute nix direnv setups
              ];
              opt = with pkgs.vimPlugins;
                [
                  # grammar check
                  vim-grammarous
                ];
            };
          };
        };
        apps.pwnvim = flake-utils.lib.mkApp {
          drv = packages.pwnvim;
          name = "pwnvim";
          exePath = "/bin/nvim";
        };
        packages.default = packages.pwnvim;
        apps.default = apps.pwnvim;
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ packages.pwnvim ] ++ dependencies;
        };
      });

}
