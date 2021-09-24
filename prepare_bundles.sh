#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundles.sh
#  CONTENT: Generate different bundles such as the All-in-One.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

[[ -z "${SMALLTALK_VERSION}" ]] && exit 2
[[ -z "${GIT_BRANCH}" ]] && exit 3
[[ -z "${DEPLOYMENT_BRANCH}" ]] && exit 3

source "env_vars"
source "helpers.sh"
source "helpers_bundles.sh"

readonly TEMPLATE_DIR="${HOME_DIR}/templates"
readonly AIO_TEMPLATE_DIR="${TEMPLATE_DIR}/all-in-one"
readonly LIN_TEMPLATE_DIR="${TEMPLATE_DIR}/linux"
readonly MAC_TEMPLATE_DIR="${TEMPLATE_DIR}/macos"
readonly WIN_TEMPLATE_DIR="${TEMPLATE_DIR}/win"

readonly LOCALE_DIR="${HOME_DIR}/locale"

readonly VM_LIN="vm-linux"
readonly VM_MAC="vm-macos"
readonly VM_WIN="vm-win"
readonly VM_ARM6="vm-armv6"
readonly VM_VERSIONS="versions.txt"

if is_etoys; then
  readonly SMALLTALK_NAME="Etoys"
else
  readonly SMALLTALK_NAME="Squeak"
fi

source "prepare_image_post.sh"
download_and_extract_vms

if is_deployment_branch; then
  source "helpers_codesign.sh"
  prepare_codesign
fi

reset_build_dir
source "prepare_aio.sh"
reset_build_dir
source "prepare_mac.sh"
reset_build_dir
source "prepare_lin.sh"
reset_build_dir
source "prepare_win.sh"

reset_build_dir
if is_32bit; then
  source "prepare_armv6.sh"
fi

if is_deployment_branch; then
  cleanup_codesign
fi
