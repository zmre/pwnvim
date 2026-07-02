#!/bin/sh

if [ -e result ]; then
  OLDRESULT=$(realpath result)
fi
nix flake update
nix build --json \
  | jq -r '.[].outputs | to_entries[].value' \
  | cachix push zmre
if [ -n "${OLDRESULT:-}" ]; then
  echo "Diff with $OLDRESULT"
  nix store diff-closures "$OLDRESULT" ./result |grep '→'
else
  echo "No previous result symlink; skipping closure diff"
fi
