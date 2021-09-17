#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_image_post.sh
#  CONTENT: Prepare content around the base image.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

download_and_prepare_additional_files_for_etoys() {
  begin_group "...preparing Etoys main projects..."
  for project in "${HOME_DIR}/etoys/"*.[0-9]*; do
    zip -j "${project}.zip" "${project}"/*
    mv "${project}.zip" "${TMP_DIR}/${project##*/}.pr"
  done
  end_group

  begin_group "...preparing etoys gallery projects..."
  mkdir -p "${TMP_DIR}/ExampleEtoys"
  for project in "${HOME_DIR}/etoys/ExampleEtoys/"*.[0-9]*; do
    zip -j "${project}.zip" "${project}"/*
    mv "${project}.zip" "${TMP_DIR}/ExampleEtoys/${project##*/}.pr"
  done
  end_group

  echo "...copying etoys quick guides..."
  for language in "${HOME_DIR}/etoys/QuickGuides/"*; do
    targetdir="${TMP_DIR}/locale/${language##*/}"
    mkdir -p "${targetdir}"
    cp -R "${language}/QuickGuides" "${targetdir}/"
  done
}

rename_and_move_image() {
  echo "...copying image files into build dir..."
  cp "${TMP_DIR}/Squeak.image" "${BUILD_DIR}/${IMAGE_NAME}.image"
  cp "${TMP_DIR}/Squeak.changes" "${BUILD_DIR}/${IMAGE_NAME}.changes"
}

prepare_locales() {
  begin_group "Preparing locales (1/2): Installing gettext..."
  brew update
  brew install gettext
  brew link --force gettext
  end_group

  begin_group "Preparing locales (2/2): Compiling translations..."
  for language in "${LOCALE_DIR}/"*; do
    pushd "${language}"
    targetdir="${TMP_DIR}/locale/${language##*/}/LC_MESSAGES"
    for f in *.po; do
      mkdir -p "${targetdir}"
      msgfmt -v -o "${targetdir}/${f%%po}mo" "${f}" || true # ignore translation problems
    done
    popd
  done
  end_group
}

if is_etoys; then
  download_and_prepare_additional_files_for_etoys
fi

prepare_locales

# Source in version.sh file produced by image
source "${VERSION_FILE}"
readonly IMAGE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${IMAGE_BITS}bit"
readonly SQUEAK_VERSION_NUMBER=$(echo "${SQUEAK_VERSION}" | sed "s/^[A-Za-z]*\(.*\)$/\1/")
readonly WINDOW_TITLE="${SMALLTALK_NAME} ${SQUEAK_VERSION_NUMBER} (${IMAGE_BITS} bit)"

export_variable "SQUEAK_VERSION" "${SQUEAK_VERSION}"
export_variable "SQUEAK_UPDATE" "${SQUEAK_UPDATE}"
export_variable "IMAGE_BITS" "${IMAGE_BITS}"
export_variable "IMAGE_FORMAT" "${IMAGE_FORMAT}"

export_variable "IMAGE_NAME" "${IMAGE_NAME}"
export_variable "SQUEAK_VERSION_NUMBER" "${SQUEAK_VERSION_NUMBER}"
export_variable "WINDOW_TITLE" "${WINDOW_TITLE}"

begin_group "Finalizing image..."
rename_and_move_image
compress "${IMAGE_NAME}"
end_group
