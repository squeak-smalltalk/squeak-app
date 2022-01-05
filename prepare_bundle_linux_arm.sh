#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundle_linux_arm.sh
#  CONTENT: Generate bundle for ARMv6 (32-bit) and ARMv8 (64-bit).
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating ARM bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_LIN_ARM="${IMAGE_NAME}-${VERSION_VM_LINUX_ARM}-${BUNDLE_NAME_LIN_ARM_SUFFIX}"
export_variable "BUNDLE_NAME_LIN_ARM" "${BUNDLE_NAME_LIN_ARM}"
BUNDLE_PATH="${BUILD_PATH}/${BUNDLE_NAME_LIN_ARM}"

VM_BASE_PATH="${TMP_PATH}/${VM_LIN_ARM}"
if should_use_rc_vm; then
  # There is an extra indirection in the OSVM builds on GitHub
  # E.g., vm-linux-arm/sqcogspur64ARMv8linuxht/...
  pushd ${VM_BASE_PATH}
  VM_BASE_PATH="${VM_BASE_PATH}/$(find * -type d | head -n 1)"
  popd
fi

VM_PATH="${BUNDLE_PATH}/bin"
SHARED_PATH="${BUNDLE_PATH}/shared"

echo "...creating directories..."
mkdir -p "${BUNDLE_PATH}" "${VM_PATH}" "${SHARED_PATH}"

echo "...copying Linux VM (ARM-based)..."
cp -R "${VM_BASE_PATH}/lib/squeak/"*/* "${VM_PATH}"

copy_resources "${SHARED_PATH}"

echo "...merging template..."
cp "${LIN_TEMPLATE_PATH}/squeak.sh" "${BUNDLE_PATH}/"

echo "...setting permissions..."
chmod +x "${VM_PATH}/squeak"

echo "...applying various templates (squeak.sh)..."
# squeak.sh launcher
sed -i".bak" "s/%VM_NAME%/squeak/g" "${BUNDLE_PATH}/squeak.sh"
rm -f "${BUNDLE_PATH}/squeak.sh.bak"

compress_into_product_Linux "${BUNDLE_NAME_LIN_ARM}"
reset_build_dir

end_group
