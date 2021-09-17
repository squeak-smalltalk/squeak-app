#!/bin/bash
git clean -fdx
export HOME_DIR="$(pwd)"
export SMALLTALK_VERSION="Squeak64-trunk"
export RUNNER_OS="Windows"
export GIT_BRANCH="squeak-trunk"
export DEPLOYMENT_BRANCH="squeak-trunk"

# On local runs, just disable codesigning, security, and the extracting
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

exec ./prepare_image.sh
exec ./test_image.sh
exec ./prepare_bundles.sh
# exec ./deploy_image.sh
