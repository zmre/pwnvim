(
  # For nixd from: https://github.com/nix-community/nixd/tree/main/docs/examples/flake
  import
  (
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    in
      fetchTarball {
        # Keep the owner in sync with the flake-compat input in flake.nix
        url = "https://github.com/${lock.nodes.flake-compat.locked.owner}/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
        sha256 = lock.nodes.flake-compat.locked.narHash;
      }
  )
  {src = ./.;}
)
.defaultNix
