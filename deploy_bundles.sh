#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    deploy_bundles.sh
#  CONTENT: Upload all bundles to files.squeak.org
#
#  REQUIRES:
#    SMALLTALK_VERSION ... e.g., Squeak64-trunk
#    SHOULD_DEPLOY     ... i.e., true or false
#    product/*.zip
#    product/*.dmg
#    IMAGE_NAME
#    IMAGE_BITS
#....BUNDLE_NAME_AIO
#....BUNDLE_NAME_MAC_X86
#....BUNDLE_NAME_MAC_ARM
#....BUNDLE_NAME_MAC
#....BUNDLE_NAME_LIN_X86
#....BUNDLE_NAME_LIN_ARM
#....BUNDLE_NAME_WIN_X86
#    DEPLOY_KEY        ... i.e., for unlocking secret files
#    DEPLOY_IV         ... i.e., for unlocking secret files
#    SSH_PUBLIC_KEY
#    PROXY_PORT
#    PROXY_HOST
#    PROXY_USER
#    UPSTREAM_HOST
#    UPSTREAM_USER
#  PROVIDES:
#    -
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

source "env_vars"
source "helpers.sh"

[[ -z "${IMAGE_NAME}" ]] && exit 2
[[ -z "${IMAGE_BITS}" ]] && exit 3

if [[ "${IMAGE_BITS}" == "64" ]]; then
  [[ -z "${BUNDLE_NAME_MAC}" ]] && exit 4
  [[ -z "${BUNDLE_NAME_MAC_ARM}" ]] && exit 5
  [[ -z "${BUNDLE_NAME_MAC_X86}" ]] && exit 6
  [[ -z "${BUNDLE_NAME_LIN_X86}" ]] && exit 7
  [[ -z "${BUNDLE_NAME_LIN_ARM}" ]] && exit 8
  [[ -z "${BUNDLE_NAME_WIN_X86}" ]] && exit 9
  [[ -z "${BUNDLE_NAME_AIO}" ]] && exit 10
else
  [[ -z "${BUNDLE_NAME_LIN_X86}" ]] && exit 10
  [[ -z "${BUNDLE_NAME_LIN_ARM}" ]] && exit 11
  [[ -z "${BUNDLE_NAME_WIN_X86}" ]] && exit 12
  [[ -z "${BUNDLE_NAME_AIO}" ]] && exit 13
fi

begin_group "...preparing deployment..."

if [[ -z "${DEPLOY_KEY}" ]]; then
  print_error "Cannot deploy because secret missing."
  exit 1
else
  unlock_secret "deploy" "${DEPLOY_KEY}" "${DEPLOY_IV}"
  readonly SSH_KEY_PATH="${HOME_PATH}/secret-deploy"
  readonly SSH_KEY_FILEPATH="${SSH_KEY_PATH}/ssh_deploy_key"
  if ! is_file "${SSH_KEY_FILEPATH}"; then
    print_error "Cannot find ssh_deploy_key"
    exit 1
  fi
  chmod 600 "${SSH_KEY_FILEPATH}"
fi

end_group

begin_group "...uploading all files to files.squeak.org.."

readonly UPSTREAM_BASE="/var/www/files.squeak.org"

if is_etoys; then
  UPSTREAM_PATH="${UPSTREAM_BASE}/etoys/${SQUEAK_VERSION/Etoys/}"
else
  UPSTREAM_PATH="${UPSTREAM_BASE}/${SQUEAK_VERSION/Squeak/}"
fi
UPSTREAM_PATH="${UPSTREAM_PATH}/${IMAGE_NAME}"

ssh-keygen -R ${PROXY_HOST}
ssh-keyscan -t ecdsa-sha2-nistp256 -p "${PROXY_PORT}" "${PROXY_HOST}" 2>&1 | tee -a "${HOME}/.ssh/known_hosts" > /dev/null;
echo "${UPSTREAM_HOST} ecdsa-sha2-nistp256 ${SSH_PUBLIC_KEY}" | tee -a "${HOME}/.ssh/known_hosts" > /dev/null;

SSH_CONFIG_PATH=${HOME}/.ssh/config
touch ${SSH_CONFIG_PATH}
if grep -vq "^Host ${PROXY_HOST}$" ${SSH_CONFIG_PATH}; then
cat >> ${SSH_CONFIG_PATH} <<EOF
Host $PROXY_HOST
         User $PROXY_USER
         IdentityFile $SSH_KEY_FILEPATH
         IdentitiesOnly yes
         PreferredAuthentications publickey
         PubkeyAuthentication yes
EOF
fi
rsync -rvz --ignore-existing -e "ssh -o ProxyJump=${PROXY_HOST} -l ${UPSTREAM_USER} -i ${SSH_KEY_FILEPATH}" "${PRODUCT_PATH}/" "${UPSTREAM_HOST}:${UPSTREAM_PATH}/";

end_group

begin_group "...updating 'latest' symlinks on server..."

LATEST_PREFIX="${UPSTREAM_BASE}/nightly/Squeak-latest-${IMAGE_BITS}bit"
SYMS_CMD="ln -f -s ${UPSTREAM_PATH}/${IMAGE_NAME}.zip ${LATEST_PREFIX}.zip"
if [[ "${IMAGE_BITS}" == "64" ]]; then
  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_LIN_X86}.tar.gz ${LATEST_PREFIX}-Linux-x64.tar.gz"
  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_LIN_ARM}.tar.gz ${LATEST_PREFIX}-Linux-ARMv8.tar.gz"

  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_MAC_X86}.dmg ${LATEST_PREFIX}-macOS-x64.dmg"
  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_MAC_ARM}.dmg ${LATEST_PREFIX}-macOS-ARMv8.dmg"
  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_MAC}.dmg ${LATEST_PREFIX}-macOS.dmg"

  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_WIN_X86}.zip ${LATEST_PREFIX}-Windows-x64.zip"
else
  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_LIN_X86}.tar.gz ${LATEST_PREFIX}-Linux-x86.tar.gz"
  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_LIN_ARM}.tar.gz ${LATEST_PREFIX}-Linux-ARMv6.tar.gz"

  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_WIN_X86}.zip ${LATEST_PREFIX}-Windows-x86.zip"
fi
ssh -o ProxyCommand="ssh -l ${PROXY_USER} -i ${SSH_KEY_FILEPATH} -p ${PROXY_PORT} -W %h:%p ${PROXY_HOST}" \
  -l "${UPSTREAM_USER}" -i "${SSH_KEY_FILEPATH}" "${UPSTREAM_HOST}" -t "${SYMS_CMD}"

end_group

# Remove sensitive information
rm -rf "${SSH_KEY_PATH}"
