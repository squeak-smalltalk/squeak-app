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

if [[ ! -f "${TMP_DIR}/base.zip" ]]; then
  echo "Base image not found at ${IMAGE_URL}!"
  exit 1
fi

unzip -q "${TMP_DIR}/base.zip" -d "${TMP_DIR}/"
mv "${TMP_DIR}/"*.image "${TMP_DIR}/Squeak.image"
mv "${TMP_DIR}/"*.changes "${TMP_DIR}/Squeak.changes"
mv "${ICONS_DIR}/balloon.png" "${TMP_DIR}/balloon.png"

echo "...launching, updating, and configuring Squeak..."
"${TMP_DIR}/${VM_BUILD}/CogSpur.app/Contents/MacOS/Squeak" "-exitonwarn" \
    "${TMP_DIR}/Squeak.image" "${TRAVIS_BUILD_DIR}/prepare_image.st" "${TRAVIS_SMALLTALK_VERSION}"
source "${TMP_DIR}/version.sh"

readonly IMAGE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${IMAGE_BITS}bit"

echo "...copying image files into build dir..."
cp "${TMP_DIR}/Squeak.image" "${BUILD_DIR}/${IMAGE_NAME}.image"
cp "${TMP_DIR}/Squeak.changes" "${BUILD_DIR}/${IMAGE_NAME}.changes"

travis_fold start install_gettext "...installing gettext..."
brew update
brew install gettext
brew link --force gettext
travis_fold end install_gettext

travis_fold start prepare_translations "...preparing translations and putting them into bundle..."
for language in "${LOCALE_DIR}/"*; do
  pushd "${language}"
  targetdir="${TMP_DIR}/locale/${language##*/}/LC_MESSAGES"
  for f in *.po; do
    mkdir -p "${targetdir}"
    msgfmt -v -o "${targetdir}/${f%%po}mo" "${f}" || true # ignore translation problems
  done
  popd
done
travis_fold end prepare_translations

if is_etoys; then
  travis_fold start main_projects "...preparing etoys main projects..."
  for project in "${TRAVIS_BUILD_DIR}/etoys/"*.[0-9]*; do
    zip -j "${project}.zip" "${project}"/*
    mv "${project}.zip" "${TMP_DIR}/${project##*/}.pr"
  done
  travis_fold end main_projects

  travis_fold start gallery_projects "...preparing etoys gallery projects..."
  mkdir -p "${TMP_DIR}/ExampleEtoys"
  for project in "${TRAVIS_BUILD_DIR}/etoys/ExampleEtoys/"*.[0-9]*; do
    zip -j "${project}.zip" "${project}"/*
    mv "${project}.zip" "${TMP_DIR}/ExampleEtoys/${project##*/}.pr"
  done
  travis_fold end gallery_projects

  echo "...copying etoys quick guides..."
  for language in "${TRAVIS_BUILD_DIR}/etoys/QuickGuides/"*; do
    targetdir="${TMP_DIR}/locale/${language##*/}"
    mkdir -p "${targetdir}"
    cp -R "${language}/QuickGuides" "${targetdir}/"
  done
fi

compress "${IMAGE_NAME}"
