#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare.sh
#  CONTENT: Generate different bundles such as the All-in-One.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

if [[ -z "${TRAVIS_BUILD_DIR}" ]]; then
  echo "Script needs to run on Travis CI"
  exit 1
fi

readonly FILES_BASE="http://files.squeak.org/base"
readonly RELEASE_URL="${FILES_BASE}/${TRAVIS_SMALLTALK_VERSION/Etoys/Squeak}"
readonly IMAGE_URL="${RELEASE_URL}/base.zip"
readonly VM_BASE="${RELEASE_URL}"
readonly TARGET_URL="https://www.hpi.uni-potsdam.de/hirschfeld/artefacts/squeak/"

readonly TEMPLATE_DIR="${TRAVIS_BUILD_DIR}/templates"
readonly AIO_TEMPLATE_DIR="${TEMPLATE_DIR}/all-in-one"
readonly LIN_TEMPLATE_DIR="${TEMPLATE_DIR}/linux"
readonly MAC_TEMPLATE_DIR="${TEMPLATE_DIR}/macos"
readonly WIN_TEMPLATE_DIR="${TEMPLATE_DIR}/win"

readonly BUILD_DIR="${TRAVIS_BUILD_DIR}/build"
readonly PRODUCT_DIR="${TRAVIS_BUILD_DIR}/product"
readonly TMP_DIR="${TRAVIS_BUILD_DIR}/tmp"
readonly ENCRYPTED_DIR="${TRAVIS_BUILD_DIR}/encrypted"

readonly LOCALE_DIR="${TRAVIS_BUILD_DIR}/locale"
readonly ICONS_DIR="${TRAVIS_BUILD_DIR}/icons"
readonly RELEASE_NOTES_DIR="${TRAVIS_BUILD_DIR}/release-notes"

readonly VM_BUILD="vm-build"
readonly VM_LIN="vm-linux"
readonly VM_MAC="vm-macos"
readonly VM_WIN="vm-win"
readonly VM_ARM6="vm-armv6"
readonly VM_VERSIONS="versions.txt"

# version.sh file produced by image
readonly VERSION_FILE="${TMP_DIR}/version.sh"

source "helpers.sh"

if is_etoys; then
  readonly SMALLTALK_NAME="Etoys"
else
  readonly SMALLTALK_NAME="Squeak"
fi

# Create build, product, and temp folders
mkdir "${BUILD_DIR}" "${PRODUCT_DIR}" "${TMP_DIR}"

download_and_extract_vms() {
  travis_fold start download_extract "...downloading and extracting all VMs..."

  echo "...downloading and sourcing VM versions file..."
  curl -f -s --retry 3 -o "${TMP_DIR}/vm-versions" "${VM_BASE}/${VM_VERSIONS}"
  source "${TMP_DIR}/vm-versions"
  if [[ -z "${VERSION_VM_ARMV6}" ]] || [[ -z "${VERSION_VM_LINUX}" ]] || \
     [[ -z "${VERSION_VM_MACOS}" ]] || [[ -z "${VERSION_VM_WIN}" ]]; then
    echo "Could not determine all required VM versions."
    exit 1
  fi

  echo "...downloading and extracting macOS VM..."
  curl -f -s --retry 3 -o "${TMP_DIR}/${VM_MAC}.zip" "${VM_BASE}/${VM_MAC}.zip"
  unzip -q "${TMP_DIR}/${VM_MAC}.zip" -d "${TMP_DIR}/${VM_MAC}"
  readonly SMALLTALK_VM="${TMP_DIR}/${VM_MAC}/CogSpur.app/Contents/MacOS/Squeak"
  if ! is_file "${SMALLTALK_VM}"; then
    echo "Failed to locate macOS VM binary."
    exit 1
  fi

  echo "...downloading and extracting Linux VM..."
  curl -f -s --retry 3 -o "${TMP_DIR}/${VM_LIN}.zip" "${VM_BASE}/${VM_LIN}.zip"
  unzip -q "${TMP_DIR}/${VM_LIN}.zip" -d "${TMP_DIR}/${VM_LIN}"

  echo "...downloading and extracting Windows VM..."
  curl -f -s --retry 3 -o "${TMP_DIR}/${VM_WIN}.zip" "${VM_BASE}/${VM_WIN}.zip"
  unzip -q "${TMP_DIR}/${VM_WIN}.zip" -d "${TMP_DIR}/${VM_WIN}"

  # ARMv6 currently only supported on 32-bit
  if is_32bit; then
    echo "...downloading and extracting ARMv6 VM..."
    curl -f -s --retry 3 -o "${TMP_DIR}/${VM_ARM6}.zip" "${VM_BASE}/${VM_ARM6}.zip"
    unzip -q "${TMP_DIR}/${VM_ARM6}.zip" -d "${TMP_DIR}/${VM_ARM6}"
  fi
  travis_fold end download_extract
}

compress() {
  target=$1
  echo "...compressing the bundle..."
  pushd "${BUILD_DIR}" > /dev/null
  # tar czf "${PRODUCT_DIR}/${target}.tar.gz" "./"
  zip -q -r "${PRODUCT_DIR}/${target}.zip" "./"
  popd > /dev/null
  # Reset $BUILD_DIR
  rm -rf "${BUILD_DIR}" && mkdir "${BUILD_DIR}"
  echo "...done."
}

copy_resources() {
  local target=$1
  echo "...copying image files into bundle..."
  cp "${TMP_DIR}/Squeak.image" "${target}/${IMAGE_NAME}.image"
  cp "${TMP_DIR}/Squeak.changes" "${target}/${IMAGE_NAME}.changes"
  cp "${TMP_DIR}/"*.sources "${target}/"
  if ! is_Squeak_50; then
    cp -R "${RELEASE_NOTES_DIR}" "${target}/"
    cp -R "${TMP_DIR}/locale" "${target}/"
  fi
  if is_etoys; then
    cp "${TMP_DIR}/"*.pr "${target}/"
    cp -R "${TMP_DIR}/ExampleEtoys" "${target}/"
  fi
}

download_and_extract_vms

source "prepare_image.sh"

if is_master_branch; then
  # Decrypt and extract sensitive files
  openssl aes-256-cbc -K $encrypted_7fdec7aaa5ee_key \
    -iv $encrypted_7fdec7aaa5ee_iv -in .encrypted.zip.enc -out .encrypted.zip -d
  unzip -q .encrypted.zip
  if ! is_dir "${ENCRYPTED_DIR}"; then
    echo "Failed to locate decrypted files."
    exit 1
  fi

  travis_fold start macos_signing "...preparing signing..."
  KEY_CHAIN=macos-build.keychain
  security create-keychain -p travis "${KEY_CHAIN}"
  security default-keychain -s "${KEY_CHAIN}"
  security unlock-keychain -p travis "${KEY_CHAIN}"
  security set-keychain-settings -t 3600 -u "${KEY_CHAIN}"
  security import "${ENCRYPTED_DIR}/sign.cer" -k ~/Library/Keychains/"${KEY_CHAIN}" -T /usr/bin/codesign
  security import "${ENCRYPTED_DIR}/sign.p12" -k ~/Library/Keychains/"${KEY_CHAIN}" -P "${CERT_PASSWORD}" -T /usr/bin/codesign
  travis_fold end macos_signing
fi

source "prepare_aio.sh"
source "prepare_mac.sh"
source "prepare_lin.sh"
source "prepare_win.sh"
if is_32bit; then
  source "prepare_armv6.sh"
fi

if is_master_branch; then
  travis_fold start upload_files "...uploading all files to files.squeak.org..."
  TARGET_PATH="/var/www/files.squeak.org"
  if is_etoys; then
    TARGET_PATH="${TARGET_PATH}/etoys/${SQUEAK_VERSION/Etoys/}"
  else
    TARGET_PATH="${TARGET_PATH}/${SQUEAK_VERSION/Squeak/}"
  fi
  TARGET_PATH="${TARGET_PATH}/${IMAGE_NAME}"
  chmod 600 "${ENCRYPTED_DIR}/ssh_deploy_key"
  ssh-keyscan -t ecdsa-sha2-nistp256 -p "${ENCRYPTED_PROXY_PORT}" "${ENCRYPTED_PROXY_HOST}" 2>&1 | tee -a "${HOME}/.ssh/known_hosts" > /dev/null;
  echo "${ENCRYPTED_HOST} ecdsa-sha2-nistp256 ${ENCRYPTED_PUBLIC_KEY}" | tee -a "${HOME}/.ssh/known_hosts" > /dev/null;
  rsync -rvz --ignore-existing -e "ssh -o ProxyCommand='ssh -l ${ENCRYPTED_PROXY_USER} -i ${ENCRYPTED_DIR}/ssh_deploy_key -p ${ENCRYPTED_PROXY_PORT} -W %h:%p ${ENCRYPTED_PROXY_HOST}' -l ${ENCRYPTED_USER} -i ${ENCRYPTED_DIR}/ssh_deploy_key" "${PRODUCT_DIR}/" "${ENCRYPTED_HOST}:${TARGET_PATH}/";
  travis_fold end upload_files

  # Remove sensitive information
  rm -rf "${ENCRYPTED_DIR}"
  security delete-keychain "${KEY_CHAIN}"
else
  echo "...not uploading files because this is not the master branch."
fi
