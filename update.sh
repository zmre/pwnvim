#!/bin/sh

OLDRESULT=$(realpath result)
nix flake update
nix build --json \
  | jq -r '.[].outputs | to_entries[].value' \
  | cachix push zmre
echo "Diff with $OLDRESULT"
nix store diff-closures "$OLDRESULT" ./result |grep '→'
#nix store diff-closures "$OLDRESULT" ./result |grep -Ev '[∅ε]' |grep '→'

