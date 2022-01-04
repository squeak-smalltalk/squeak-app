#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundle_linux.sh
#  CONTENT: Generate bundle for Ubuntu/Linux (x86 and x86_64).
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating Linux bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_LIN_X86="${IMAGE_NAME}-${VERSION_VM_LINUX}-${BUNDLE_NAME_LIN_X86_SUFFIX}"
export_variable "BUNDLE_NAME_LIN_X86" "${BUNDLE_NAME_LIN_X86}"
BUNDLE_PATH="${BUILD_PATH}/${BUNDLE_NAME_LIN_X86}"
VM_PATH="${BUNDLE_PATH}/bin"
SHARED_PATH="${BUNDLE_PATH}/shared"

echo "...creating directories..."
mkdir -p "${BUNDLE_PATH}" "${VM_PATH}" "${SHARED_PATH}"

echo "...copying Linux VM (x86-based)..."
cp -R "${TMP_PATH}/${VM_LIN_X86}/lib/squeak/"*/* "${VM_PATH}"

copy_resources "${SHARED_PATH}"

echo "...merging template..."
cp "${LIN_TEMPLATE_PATH}/squeak.sh" "${BUNDLE_PATH}/"

echo "...setting permissions..."
chmod +x "${VM_PATH}/squeak" "${BUNDLE_PATH}/squeak.sh"

compress_into_product "${BUNDLE_NAME_LIN_X86}"
reset_build_dir

end_group
