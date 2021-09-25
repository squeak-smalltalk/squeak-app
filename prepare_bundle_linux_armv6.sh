#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundle_linux_armv6.sh
#  CONTENT: Generate bundle for ARMv6.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating ARMv6 bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_ARM="${IMAGE_NAME}-${VERSION_VM_ARMV6}-ARMv6"
export_variable "BUNDLE_NAME_ARM" "${BUNDLE_NAME_ARM}"
BUNDLE_PATH="${BUILD_PATH}/${BUNDLE_NAME_ARM}"
VM_PATH="${BUNDLE_PATH}/bin"
SHARED_PATH="${BUNDLE_PATH}/shared"

echo "...creating directories..."
mkdir -p "${BUNDLE_PATH}" "${VM_PATH}" "${SHARED_PATH}"

echo "...copying ARMv6 VM..."
cp -R "${TMP_PATH}/${VM_ARM6}/lib/squeak/"*/ "${VM_PATH}"

copy_resources "${SHARED_PATH}"

echo "...merging template..."
cp "${LIN_TEMPLATE_PATH}/squeak.sh" "${BUNDLE_PATH}/"

echo "...setting permissions..."
chmod +x "${VM_PATH}/squeak"

compress_into_product "${BUNDLE_NAME_ARM}"
reset_build_dir

end_group
