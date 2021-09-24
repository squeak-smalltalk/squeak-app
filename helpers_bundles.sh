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

reset_build_dir() {
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
