download_and_extract_all_vms() {
  begin_group "Downloading and extracting all VMs..."

  echo "...downloading and sourcing VM versions file..."
  curl -f -s --retry 3 -o "${TMP_PATH}/vm-versions" "${VM_BASE}/${VM_VERSIONS}"
  source "${TMP_PATH}/vm-versions"

  if is_64bit; then

    if [[ -z "${VERSION_VM_LINUX_ARM}" ]] || \
       [[ -z "${VERSION_VM_LINUX_X86}" ]] || \
       [[ -z "${VERSION_VM_MACOS_ARM}" ]] || \
       [[ -z "${VERSION_VM_MACOS_X86}" ]] || \
       [[ -z "${VERSION_VM_WIN_X86}" ]]; then
      print_error "...could not determine all required VM versions!"
      exit 1
    fi

    download_and_extract_vm "macOS (x64)" "${VM_BASE}/${VM_MAC_X86}.zip" "${TMP_PATH}/${VM_MAC_X86}"
    download_and_extract_vm "macOS (ARMv8)" "${VM_BASE}/${VM_MAC_ARM}.zip" "${TMP_PATH}/${VM_MAC_ARM}"
    # unified binary will be constructed on-the-fly
    # download_and_extract_vm "macOS (unified)" "${VM_BASE}/${VM_MAC}.zip" "${TMP_PATH}/${VM_MAC}"
    download_and_extract_vm "Linux (x64)" "${VM_BASE}/${VM_LIN_X86}.zip" "${TMP_PATH}/${VM_LIN_X86}"
    download_and_extract_vm "Linux (ARMv8)" "${VM_BASE}/${VM_LIN_ARM}.zip" "${TMP_PATH}/${VM_LIN_ARM}"
    download_and_extract_vm "Windows (x64)" "${VM_BASE}/${VM_WIN_X86}.zip" "${TMP_PATH}/${VM_WIN_X86}"
  else # 32-bit

    if [[ -z "${VERSION_VM_LINUX_ARM}" ]] || \
       [[ -z "${VERSION_VM_LINUX_X86}" ]] || \
       [[ -z "${VERSION_VM_WIN_X86}" ]]; then
      print_error "...could not determine all required VM versions!"
      exit 1
    fi

    download_and_extract_vm "Linux (x86)" "${VM_BASE}/${VM_LIN_X86}.zip" "${TMP_PATH}/${VM_LIN_X86}"
    download_and_extract_vm "Linux (ARMv6)" "${VM_BASE}/${VM_LIN_ARM}.zip" "${TMP_PATH}/${VM_LIN_ARM}"
    download_and_extract_vm "Windows (x86)" "${VM_BASE}/${VM_WIN_X86}.zip" "${TMP_PATH}/${VM_WIN_X86}"    
  fi

  end_group
}

download_and_extract_all_vms_rc() {
  begin_group "Downloading and extracting all VMs (RC ${VM_RC_TAG})..."

  echo "...downloading and sourcing VM versions file..."
  # Use latest release candidate of OSVM
  # https://github.com/OpenSmalltalk/opensmalltalk-vm/releases/tag/202112201228
  readonly VERSION_VM_LINUX_X86="${VM_RC_TAG}"
  readonly VERSION_VM_MACOS_X86="${VM_RC_TAG}"
  readonly VERSION_VM_WIN_X86="${VM_RC_TAG}"
  readonly VERSION_VM_LINUX_ARM="${VM_RC_TAG}"
  readonly VERSION_VM_MACOS_ARM="${VM_RC_TAG}"
  readonly VERSION_VM_WIN_ARM="n/a"

  if is_64bit; then
    download_and_extract_vm "macOS (x64)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_macos64x64.dmg" \
      "${TMP_PATH}/${VM_MAC_X86}"
    download_and_extract_vm "macOS (ARMv8)" \
      "${VM_RC_BASE}/${VM_RC_TAG}/squeak.cog.spur_macos64ARMv8.dmg" \
      "${TMP_PATH}/${VM_MAC_ARM}"
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
    readonly BUNDLE_NAME_MAC_SUFFIX="macOS"
    readonly BUNDLE_NAME_MAC_X86_SUFFIX="macOS-x64"
    readonly BUNDLE_NAME_MAC_ARM_SUFFIX="macOS-ARMv8"
    readonly BUNDLE_NAME_WIN_X86_SUFFIX="Windows-x64"
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
    readonly BUNDLE_NAME_MAC_SUFFIX="" # n/a for 32-bit
    readonly BUNDLE_NAME_MAC_X86_SUFFIX="" # n/a for 32-bit
    readonly BUNDLE_NAME_MAC_ARM_SUFFIX="" # n/a for 32-bit
    readonly BUNDLE_NAME_WIN_X86_SUFFIX="Windows-x86"
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

# Make a fat binary from a pair of VMs in
# build.macos64{x64,ARMv8}/virtend.cog.spur/Virtend*.app
# To choose the oldest nib the oldest deployment target (x86_64) should be last
create_unified_vm_macOS() {
  local MISMATCHINGNIBS=
  local MISMATCHINGPLISTS=

  readonly O="$1"
  readonly A="$2"
  readonly B="$3"

  if [ ! -d "$A" ]; then
    echo "$A does not exist; aborting"
    exit 44
  fi

  if [ ! -d "$B" ]; then
    echo "$B does not exist; aborting"
    exit 45
  fi

  echo "merging $A \& $B into $O..."
  mkdir -p $O

  for f in `cd $A >/dev/null; find . | sed 's|^\.\/||'`; do
    if [ -d "$A/$f" ]; then
      mkdir -p $O/$f
    # elif [ -L "$A/$f" ]; then
    #   echo ln -s `readlink "$A/$f"` "$O/$f"
    elif [ ! -f "$A/$f" ]; then
      echo  "$A/$f does not exist; how come?"
    elif [ ! -f "$B/$f" ]; then
      echo  "$B/$f does not exist; how come?"
    else
      case `file -b "$A/$f"` in
        Mach-O*)
          lipo -create -output "$O/$f" "$A/$f" "$B/$f";;
        *)
          if cmp -s "$A/$f" "$B/$f"; then
            cp "$A/$f" "$O/$f"
          else
            echo "EXCLUDING $f because it differs"
            case "$f" in
              *.plist)
                MISMATCHINGPLISTS="$MISMATCHINGPLISTS $f"
                ;;
              *.nib)
                MISMATCHINGNIBS="$MISMATCHINGNIBS   $f"
                echo "using $B version"
                cp "$B/$f" "$O/$f"
                ;;
            esac
          fi
      esac
    fi
  done

  if [ -n "$MISMATCHINGPLISTS" ]; then
    echo "Builds $A \& $B are NOT in perfect sync. Rebuild one or other to resolve"
    for f in $MISMATCHINGPLISTS; do
      echo "$f"
      diff $A/$f $B/$f
    done
    exit 46
  fi

  if [ -n "$MISMATCHINGNIBS" ]; then
    echo "Builds $A \& $B are NOT in perfect sync. ui nibs differ. Took $B\'s"
    for f in $MISMATCHINGNIBS; do
      echo $f
    done
  fi
}