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

is_deployment_branch() {
  [[ "${GIT_BRANCH}" == *"${DEPLOYMENT_BRANCH}"* ]]
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
  local name=$1
  local url=$2 # e.g., files.squeak.org/base/Squeak-trunk/vm-win.zip
  local target=$3 # e.g., tmp/vm-win
  echo "...downloading and extracting ${name} VM..."
  curl -f -s --retry 3 -o "${TMP_DIR}/vm.zip" "${url}"
  unzip -q "${TMP_DIR}/vm.zip" -d "${target}"
  rm "${TMP_DIR}/vm.zip"
}

export_variable() {
  local var_name=$1
  local var_value=$2
  if [[ ! -z ${GITHUB_ENV} ]]; then
    echo "${var_name}=${var_value}" >> $GITHUB_ENV
  else
    print_warning "...skipping export of $var_name outside GitHub Actions..."
  fi
}

prepare_platform_vm() {
  case $RUNNER_OS in
    "Windows")
      readonly VM_URL="${VM_BASE}/vm-win.zip"
      readonly SMALLTALK_VM="${TMP_DIR}/vm/SqueakConsole.exe"
      # Add other GNU tools (e.g., wget) for third-party build scripts
      PATH=$PATH:/c/msys64/usr/bin
      ;;
    "Linux")
      readonly VM_URL="${VM_BASE}/vm-linux.zip"
      readonly SMALLTALK_VM="${TMP_DIR}/vm/squeak"
      ;;
    "macOS")
      readonly VM_URL="${VM_BASE}/vm-macos.zip"
      readonly SMALLTALK_VM="${TMP_DIR}/vm/Squeak.app/Contents/MacOS/Squeak"
      ;;
  esac

  download_and_extract_vm "$RUNNER_OS" "${VM_URL}" "${TMP_DIR}/vm"

  if [[ ! -f "${SMALLTALK_VM}" ]]; then
    echo "Failed to locate VM executable." && exit 1
  fi
}

lock_secret() {
  local name=secret-$1
  local key=$2
  local iv=$3

  local secret_dir="${HOME_DIR}/${name}"

  if ! is_dir "${secret_dir}"; then
    print_error "Failed to locate files to encrypt."
    exit 1
  fi

  zip -q -r "${HOME_DIR}/.${name}.zip" "${name}"
  rm -r -d "${secret_dir}"

  openssl aes-256-cbc -e -in .${name}.zip -out .${name}.zip.enc \
    -pbkdf2 -K "${key}" -iv "${iv}"
  rm .${name}.zip
}

unlock_secret() {
  local name=secret-$1
  local key=$2
  local iv=$3

  local secret_dir="${HOME_DIR}/${name}"

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
readonly BUILD_DIR="${HOME_DIR}/build"
readonly PRODUCT_DIR="${HOME_DIR}/product"
readonly TMP_DIR="${HOME_DIR}/tmp"
mkdir -p "${BUILD_DIR}" "${PRODUCT_DIR}" "${TMP_DIR}"
