#!/bin/sh

L_RELEASE="0.1.4" # also update in install.sh and libexec/l.rb

# check uncommitted changes

      if ! git diff-index --quiet HEAD --; then
        echo "There are files that need to be committed first."
      else
        # tag the release

              if git tag -a -m "Release $L_RELEASE" "$L_RELEASE"; then
                echo "Tagged $L_RELEASE release."

        # push the changes and tags

                if git push && git push --tags; then
                  echo "Pushed git commits and tags"
                else
                  echo "Release aborted."
                fi
              else
                echo "Release aborted."
              fi
      fi
