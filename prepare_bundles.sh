#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundles.sh
#  CONTENT: Generate different bundles such as the All-in-One.
#
#  REQUIRES:
#    SMALLTALK_VERSION ... e.g., Squeak64-trunk or Etoys64-trunk
#    SHOULD_CODESIGN   ... i.e., true or false
#    tmp/Squeak.image
#    tmp/Squeak.changes
#    tmp/*.sources
#    SQUEAK_VERSION    ... e.g., Squeak6.0alpha
#    SQUEAK_UPDATE     ... e.g., 20639
#    IMAGE_BITS        ... i.e., 64 or 32
#  OPTIONAL:
#    CODESIGN_KEY      ... i.e., for unlocking secret files
#    CODESIGN_IV       ... i.e., for unlocking secret files
#    CERT_IDENTITY     ... i.e., for signing the bundle
#    CERT_PASSWORD     ... i.e., for signing the bundle
#    NOTARIZATION_USER ... i.e., for distributing the bundle
#    NOTARIZATION_PASSWORD i.e., for distributing the bundle
#  PROVIDES:
#    IMAGE_NAME        ... e.g., Squeak6.0alpha-20639-64bit
#    product/*.zip
#    product/*.dmg
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

source "env_vars"
source "helpers.sh"
source "helpers_bundles.sh"

[[ -z "${SMALLTALK_VERSION}" ]] && exit 2
[[ -z "${SHOULD_CODESIGN}" ]] && exit 3

[[ -z "${SQUEAK_VERSION}" ]] && exit 4
[[ -z "${SQUEAK_UPDATE}" ]] && exit 5
[[ -z "${IMAGE_BITS}" ]] && exit 6

readonly TEMPLATE_PATH="${HOME_PATH}/templates"
readonly AIO_TEMPLATE_PATH="${TEMPLATE_PATH}/all-in-one"
readonly LIN_TEMPLATE_PATH="${TEMPLATE_PATH}/linux"
readonly MAC_TEMPLATE_PATH="${TEMPLATE_PATH}/macos"
readonly WIN_TEMPLATE_PATH="${TEMPLATE_PATH}/win"

readonly LOCALE_PATH="${HOME_PATH}/locale"

readonly VM_VERSIONS="versions.txt"

if is_etoys; then
  readonly SMALLTALK_NAME="Etoys"
else
  readonly SMALLTALK_NAME="Squeak"
fi

source "prepare_image_post.sh"
download_and_extract_all_vms

if should_codesign; then
  source "helpers_codesign.sh"
  prepare_codesign
fi

prepare_image_bundle # Just .image and .changes in an archive
source "prepare_bundle_aio.sh"
source "prepare_bundle_macos.sh"
source "prepare_bundle_linux.sh"
source "prepare_bundle_windows.sh"

if is_32bit; then
  source "prepare_bundle_linux_armv6.sh"
fi

if should_codesign; then
  cleanup_codesign
fi