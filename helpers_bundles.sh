download_and_extract_all_vms() {
  begin_group "Downloading and extracting all VMs..."

  echo "...downloading and sourcing VM versions file..."
  curl -f -s --retry 3 -o "${TMP_PATH}/vm-versions" "${VM_BASE}/${VM_VERSIONS}"
  source "${TMP_PATH}/vm-versions"
  if [[ -z "${VERSION_VM_ARMV6}" ]] || [[ -z "${VERSION_VM_LINUX}" ]] || \
     [[ -z "${VERSION_VM_MACOS}" ]] || [[ -z "${VERSION_VM_WIN}" ]]; then
    print_error "...could not determine all required VM versions!"
    exit 1
  fi

  download_and_extract_vm "macOS" "${VM_BASE}/${VM_MAC_X86}.zip" "${TMP_PATH}/${VM_MAC_X86}"
  download_and_extract_vm "Linux" "${VM_BASE}/${VM_LIN_X86}.zip" "${TMP_PATH}/${VM_LIN_X86}"
  download_and_extract_vm "Windows" "${VM_BASE}/${VM_WIN_X86}.zip" "${TMP_PATH}/${VM_WIN_X86}"

  # ARMv6 currently only supported on 32-bit
  if is_32bit; then
    download_and_extract_vm "ARMv6" "${VM_BASE}/${VM_ARM6}.zip" "${TMP_PATH}/${VM_ARM6}"
  fi

  end_group
}

download_and_extract_all_vms_rc() {
  begin_group "Downloading and extracting all VMs (release candidate)..."

  echo "...downloading and sourcing VM versions file..."
  # Use latest release candidate of OSVM
  # https://github.com/OpenSmalltalk/opensmalltalk-vm/releases/tag/202112201228
  readonly VERSION_VM_LINUX="${VM_RC_TAG}"
  readonly VERSION_VM_MACOS="${VM_RC_TAG}"
  readonly VERSION_VM_WIN="${VM_RC_TAG}"
  readonly VERSION_VM_LINUX_ARM="${VM_RC_TAG}"
  readonly VERSION_VM_MACOS_ARM="${VM_RC_TAG}"
  readonly VERSION_VM_WIN_ARM="n/a"

  if is_64bit; then
    download_and_extract_vm "macOS (x64)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_macos64x64.dmg" \
      "${TMP_PATH}/${VM_MAC_X86}/Squeak.app"
    download_and_extract_vm "macOS (ARMv8)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_macos64ARMv8.dmg" \
      "${TMP_PATH}/${VM_MAC_ARM}/Squeak.app"
    download_and_extract_vm "Linux (x64)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_linux64x64.tar.gz" \
      "${TMP_PATH}/${VM_LIN_X86}"
    download_and_extract_vm "Linux (ARMv8)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_linux64ARMv8.tar.gz" \
      "${TMP_PATH}/${VM_LIN_ARM}"
    download_and_extract_vm "Windows (x64)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_win64x64.zip" \
      "${TMP_PATH}/${VM_WIN_X86}"

    readonly BUNDLE_NAME_LIN_X86_SUFFIX="Linux-x64"
    readonly BUNDLE_NAME_LIN_ARM_SUFFIX="Linux-ARMv8"
    readonly BUNDLE_NAME_MAC_X86_SUFFIX="macOS-x64"
    readonly BUNDLE_NAME_MAC_ARM_SUFFIX="macOS-ARMv8"
    readonly BUNDLE_NAME_WIN_X86_SUFFIX="Windows"
    readonly BUNDLE_NAME_WIN_ARM_SUFFIX="" # n/a

  else # 32-bit
    echo "(No support for 32-bit macOS anymore.)"
    download_and_extract_vm "Linux (x86)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_linux32x86.tar.gz" \
      "${TMP_PATH}/${VM_LIN_X86}"
    download_and_extract_vm "Linux (ARMv6)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_linux32ARMv6.tar.gz" \
      "${TMP_PATH}/${VM_LIN_ARM}"
    download_and_extract_vm "Windows (x86)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_win32x86.zip" \
      "${TMP_PATH}/${VM_WIN_X86}"

    readonly BUNDLE_NAME_LIN_X86_SUFFIX="Linux-x86"
    readonly BUNDLE_NAME_LIN_ARM_SUFFIX="Linux-ARMv6"
    readonly BUNDLE_NAME_MAC_X86_SUFFIX="" # n/a for 32-bit
    readonly BUNDLE_NAME_MAC_ARM_SUFFIX="" # n/a for 32-bit
    readonly BUNDLE_NAME_WIN_X86_SUFFIX="Windows"
    readonly BUNDLE_NAME_WIN_ARM_SUFFIX="" # n/a
  fi

  end_group
}

compress_into_product() {
  target=$1
  echo "...compressing $target..."
  pushd "${BUILD_PATH}" > /dev/null
  # tar czf "${PRODUCT_PATH}/${target}.tar.gz" "./"
  zip -q -r "${PRODUCT_PATH}/${target}.zip" "./"
  popd > /dev/null
}

compress_into_product_macOS() {
  source_path=$1
  target_name=$2
  target_path="${PRODUCT_PATH}/${target_name}.dmg"

  if [[ ! $(type -t hdiutil) ]]; then
    print_warning "...Cannot compress into DMG because hdiutil not found."
    compress_into_product $target_name
    return
  fi

  echo "...compressing $target as DMG for macOS..."
  TMP_DMG="temp.dmg"
  hdiutil create -size 192m -volname "${target_name}" -srcfolder "${source_path}" \
      -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -nospotlight "${TMP_DMG}"
  DEVICE="$(hdiutil attach -readwrite -noautoopen -nobrowse "${TMP_DMG}" | awk 'NR==1{print$1}')"
  VOLUME="$(mount | grep "${DEVICE}" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')"
  hdiutil detach "${DEVICE}"
  hdiutil convert "${TMP_DMG}" -format UDBZ -imagekey bzip2-level=6 -o "${target_path}"
  rm -f "${TMP_DMG}"

if should_codesign; then
  do_codesign "${target_path}" # *.dmg
  if should_notarize; then
    do_notarize "${target_path}" # *.dmg
  fi
fi
}

reset_build_dir() {
  rm -rf "${BUILD_PATH}" && mkdir "${BUILD_PATH}"
}

copy_resources() {
  local target=$1
  echo "...copying image files into bundle..."
  cp "${TMP_PATH}/Squeak.image" "${target}/${IMAGE_NAME}.image"
  cp "${TMP_PATH}/Squeak.changes" "${target}/${IMAGE_NAME}.changes"
  cp "${TMP_PATH}/"*.sources "${target}/"

  cp -R "${RELEASE_NOTES_PATH}" "${target}/"
  cp -R "${TMP_PATH}/locale" "${target}/"

  if is_etoys; then
    cp "${TMP_PATH}/"*.pr "${target}/"
    cp -R "${TMP_PATH}/ExampleEtoys" "${target}/"
  fi
}
