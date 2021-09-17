#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_image.sh
#  CONTENT: Prepare appropriate base image.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

[[ -z "${SMALLTALK_VERSION}" ]] && exit 2
[[ -z "${RUNNER_OS}" ]] && exit 3

source "env_vars"
source "helpers.sh"

mkdir -p "${TMP_DIR}"

download_and_prepare_files() {
  print_info "...downloading and extracting image, changes, and sources..."
  curl -f -s --retry 3 -o "${TMP_DIR}/base.zip" "${IMAGE_URL}"

  if [[ ! -f "${TMP_DIR}/base.zip" ]]; then
    echo "Base image not found at ${IMAGE_URL}!"
    exit 1
  fi

  unzip -q "${TMP_DIR}/base.zip" -d "${TMP_DIR}/"
  mv "${TMP_DIR}/"*.image "${TMP_DIR}/Squeak.image"
  mv "${TMP_DIR}/"*.changes "${TMP_DIR}/Squeak.changes"
  cp -R "${RELEASE_NOTES_DIR}" "${TMP_DIR}/"
  cp "${ICONS_DIR}/balloon.png" "${TMP_DIR}/"
}

prepare_image() {
  begin_group "...launching, updating, and configuring Squeak..."
  # Do not use -headless here, otherwise there is a problem with the image's initial dimensions
  pushd "${TMP_DIR}"
  "${SMALLTALK_VM}" "Squeak.image" \
      "../prepare_image.st" "${SMALLTALK_VERSION}"
  popd
  end_group
  if ! is_file "${VERSION_FILE}"; then
    print_error "Image preparation failed: version.sh file was not exported."
    exit 1
  fi
}

print_info "...starting to build ${SMALLTALK_VERSION}..."

prepare_platform_vm
download_and_prepare_files
prepare_image
