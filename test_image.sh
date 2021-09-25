#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    test_image.sh
#  CONTENT: Use smalltalkCI to run all tests in the prepared image.
#
#  REQUIRES:
#    SMALLTALK_VERSION ... e.g., Squeak64-trunk
#    SMALLTALK_CI_HOME ... i.e., the path to smalltalkCI sources
#    tmp/Squeak.image
#    tmp/Squeak.changes
#    tmp/*.sources
#  PROVIDES:
#    tmp/*.xml             i.e., the test results
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

source "env_vars"
source "helpers.sh"

[[ -z "${SMALLTALK_VERSION}" ]] && exit 2
[[ -z "${SMALLTALK_CI_HOME}" ]] && exit 3

readonly SCI_PATH="${HOME_PATH}/smalltalk-ci"

test_image() {
  local ston_config="default.ston"

  if [[ -f "${SCI_PATH}/${SMALLTALK_VERSION}.ston" ]]; then
    ston_config="${SMALLTALK_VERSION}.ston"
  fi

  cp "${TMP_PATH}/Squeak.image" "${TMP_PATH}/Test.image"
  cp "${TMP_PATH}/Squeak.changes" "${TMP_PATH}/Test.changes"

  # Prepare usage of relative paths to improve compatibility with Windows
  cp "${SCI_PATH}/${ston_config}" "${TMP_PATH}/${ston_config}"
  cp -r "${SMALLTALK_CI_HOME}/repository" "${HOME_PATH}/smalltalk-ci"

  begin_group "Testing Squeak via smalltalkCI using ${ston_config}..."
  export SCIII_COLORFUL="true"
  pushd "${TMP_PATH}" > /dev/null
  "${SMALLTALK_VM}" -headless "Test.image" \
       "../test_image.st" "${SMALLTALK_VERSION}" \
       "../smalltalk-ci" "${ston_config}" \
         || true # Ignore crashes/failures
  popd > /dev/null
  check_test_status
  end_group
}

check_test_status() {
  local test_status_file="build_status.txt"
  local build_status

  if ! is_file "${TMP_PATH}/${test_status_file}"; then
    print_error "...build failed before tests were performed correctly!"
    exit 1
  fi
  build_status=$(cat "${TMP_PATH}/${test_status_file}")
  if [[ ! -z "${build_status}" ]]; then
    # Note that build_status is not expected to be "[successful]" but empty on success
    print_warning "...all tests were performed correctly but they did not all pass."
    exit 1
  fi
}

prepare_platform_vm
test_image
