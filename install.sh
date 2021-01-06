#!/bin/sh

set -e

L_HOME_DIR="$HOME/.l.rb"
L_RELEASE="0.0.1"

# make sure the bin path is in place

      [ -n "$PREFIX" ] || PREFIX="/usr/local"
      BIN_PATH="$PREFIX/bin"
      mkdir -p "$BIN_PATH"

# download the release tag and link to the bin path

      mkdir -p "$L_HOME_DIR"
      pushd "$L_HOME_DIR" > /dev/null &&
        rm -rf "l.rb-$L_RELEASE"
        curl -L "https://github.com/redding/l.rb/tarball/$L_RELEASE" | tar xzf - '*/libexec/*'
        mv *-l.rb-* "l.rb-$L_RELEASE"
        ln -sf "l.rb-$L_RELEASE/libexec"
      popd > /dev/null

# install in the bin path

      ln -sf "$L_HOME_DIR/libexec/l.rb" "$BIN_PATH/l"

# done!

      echo "Installed at ${BIN_PATH}/l"
