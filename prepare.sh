#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare.sh
#  CONTENT: Generate 32-bit and 64-bit bundles such as the All-in-One.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

[[ -z "${TRAVIS_BUILD_DIR}" ]] && echo "Script needs to run on Travis CI" \
  && exit 1

export FILES_BASE="http://files.squeak.org/base/"
# export VM_BASE="http://files.squeak.org/base/"
export TARGET_URL="https://www.hpi.uni-potsdam.de/hirschfeld/artefacts/squeak/"

export SCRIPTS_DIR="${TRAVIS_BUILD_DIR}/scripts"
export TEMPLATE_DIR="${TRAVIS_BUILD_DIR}/template"

export BUILD_DIR="${TRAVIS_BUILD_DIR}/build"
export TMP_DIR="${TRAVIS_BUILD_DIR}/tmp"

# Prepare signing
unzip -q ./certs/dist.zip -d ./certs
security create-keychain -p travis osx-build.keychain
security default-keychain -s osx-build.keychain
security unlock-keychain -p travis osx-build.keychain
security import ./certs/dist.cer -k ~/Library/Keychains/osx-build.keychain -T /usr/bin/codesign
security import ./certs/dist.p12 -k ~/Library/Keychains/osx-build.keychain -P "${CERT_PASSWORD}" -T /usr/bin/codesign

# Create build and temp folders for 32-bit run
mkdir "${BUILD_DIR}" "${TMP_DIR}"
bash "${TRAVIS_BUILD_DIR}/prepare_32.sh"

# Clean-up build and temp folders for 64-bit run
rm -f -r "${TMP_DIR}"
rm -f -r "${BUILD_DIR}"
mkdir "${BUILD_DIR}" "${TMP_DIR}"
bash "${TRAVIS_BUILD_DIR}/prepare_64.sh"

# Remove signing information
security delete-keychain osx-build.keychain
