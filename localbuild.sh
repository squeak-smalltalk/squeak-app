#!/bin/bash
export TRAVIS_BUILD_DIR="$(pwd)"
export TRAVIS_SMALLTALK_VERSION="Squeak-trunk"
export LOCALBUILD=1
exec ./prepare.sh
