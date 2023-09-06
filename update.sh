#!/bin/sh

OLDRESULT=$(realpath result)
nix flake update
nix build
nix flake archive --json \
  | jq -r '.path,(.inputs|to_entries[].value.path)' \
  | cachix push zmre
echo "Diff with $OLDRESULT"
nix store diff-closures "$OLDRESULT" ./result |grep -Ev '[∅ε]' |grep '→'

