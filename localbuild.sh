#!/bin/bash

export SMALLTALK_VERSION="${1:-Squeak64-trunk}"
export SHOULD_DEPLOY="${2:-false}"
export SHOULD_CODESIGN="${SHOULD_DEPLOY}"

# On local runs, just disable code signing, security, and the extracting
# of the signing key

function codesign() {
  echo "No code signing in local build"
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
  echo "No auto-install in local build"
}
export -f codesign
export -f security
export -f unzip
export -f curl
export -f brew

# git clean -fdx
# exec ./prepare_image.sh

# export SMALLTALK_CI_HOME="../smalltalkCI"
# exec ./test_image.sh

# source "tmp/version.sh"
# exec ./prepare_bundles.sh

# export IMAGE_NAME="Squeak6.0alpha-20639-64bit"
# exec ./deploy_bundles.sh
