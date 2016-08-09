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

readonly FILES_BASE="http://files.squeak.org/base/"
# readonly VM_BASE="http://files.squeak.org/base/"
readonly TARGET_URL="https://www.hpi.uni-potsdam.de/hirschfeld/artefacts/squeak/"

readonly SCRIPTS_DIR="${TRAVIS_BUILD_DIR}/scripts"
readonly TEMPLATE_DIR="${TRAVIS_BUILD_DIR}/template"

readonly BUILD_DIR="${TRAVIS_BUILD_DIR}/build"
readonly TMP_DIR="${TRAVIS_BUILD_DIR}/tmp"

# Prepare signing
unzip -q ./certs/dist.zip -d ./certs

# Create build and temp folders for 32-bit run
mkdir "${BUILD_DIR}" "${TMP_DIR}"
bash "${TRAVIS_BUILD_DIR}/prepare_32.sh"

# Clean-up build and temp folders for 64-bit run
rm -f -r "${TMP_DIR}"
rm -f -r "${BUILD_DIR}"
mkdir "${BUILD_DIR}" "${TMP_DIR}"
bash "${TRAVIS_BUILD_DIR}/prepare_64.sh"
