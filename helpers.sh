is_64bit() {
  [[ "${SMALLTALK_VERSION}" == *"64-"* ]]
}

is_32bit() {
  ! is_64bit
}

is_etoys() {
  [[ "${SMALLTALK_VERSION}" == "Etoys"* ]]
}

is_trunk() {
  [[ "${SMALLTALK_VERSION}" == *"trunk"* ]]
}

is_file() {
  [[ -f $1 ]]
}

is_dir() {
  [[ -d $1 ]]
}

should_deploy() {
  [[ "${SHOULD_DEPLOY}" == "true" ]]
}

should_codesign() {
  [[ "${SHOULD_CODESIGN}" == "true" ]]
}

should_notarize() {
  [[ ! is_trunk ]]
  # return 0
}

should_use_rc_vm() {
  [[ ! -z ${VM_RC_TAG} ]]
}

readonly COLOR_RESET="\033[0m"
readonly COLOR_LIGHT_RED="\033[1;31m"
readonly COLOR_LIGHT_GREEN="\033[1;32m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_LIGHT_BLUE="\033[1;34m"

print_info() {
  local message=$1
  echo -e "${COLOR_LIGHT_BLUE}${message}${COLOR_RESET}"
}

print_warning() {
  local message=$1
  echo -e "${COLOR_YELLOW}${message}${COLOR_RESET}"
}

print_error() {
  local message=$1
  echo -e "${COLOR_LIGHT_RED}${message}${COLOR_RESET}"
}

print_done() {
  echo -e "${COLOR_LIGHT_GREEN}...done.${COLOR_RESET}"
}

begin_group() {
  local title=$1
  echo -e "::group::${title}"
}

end_group() {
  print_done
  echo "::endgroup::"
}

download_and_extract_vm() {
# Examples for $url
#   https://github.com/OpenSmalltalk/opensmalltalk-vm/releases/download/latest-build/squeak.cog.spur_win64x64.zip
#   https://github.com/OpenSmalltalk/opensmalltalk-vm/releases/download/latest-build/squeak.cog.spur_macos64x64.dmg
#   https://github.com/OpenSmalltalk/opensmalltalk-vm/releases/download/latest-build/squeak.cog.spur_linux64ARMv8.tar.gz
  local name=$1
  local url=$2 # e.g., files.squeak.org/base/Squeak-trunk/vm-win.zip
  local target=$3 # e.g., tmp/vm-win
  local archive=$(basename "${url}")
  local filepath="${TMP_PATH}/${archive}"
  echo "...downloading and extracting ${name} VM..."
  curl -f -s --retry 3 -L -o "${filepath}" "${url}"

  # Extraction code based on https://github.com/hpi-swa/smalltalkCI
  if [[ "${filepath}" == *".tar.gz" ]]; then
    mkdir -p "${target}"
    tar xzf "${filepath}" -C "${target}"
  elif [[ "${filepath}" == *".zip" ]]; then
    unzip "${filepath}" -d "${target}"
  elif [[ "${filepath}" == *".dmg" ]]; then
    local volume=$(hdiutil attach "${filepath}" | tail -1 | awk '{print $3}')
    mkdir -p "${target}"
    cp -R "${volume}/"* "${target}/"
    echo "Extracted into ${target}/ from ${volume}/"
    pushd ${volume}
    ls -lisa
    popd
    pushd ${target}
    ls -lisa
    popd

    diskutil unmount "${volume}"

  else
    echo "Unknown archive format." && exit 77
  fi

  rm "${filepath}"
}


export_variable() {
  local var_name=$1
  local var_value=$2
  if [[ ! -z ${GITHUB_ENV} ]]; then
    echo "${var_name}=${var_value}" >> $GITHUB_ENV
    echo "${var_name}=${var_value}" >> $GLOBAL_ENV
  else
    print_warning "...skipping export of $var_name outside GitHub Actions..."
  fi
}

import_variables() {
  if is_file $GLOBAL_ENV; then
    source $GLOBAL_ENV
  else
    echo "No global variables to import."
  fi
}

prepare_platform_vm() {
  case $RUNNER_OS in
    "Windows")
      readonly VM_URL="${VM_BASE}/${VM_WIN_X86}.zip"
      readonly SMALLTALK_VM="${TMP_PATH}/vm/SqueakConsole.exe"
      # Add other GNU tools (e.g., wget) for third-party build scripts
      PATH=$PATH:/c/msys64/usr/bin
      ;;
    "Linux")
      readonly VM_URL="${VM_BASE}/${VM_LIN_X86}.zip"
      readonly SMALLTALK_VM="${TMP_PATH}/vm/squeak"
      ;;
    "macOS")
      readonly VM_URL="${VM_BASE}/${VM_MAC_X86}.zip"
      readonly SMALLTALK_VM="${TMP_PATH}/vm/Squeak.app/Contents/MacOS/Squeak"
      ;;
  esac

  download_and_extract_vm "$RUNNER_OS" "${VM_URL}" "${TMP_PATH}/vm"

  if [[ ! -f "${SMALLTALK_VM}" ]]; then
    echo "Failed to locate VM executable." && exit 1
  fi
}

lock_secret() {
  local name=secret-$1
  local key=$2
  local iv=$3

  local secret_dir="${HOME_PATH}/${name}"

  if ! is_dir "${secret_dir}"; then
    print_error "Failed to locate files to encrypt."
    exit 1
  fi

  zip -q -r "${HOME_PATH}/.${name}.zip" "${name}"
  rm -r -d "${secret_dir}"

  openssl aes-256-cbc -e -in .${name}.zip -out .${name}.zip.enc \
    -pbkdf2 -K "${key}" -iv "${iv}"
  rm .${name}.zip
}

unlock_secret() {
  local name=secret-$1
  local key=$2
  local iv=$3

  local secret_dir="${HOME_PATH}/${name}"

  if ! is_file .${name}.zip.enc; then
    print_error "Failed to locate encrypted archive."
    exit 1
  fi

  openssl aes-256-cbc -d -in .${name}.zip.enc -out .${name}.zip \
    -pbkdf2 -K "${key}" -iv "${iv}"
  rm .${name}.zip.enc

  unzip -q .${name}.zip
  rm .${name}.zip

  if ! is_dir "${secret_dir}"; then
    print_error "Failed to locate decrypted files."
    exit 1
  fi
}

# Assure the existence of all working directories
readonly BUILD_PATH="${HOME_PATH}/build"
readonly PRODUCT_PATH="${HOME_PATH}/product"
readonly TMP_PATH="${HOME_PATH}/tmp"
mkdir -p "${BUILD_PATH}" "${PRODUCT_PATH}" "${TMP_PATH}"

# Communicate variables beyond a single action
readonly GLOBAL_ENV="${TMP_PATH}/global-env"
import_variables

# Assure $RUNNER_OS if not invoked from within GitHub Actions
if [[ -z "${RUNNER_OS}" ]]; then
  case $(uname -s) in
    Darwin*)
      export RUNNER_OS="macOS"
      ;;
    Linux*)
      export RUNNER_OS="Linux"
      ;;
    CYGWIN*|MINGW*)
      export RUNNER_OS="Windows"
      ;;
    *)
      echo "Unsupported platform."
      exit 1
  esac
fi
