#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_lin.sh
#  CONTENT: Generate bundle for Linux.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating Linux bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_LIN="${IMAGE_NAME}-${VERSION_VM_LINUX}-Linux"
BUNDLE_DIR="${BUILD_DIR}/${BUNDLE_NAME_LIN}"
VM_DIR="${BUNDLE_DIR}/bin"
SHARED_DIR="${BUNDLE_DIR}/shared"

echo "...creating directories..."
mkdir -p "${BUNDLE_DIR}" "${VM_DIR}" "${SHARED_DIR}"

echo "...copying Linux VM..."
cp -R "${TMP_DIR}/${VM_LIN}/lib/squeak/"*/ "${VM_DIR}"

copy_resources "${SHARED_DIR}"

echo "...merging template..."
cp "${LIN_TEMPLATE_DIR}/squeak.sh" "${BUNDLE_DIR}/"

echo "...setting permissions..."
chmod +x "${VM_DIR}/squeak" "${BUNDLE_DIR}/squeak.sh"

compress "${BUNDLE_NAME_LIN}"

end_group
