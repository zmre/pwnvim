#!/bin/sh

OLDRESULT=$(realpath result)
nix flake update
nix build
echo "Diff with $OLDRESULT"
nix store diff-closures "$OLDRESULT" ./result |egrep -v '[∅ε]' |grep '→'