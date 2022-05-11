#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_image.sh
#  CONTENT: Prepare appropriate base image.
#
#  REQUIRES:
#    SMALLTALK_VERSION ... e.g., Squeak64-trunk
#  PROVIDES:
#    SQUEAK_VERSION    ... e.g., Squeak6.0alpha
#    SQUEAK_UPDATE     ... e.g., 20639
#    IMAGE_BITS        ... i.e., 64 or 32
#    IMAGE_FORMAT      ... e.g., 68021
#    tmp/Squeak.image
#    tmp/Squeak.changes
#    tmp/*.sources
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

[[ -z "${SMALLTALK_VERSION}" ]] && exit 2

source "env_vars"
source "helpers.sh"

download_and_prepare_files() {
  print_info "...downloading and extracting image, changes, and sources..."
  curl -f -s --retry 3 -o "${TMP_PATH}/base.zip" "${IMAGE_URL}"

  if [[ ! -f "${TMP_PATH}/base.zip" ]]; then
    echo "Base image not found at ${IMAGE_URL}!"
    exit 1
  fi

  unzip -q "${TMP_PATH}/base.zip" -d "${TMP_PATH}/"
  mv "${TMP_PATH}/"*.image "${TMP_PATH}/Squeak.image"
  mv "${TMP_PATH}/"*.changes "${TMP_PATH}/Squeak.changes"
  cp -R "${RELEASE_NOTES_PATH}" "${TMP_PATH}/"
  cp "${ICONS_PATH}/balloon.png" "${TMP_PATH}/"
}

prepare_image() {
  begin_group "...launching, updating, and configuring Squeak..."
  # Do not use -headless here, otherwise there is a problem with the image's initial dimensions
  pushd "${TMP_PATH}" > /dev/null
  "${SMALLTALK_VM}" "Squeak.image" \
      "../prepare_image.st" "${SMALLTALK_VERSION}"
  popd > /dev/null
  end_group

  readonly VERSION_FILEPATH="${TMP_PATH}/version.sh"
  if ! is_file "${VERSION_FILEPATH}"; then
    print_error "Image preparation failed: version.sh file was not exported."
    exit 1
  else
    export_version_info
  fi
}

export_version_info() {
  source "${VERSION_FILEPATH}" # version.sh file produced by image
  export_variable "SQUEAK_VERSION" "${SQUEAK_VERSION}"
  export_variable "SQUEAK_UPDATE" "${SQUEAK_UPDATE}"
  export_variable "IMAGE_BITS" "${IMAGE_BITS}"
  export_variable "IMAGE_FORMAT" "${IMAGE_FORMAT}"
}

print_info "...starting to build ${SMALLTALK_VERSION}..."

prepare_platform_vm
download_and_prepare_files
prepare_image
