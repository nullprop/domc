#!/bin/bash -x

set -euo pipefail

TF="$HOME/.steam/steam/steamapps/common/Team Fortress 2/tf"

mkdir -pv "$TF/scripts/"
ln -s "$(pwd)/scripts/vscripts" "$TF/scripts/vscripts"

