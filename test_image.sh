#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    test_image.sh
#  CONTENT: Use smalltalkCI to run all tests in the prepared image.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

[[ -z "${SMALLTALK_VERSION}" ]] && exit 2
[[ -z "${RUNNER_OS}" ]] && exit 3
[[ -z "${SMALLTALK_CI_HOME}" ]] && exit 4

source "env_vars"
source "helpers.sh"

mkdir -p "${TMP_DIR}"

readonly SCI_DIR="${HOME_DIR}/smalltalk-ci"

test_image() {
  local ston_config="default.ston"

  if [[ -f "${SCI_DIR}/${SMALLTALK_VERSION}.ston" ]]; then
    ston_config="${SMALLTALK_VERSION}.ston"
  fi

  cp "${TMP_DIR}/Squeak.image" "${TMP_DIR}/Test.image"
  cp "${TMP_DIR}/Squeak.changes" "${TMP_DIR}/Test.changes"

  # Improve compatibility with Windows ... *sigh*
  cp "${SCI_DIR}/${ston_config}" "${TMP_DIR}/${ston_config}"
  cp -r "${SMALLTALK_CI_HOME}/repository" "${HOME_DIR}/smalltalk-ci"

  begin_group "Testing Squeak via smalltalkCI using ${ston_config}..."
  export SCIII_COLORFUL="true"
  pushd "${TMP_DIR}"
  "${SMALLTALK_VM}" -headless "Test.image" \
       "../test_image.st" "${SMALLTALK_VERSION}" \
       "../smalltalk-ci" "${ston_config}" \
         || true # Ignore crashes/failures
  popd
  check_test_status
  end_group
}

check_test_status() {
  local test_status_file="build_status.txt"
  local build_status

  if ! is_file "${TMP_DIR}/${test_status_file}"; then
    print_error "...build failed before tests were performed correctly!"
    exit 1
  fi
  build_status=$(cat "${TMP_DIR}/${test_status_file}")
  if [[ ! -z "${build_status}" ]]; then
    # Note that build_status is not expected to be "[successful]" but empty on success
    print_warning "...all tests were performed correctly but they did not all pass."
    exit 1
  fi
}

prepare_platform_vm
test_image
