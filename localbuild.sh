#!/bin/bash
export TRAVIS_BUILD_DIR="$(pwd)"
export TRAVIS_SMALLTALK_VERSION="Squeak-trunk"

# On non-Travis runs, just disable codesigning, security, and the extracting
# of the signing key
alias codesign=echo
alias security=echo
export UNZIPPATH=$(which unzip)
function friendlyunzip() {
    $UNZIPPATH $@ || true
}
alias unzip=friendlyunzip

exec ./prepare.sh
