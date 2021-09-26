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

  download_and_extract_vm "macOS" "${VM_BASE}/${VM_MAC}.zip" "${TMP_PATH}/${VM_MAC}"
  download_and_extract_vm "Linux" "${VM_BASE}/${VM_LIN}.zip" "${TMP_PATH}/${VM_LIN}"
  download_and_extract_vm "Windows" "${VM_BASE}/${VM_WIN}.zip" "${TMP_PATH}/${VM_WIN}"

  # ARMv6 currently only supported on 32-bit
  if is_32bit; then
    download_and_extract_vm "ARMv6" "${VM_BASE}/${VM_ARM6}.zip" "${TMP_PATH}/${VM_ARM6}"
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
