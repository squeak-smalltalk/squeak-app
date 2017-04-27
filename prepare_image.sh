#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_image.sh
#  CONTENT: Prepare appropriate base image.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

download_and_prepare_files() {
  print_info "...downloading and extracting image, changes, and sources..."
  curl -f -s --retry 3 -o "${TMP_DIR}/base.zip" "${IMAGE_URL}"

  if [[ ! -f "${TMP_DIR}/base.zip" ]]; then
    echo "Base image not found at ${IMAGE_URL}!"
    exit 1
  fi

  unzip -q "${TMP_DIR}/base.zip" -d "${TMP_DIR}/"
  mv "${TMP_DIR}/"*.image "${TMP_DIR}/Squeak.image"
  mv "${TMP_DIR}/"*.changes "${TMP_DIR}/Squeak.changes"
  cp -R "${RELEASE_NOTES_DIR}" "${TMP_DIR}/"
  cp "${ICONS_DIR}/balloon.png" "${TMP_DIR}/"

  if is_etoys; then
    download_and_prepare_additional_files_for_etoys
  fi
}

download_and_prepare_additional_files_for_etoys() {
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
}

prepare_image() {
  travis_fold start prepare_image "...launching, updating, and configuring Squeak..."
  # Do not use -headless here, otherwise there is a problem with the image's initial dimensions
  "${SMALLTALK_VM}" "${TMP_DIR}/Squeak.image" \
      "${TRAVIS_BUILD_DIR}/prepare_image.st" "${TRAVIS_SMALLTALK_VERSION}"
  travis_fold end prepare_image
  if ! is_file "${VERSION_FILE}"; then
    echo "Image preparation failed: version.sh file was not exported."
    exit 1
  fi
}

test_image() {
  local ston_config="default.ston"

  case "${TRAVIS_SMALLTALK_VERSION}" in
    "Squeak-trunk"*|"Squeak-5.1"*|"Squeak-5.0")
      ston_config="${TRAVIS_SMALLTALK_VERSION}.ston"
      ;;
  esac

  cp "${TMP_DIR}/Squeak.image" "${TMP_DIR}/Test.image"
  cp "${TMP_DIR}/Squeak.changes" "${TMP_DIR}/Test.changes"

  travis_fold start test_image "...testing Squeak..."
  "${SMALLTALK_VM}" -headless "${TMP_DIR}/Test.image" \
      "${TRAVIS_BUILD_DIR}/test_image.st" "${TRAVIS_SMALLTALK_VERSION}" \
      "${SMALLTALK_CI_HOME}" "${TRAVIS_BUILD_DIR}/smalltalk-ci/${ston_config}"
  check_test_status
  travis_fold end test_image
}

check_test_status() {
  local test_status_file="build_status.txt"
  local build_status

  # Temporarily disable test status check for trunk builds. Remove this check as
  # soon as all tests are running in trunk (hopefully soon).
  if is_trunk; then
    return 0
  fi

  if ! is_file "${TMP_DIR}/${test_status_file}"; then
    echo "Build failed before tests were performed correctly."
    exit 1
  fi
  build_status=$(cat "${TMP_DIR}/${test_status_file}")
  if is_nonzero "${build_status}"; then
    exit 1
  fi
}

rename_and_move_image() {
  echo "...copying image files into build dir..."
  cp "${TMP_DIR}/Squeak.image" "${BUILD_DIR}/${IMAGE_NAME}.image"
  cp "${TMP_DIR}/Squeak.changes" "${BUILD_DIR}/${IMAGE_NAME}.changes"
}

prepare_locales() {
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
}

print_info "...starting to build ${TRAVIS_SMALLTALK_VERSION}..."
download_and_prepare_files
prepare_image
if ! is_etoys; then
  test_image
fi

# prepare locales for Squeak later than 5.0
if ! is_Squeak_50; then
  prepare_locales
fi

# Source in version.sh file produced by image
source "${VERSION_FILE}"
readonly IMAGE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${IMAGE_BITS}bit"
readonly SQUEAK_VERSION_NUMBER=$(echo "${SQUEAK_VERSION}" | sed "s/^[A-Za-z]*\(.*\)$/\1/")
readonly WINDOW_TITLE="${SMALLTALK_NAME} ${SQUEAK_VERSION_NUMBER} (${IMAGE_BITS} bit)"

rename_and_move_image
compress "${IMAGE_NAME}"
