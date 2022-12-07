#!/bin/bash

TF="$HOME/.steam/steam/steamapps/common/Team Fortress 2/tf"

mkdir -pv "$TF/scripts/vscripts/"
cp -rv ./domc "$TF/scripts/vscripts/"
