#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_image_post.sh
#  CONTENT: Prepare content around the base image.
#
#  REQUIRES:
#    SMALLTALK_VERSION ... e.g., Squeak64-trunk
#    SQUEAK_VERSION    ... e.g., Squeak6.0alpha
#    SQUEAK_UPDATE     ... e.g., 20639
#    IMAGE_BITS        ... i.e., 64 or 32
#    tmp/Squeak.image
#    tmp/Squeak.changes
#    tmp/*.sources
#  PROVIDES:
#    IMAGE_NAME        ... e.g., Squeak6.0alpha-20639-64bit
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

download_and_prepare_additional_files_for_etoys() {
  begin_group "...preparing Etoys main projects..."
  for project in "${HOME_PATH}/etoys/"*.[0-9]*; do
    zip -j "${project}.zip" "${project}"/*
    mv "${project}.zip" "${TMP_PATH}/${project##*/}.pr"
  done
  end_group

  begin_group "...preparing etoys gallery projects..."
  mkdir -p "${TMP_PATH}/ExampleEtoys"
  for project in "${HOME_PATH}/etoys/ExampleEtoys/"*.[0-9]*; do
    zip -j "${project}.zip" "${project}"/*
    mv "${project}.zip" "${TMP_PATH}/ExampleEtoys/${project##*/}.pr"
  done
  end_group

  echo "...copying etoys quick guides..."
  for language in "${HOME_PATH}/etoys/QuickGuides/"*; do
    targetdir="${TMP_PATH}/locale/${language##*/}"
    mkdir -p "${targetdir}"
    cp -R "${language}/QuickGuides" "${targetdir}/"
  done
}

prepare_image_bundle() {
  begin_group "Creating .image/.changes/.sources bundle for ${SMALLTALK_VERSION}..."
  echo "...copying files into build dir..."
  cp "${TMP_PATH}/Squeak.image" "${BUILD_PATH}/${IMAGE_NAME}.image"
  cp "${TMP_PATH}/Squeak.changes" "${BUILD_PATH}/${IMAGE_NAME}.changes"
  cp "${TMP_PATH}/"*.sources "${BUILD_PATH}/"
  compress_into_product "${IMAGE_NAME}"
  reset_build_dir
  end_group
}

prepare_locales() {
  begin_group "Preparing locales (1/2): Installing gettext..."
  brew update
  brew install gettext
  brew link --force gettext
  end_group

  if [[ ! $(type -t msgfmt) ]]; then
    mkdir -p "${TMP_PATH}/locale" # Bundle empty locale directory
    print_warning "Preparing locales (2/2): Cannot prepare locales because gettext not installed."
    return
  fi

  begin_group "Preparing locales (2/2): Compiling translations..."
  for language in "${LOCALE_PATH}/"*; do
    pushd "${language}"
    targetdir="${TMP_PATH}/locale/${language##*/}/LC_MESSAGES"
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

readonly IMAGE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${IMAGE_BITS}bit"
export_variable "IMAGE_NAME" "${IMAGE_NAME}"

readonly SQUEAK_VERSION_NUMBER=$(echo "${SQUEAK_VERSION}" | sed "s/^[A-Za-z]*\(.*\)$/\1/")
readonly WINDOW_TITLE="${SMALLTALK_NAME} ${SQUEAK_VERSION_NUMBER} (${IMAGE_BITS} bit)"
