#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_image.sh
#  CONTENT: Prepare appropriate base image.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

echo "Preparing ${TRAVIS_SMALLTALK_VERSION}..."

echo "...downloading and extracting image, changes, and sources..."
curl -f -s --retry 3 -o "${TMP_DIR}/base.zip" "${IMAGE_URL}"

# Not all versions might have 64-bit base images. Skip in that case.
if [[ ! -f "${TMP_DIR}/base.zip" ]]; then
  echo "Base image not found at ${IMAGE_URL}!"
  exit 1
fi

unzip -q "${TMP_DIR}/base.zip" -d "${TMP_DIR}/"
mv "${TMP_DIR}/"*.image "${TMP_DIR}/Squeak.image"
mv "${TMP_DIR}/"*.changes "${TMP_DIR}/Squeak.changes"

echo "...launching, updating, and configuring Squeak..."
"${TMP_DIR}/${VM_MAC}/CogSpur.app/Contents/MacOS/Squeak" "-exitonwarn" \
    "-headless" "${TMP_DIR}/Squeak.image" "${TRAVIS_BUILD_DIR}/prepare_image.st"
source "${TMP_DIR}/version.sh"

readonly IMAGE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${IMAGE_BITS}bit"

echo "...done."