{
  description = "PW's Neovim (pwnvim) Configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    #nixpkgs-stable.url = "github:nixos/nixpkgs/nixpkgs-22.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}; 
        #pkgs = import nixpkgs { inherit system; };
      in rec {
        packages.pwnvim = pkgs.wrapNeovim pkgs.neovim-unwrapped {
          viAlias = false;
          vimAlias = false;
          withNodeJs = false;
          withPython3 = false;
          withRuby = false;
          extraPython3Packages = false;
          configure = {
            customRC = "";
          };
          packages.myVimPackage = with pkgs.vimPlugins; {
            start = with pkgs.vimPlugins; [onedarkpro-nvim telescope-nvim vim-fugitive ];
            opt = with pkgs.vimPlugins; [trouble-nvim ];
          };
        };
        apps.pwnvim = flake-utils.lib.mkApp { 
          drv = packages.pwnvim;
          exePath = "${pkgs.nvim}/bin/nvim";
        };
        defaultPackage = pkgs.neovim;
        defaultApp = apps.pwnvim;
        defaultPackages = packages;
      }
    );

}
