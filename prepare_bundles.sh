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

readonly TEMPLATE_DIR="${HOME_DIR}/templates"
readonly AIO_TEMPLATE_DIR="${TEMPLATE_DIR}/all-in-one"
readonly LIN_TEMPLATE_DIR="${TEMPLATE_DIR}/linux"
readonly MAC_TEMPLATE_DIR="${TEMPLATE_DIR}/macos"
readonly WIN_TEMPLATE_DIR="${TEMPLATE_DIR}/win"

readonly BUILD_DIR="${HOME_DIR}/build"

readonly PRODUCT_DIR="${HOME_DIR}/product"
export_variable "PRODUCT_DIR" "${PRODUCT_DIR}"

readonly LOCALE_DIR="${HOME_DIR}/locale"

readonly VM_LIN="vm-linux"
readonly VM_MAC="vm-macos"
readonly VM_WIN="vm-win"
readonly VM_ARM6="vm-armv6"
readonly VM_VERSIONS="versions.txt"

readonly ENCRYPTED_DIR="${HOME_DIR}/encrypted"
export_variable "ENCRYPTED_DIR" "${ENCRYPTED_DIR}"

if is_etoys; then
  readonly SMALLTALK_NAME="Etoys"
else
  readonly SMALLTALK_NAME="Squeak"
fi

# Create build, product, and temp folders
mkdir -p "${BUILD_DIR}" "${PRODUCT_DIR}" "${TMP_DIR}"

download_and_extract_vms() {
  begin_group "Downloading and extracting all VMs..."

  echo "...downloading and sourcing VM versions file..."
  curl -f -s --retry 3 -o "${TMP_DIR}/vm-versions" "${VM_BASE}/${VM_VERSIONS}"
  source "${TMP_DIR}/vm-versions"
  if [[ -z "${VERSION_VM_ARMV6}" ]] || [[ -z "${VERSION_VM_LINUX}" ]] || \
     [[ -z "${VERSION_VM_MACOS}" ]] || [[ -z "${VERSION_VM_WIN}" ]]; then
    print_error "...could not determine all required VM versions!"
    exit 1
  fi

  download_and_extract_vm "macOS" "${VM_BASE}/${VM_MAC}.zip" "${TMP_DIR}/${VM_MAC}"
  download_and_extract_vm "Linux" "${VM_BASE}/${VM_LIN}.zip" "${TMP_DIR}/${VM_LIN}"
  download_and_extract_vm "Windows" "${VM_BASE}/${VM_WIN}.zip" "${TMP_DIR}/${VM_WIN}"

  # ARMv6 currently only supported on 32-bit
  if is_32bit; then
    download_and_extract_vm "ARMv6" "${VM_BASE}/${VM_ARM6}.zip" "${TMP_DIR}/${VM_ARM6}"
  fi

  end_group
}

compress() {
  target=$1
  echo "...compressing $target..."
  pushd "${BUILD_DIR}" > /dev/null
  # tar czf "${PRODUCT_DIR}/${target}.tar.gz" "./"
  zip -q -r "${PRODUCT_DIR}/${target}.zip" "./"
  popd > /dev/null
}

reset_buildir() {
  rm -rf "${BUILD_DIR}" && mkdir "${BUILD_DIR}"
}

copy_resources() {
  local target=$1
  echo "...copying image files into bundle..."
  cp "${TMP_DIR}/Squeak.image" "${target}/${IMAGE_NAME}.image"
  cp "${TMP_DIR}/Squeak.changes" "${target}/${IMAGE_NAME}.changes"
  cp "${TMP_DIR}/"*.sources "${target}/"

  cp -R "${RELEASE_NOTES_DIR}" "${target}/"
  cp -R "${TMP_DIR}/locale" "${target}/"

  if is_etoys; then
    cp "${TMP_DIR}/"*.pr "${target}/"
    cp -R "${TMP_DIR}/ExampleEtoys" "${target}/"
  fi
}

codesign_bundle() {
  local target=$1

  echo "...signing the bundle..."

  xattr -cr "${target}" # Remove all extended attributes from app bundle

  # Sign all plugin bundles
  for d in "${target}/Contents/Resources/"*/; do
    if [[ "${d}" == *".bundle/" ]]; then
      codesign -s "${SIGN_IDENTITY}" --force --deep --verbose "${d}"
    fi
  done

  # Sign the app bundle
  codesign -s "${SIGN_IDENTITY}" --force --deep --verbose --options=runtime \
    --entitlements "${MAC_TEMPLATE_DIR}/entitlements.plist" "${target}"
}

notarize() {
  local path=$1

  if ! command -v xcnotary >/dev/null 2>&1; then
    echo "...installing xcnotary helper..."
    curl -sL https://github.com/akeru-inc/xcnotary/releases/download/v0.4.8/xcnotary-0.4.8.catalina.bottle.tar.gz | \
      tar -zxvf - --strip-components=3 xcnotary/0.4.8/bin/xcnotary
    chmod +x xcnotary
  fi

  echo "...notarizing the bundle..."
  ./xcnotary notarize "${path}" \
    --developer-account "${NOTARIZATION_USER}" \
    --developer-password-keychain-item "ALTOOL_PASSWORD"
}

download_and_extract_vms

source "prepare_image_post.sh"

if is_deployment_branch && [[ ! -z "${ENCRYPTED_KEY}" ]]; then
  # Decrypt and extract sensitive files
  openssl aes-256-cbc -K "${ENCRYPTED_KEY}" \
    -iv "${ENCRYPTED_IV}" -in .encrypted.zip.enc -out .encrypted.zip -d
  unzip -q .encrypted.zip
  if ! is_dir "${ENCRYPTED_DIR}"; then
    echo "Failed to locate decrypted files."
    exit 1
  fi

  begin_group "...preparing signing..."
  KEY_CHAIN=macos-build.keychain
  export_variable "KEY_CHAIN" "${KEY_CHAIN}" # for deploy_bundles.sh
  # Create the keychain with a password
  security create-keychain -p github-actions "${KEY_CHAIN}"
  # Make the custom keychain default, so xcodebuild will use it for signing
  security default-keychain -s "${KEY_CHAIN}"
  # Unlock the keychain
  security unlock-keychain -p github-actions "${KEY_CHAIN}"
  # Add certificates to keychain and allow codesign to access them
  security import "${ENCRYPTED_DIR}/sign.cer" -k ~/Library/Keychains/"${KEY_CHAIN}" -T /usr/bin/codesign > /dev/null
  security import "${ENCRYPTED_DIR}/sign.p12" -k ~/Library/Keychains/"${KEY_CHAIN}" -P "${CERT_PASSWORD}" -T /usr/bin/codesign > /dev/null
  # Make codesign work on macOS 10.12 or later (see https://git.io/JvE7X)
  security set-key-partition-list -S apple-tool:,apple: -s -k travis "${KEY_CHAIN}" > /dev/null
  # Store notarization password in keychain for xcnotary
  xcrun altool --store-password-in-keychain-item "ALTOOL_PASSWORD" -u "${NOTARIZATION_USER}" -p "${NOTARIZATION_PASSWORD}"
  end_group
else
  print_warning "Cannot prepare signing because secret missing."
fi

reset_buildir
source "prepare_aio.sh"
reset_buildir
source "prepare_mac.sh"
reset_buildir
source "prepare_lin.sh"
reset_buildir
source "prepare_win.sh"
reset_buildir
if is_32bit; then
  source "prepare_armv6.sh"
fi
