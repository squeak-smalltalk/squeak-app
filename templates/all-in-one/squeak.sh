#!/usr/bin/env bash
# File:        squeak.sh (All-in-One version)
# Authors:     Bert Freudenberg, Paul DeBruicker, Craig Latta, Chris Muller,
#              Fabio Niephaus
# Version:     2.1
# Date:        08/19/2016
# Description: Script to run Squeak from the all-in-one app structure
#              (based on Etoys-To-Go)

APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/%APP_NAME%" && pwd )"
IMAGE="${APP_DIR}/Contents/Resources/%SqueakImageName%"
IMAGE_BITS="%IMAGE_BITS%"
CPU="$(uname -m)"
CONF_FILE="/etc/security/limits.d/squeak.conf"

showerror() {
  if [[ -n "${DISPLAY}" ]] && [[ -x "$(which kdialog 2>/dev/null)" ]]; then
    kdialog --error "$1"
  elif [[ -n "${DISPLAY}" ]] && [[ -x "$(which zenity 2>/dev/null)" ]]; then
    zenity --error --text "$1"
  else
    dialog --msgbox "$1" 0 0
  fi
}

check_cpu() {
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
}

# Ensure that Linux kernel is newer than 2.6.12 which is required for the heartbeat thread
ensure_kernel() {
  local kernel_release="$(uname -r)"
  local re="[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\(.*\)"
  local major=$(echo "${kernel_release}" | sed -e "s#${re}#\1#")
  local minor=$(echo "${kernel_release}" | sed -e "s#${re}#\2#")
  local patch=$(echo "${kernel_release}" | sed -e "s#${re}#\3#")
  # 2.6.12
  local min_major="2"
  local min_minor="6"
  local min_patch="12"

  if [[ "${major}" -lt "${min_major}" ]] || \
     [[ "${major}" -le "${min_major}" && "${major}" -lt "${min_minor}" ]] || \
     [[ "${major}" -le "${min_major}" && "${major}" -le "${min_minor}" && "${patch}" -lt "${min_patch}" ]]; then
    showerror "Linux kernel ($(uname -r)) needs to be newer than ${min_major}.${min_minor}.${min_patch}."
    exit 1
  fi
}

ensure_vm() {
  if [[ ! -x "${VM}" ]]; then
    if [[ ! -r "${VM}" ]]; then
      showerror "This Squeak version does not support $(uname -s)-${CPU}."
    else
      showerror "Squeak does not have permissions to execute."
    fi
  fi
}

# Ensure that the $CONF_FILE configuration file exists and help to create one
ensure_conf_file() {
  local user_input
  if ! [[ -f "${CONF_FILE}" ]]; then
    read -p "${CONF_FILE} is missing. Do you want to create one?
This operation requires sudo permissions. (y/N): " user_input
    if [[ "${user_input}" = "y" ]]; then
      echo "You may be asked to enter your password..."
      sudo tee -a "${CONF_FILE}" > /dev/null <<END
*       hard    rtprio  2
*       soft    rtprio  2
END
      echo "Done! Please log out and log back in before you try again."
    else
      echo "Operation cancelled."
    fi
    exit 0
  fi
}

# Ensure that an image is selected
ensure_image() {
  local image_count
  # zenity is part of GNOME
  if [[ -z "${IMAGE}" ]]; then 
    image_count=$(ls "${RESOURCES}"/*.image 2>/dev/null | wc -l)
    if which zenity &>/dev/null && [[ "$image_count" -ne 1 ]]; then
      IMAGE=$(zenity --title 'Select an image' --file-selection --filename "${RESOURCES}/" --file-filter '*.image' --file-filter '*')
    else
      # Try to find first .image file not starting with a dot
      IMAGE="$(find "${RESOURCES}" \( -iname "*.image" ! -iname ".*" \) | head -n 1)"
    fi
  fi
}

ensure_kernel
check_cpu
VM="${APP_DIR}/Contents/Linux-${CPU}/bin/squeak"
ensure_vm
ensure_conf_file
ensure_image

echo "Using ${VM}..."
exec "${VM}" "${IMAGE}"
