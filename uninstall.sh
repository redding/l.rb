#!/bin/sh

set -e
L_HOME_DIR="$HOME/.chpg"

# remove the bin

      [ -n "$PREFIX" ] || PREFIX="/usr/local"
      BIN_PATH="$PREFIX/bin"
      rm -f "$BIN_PATH/t" > /dev/null

# remove the installed source

      rm -rf "$L_HOME_DIR"

# done!  print out some optional removal instructions

      echo "Done.\n"
