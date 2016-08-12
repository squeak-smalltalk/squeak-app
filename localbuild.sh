#!/bin/bash
export TRAVIS_BUILD_DIR="$(pwd)"
export TRAVIS_SMALLTALK_VERSION="Squeak-trunk"

# On non-Travis runs, just disable codesigning, security, and the extracting
# of the signing key
export UNZIPPATH=$(which unzip)
function codesign() {
    echo "No codesigning in local build"
}
function security() {
    echo "No security in local build"
}
function unzip() {
    "$(which unzip)" $@ || true
}
export -f codesign
export -f security
export -f unzip

exec ./prepare.sh
