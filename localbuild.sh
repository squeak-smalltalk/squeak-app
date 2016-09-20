#!/bin/bash
git clean -fdx
export TRAVIS_BUILD_DIR="$(pwd)"
export TRAVIS_SMALLTALK_VERSION="Etoys-trunk"

# On non-Travis runs, just disable codesigning, security, and the extracting
# of the signing key
mkdir encrypted
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
function curl() {
    if [ "$1" == "-T" ]; then
	echo "No uploading locally"
    else
	"$(which curl)" $@
    fi
}
function brew() {
    sudo $(which brew) $@
}
export -f codesign
export -f security
export -f unzip
export -f curl
export -f brew

exec ./prepare.sh
