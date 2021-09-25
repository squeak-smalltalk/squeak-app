prepare_codesign() {

  if [[ ! $(type -t prepare_codesign_$RUNNER_OS) ]]; then
    print_warning "Cannot prepare code signing because platform not supported: ${RUNNER_OS}"
    return
  fi

  if [[ -z "${CODESIGN_KEY}" ]]; then
    print_warning "Cannot prepare code signing because secret missing."
    return
  fi

  begin_group "...preparing code signing..."
  unlock_secret "codesign" "${CODESIGN_KEY}" "${CODESIGN_IV}"
  readonly CERT_FILEPATH_CER="${HOME_PATH}/secret-codesign/codesign.cer"
  readonly CERT_FILEPATH_P12="${HOME_PATH}/secret-codesign/codesign.p12"
  prepare_codesign_$RUNNER_OS
  prepare_notarize_$RUNNER_OS
  end_group
}

cleanup_codesign() {
  if [[ ! $(type -t prepare_codesign_$RUNNER_OS) ]]; then
    print_warning "Cannot clean-up code signing because platform not supported: ${RUNNER_OS}"
    return
  fi
  begin_group "...cleaning up code signing..."
  cleanup_codesign_$RUNNER_OS
  rm -r -d "{HOME_PATH}/secret-codesign"
  end_group
}

do_codesign() {
  if [[ ! $(type -t do_codesign_$RUNNER_OS) ]]; then
    print_warning "...not code signing because platform not supported: ${RUNNER_OS}."
    return
  fi

  if [[ -z "${CERT_IDENTITY}" ]]; then
    print_warning "...not code signing because secret missing."
    return
  fi

  do_codesign_$RUNNER_OS $1
}

do_notarize() {
  if [[ ! $(type -t do_notarize_$RUNNER_OS) ]]; then
    print_warning "...not notarizing because platform not supported: ${RUNNER_OS}."
    return
  fi

  if [[ -z "${NOTARIZATION_USER}" ]]; then
    print_warning "...not code signing because secret missing."
    return
  fi

  do_notarize_$RUNNER_OS $1
}

prepare_codesign_macOS() {
  KEY_CHAIN=macos-build.keychain
  KEY_CHAIN_PASSWORD=github-actions

  # Create the keychain with a password
  security create-keychain -p "${KEY_CHAIN_PASSWORD}" "${KEY_CHAIN}"
  # removing relock timeout on keychain
  security set-keychain-settings "${KEY_CHAIN}"
  # Add certificates to keychain and allow codesign to access them
  security import "${CERT_FILEPATH_CER}" -k ~/Library/Keychains/"${KEY_CHAIN}" -T /usr/bin/codesign > /dev/null
  security import "${CERT_FILEPATH_P12}" -k ~/Library/Keychains/"${KEY_CHAIN}" -P "${CERT_PASSWORD}" -T /usr/bin/codesign > /dev/null
  # Make codesign work on macOS 10.12 or later (see https://git.io/JvE7X)
  security set-key-partition-list -S apple-tool:,apple: -s -k "${KEY_CHAIN_PASSWORD}" "${KEY_CHAIN}" > /dev/null

  # Make the custom keychain default, so xcodebuild will use it for signing
  security default-keychain -d user -s "${KEY_CHAIN}"
  # Unlock the keychain
  security unlock-keychain -p "${KEY_CHAIN_PASSWORD}" "${KEY_CHAIN}"
}

prepare_notarize_macOS() {
  # Store notarization password in keychain for xcnotary
  xcrun altool --store-password-in-keychain-item "ALTOOL_PASSWORD" -u "${NOTARIZATION_USER}" -p "${NOTARIZATION_PASSWORD}"
}



do_codesign_macOS() {
  local target=$1

  echo "...signing the bundle..."

  xattr -cr "${target}" # Remove all extended attributes from app bundle

  # Sign all plugin bundles
  for d in "${target}/Contents/Resources/"*/; do
    if [[ "${d}" == *".bundle/" ]]; then
      codesign -s "${CERT_IDENTITY}" --force --deep --verbose "${d}"
    fi
  done

  # Sign the app bundle
  codesign -s "${CERT_IDENTITY}" --force --deep --verbose --options=runtime \
    --entitlements "${MAC_TEMPLATE_PATH}/entitlements.plist" "${target}"
}

do_notarize_macOS() {
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

cleanup_codesign_macOS() {
  security delete-keychain "${KEY_CHAIN}"
  #TODO: Remove ALTOOL_PASSWORD from local key chain
}
