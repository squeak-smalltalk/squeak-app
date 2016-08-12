#!/usr/bin/env bash
# File:        squeak.sh (All-in-One version)
# Authors:     Bert Freudenberg, Paul DeBruicker, Craig Latta, Chris Muller,
#              Fabio Niephaus
# Description: Script to run Squeak from the all-in-one app structure
#              (based on Etoys-To-Go)

APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/%APP_NAME%" && pwd )"
IMAGE="${APP_DIR}/Contents/Resources/%SqueakImageName%"
IMAGE_BITS="%IMAGE_BITS%"
CPU="$(uname -m)"

case "${CPU}" in
  "x86_64")
    if [[ "${IMAGE_BITS}" == "32" ]]; then
      CPU="i686"
      echo "Running 32-bit Squeak on a 64-bit System. install-libs32 may install them."
    fi
    ;;
  "armv6l"|"armv7l")
    CPU="ARM"
    ;;
esac

VM="$APP/Contents/Linux-$CPU/bin/squeak"
echo "${VM}"

showerror() {
  if [[ -n "${DISPLAY}" ]] && [[ -x "$(which kdialog 2>/dev/null)" ]]; then
    kdialog --error "$1"
  elif [[ -n "${DISPLAY}" ]] && [[ -x "$(which zenity 2>/dev/null)" ]]; then
    zenity --error --text "$1"
  else
    dialog --msgbox "$1" 0 0
  fi
}

if [[ ! -x "${VM}" ]]; then
  if [[ ! -r "${VM}" ]]; then
    showerror "This Squeak version does not support $(uname -s)-${CPU}"
  else
    showerror "Squeak does not have permissions to execute"
  fi
fi

exec "${VM}" "${IMAGE}"
