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
#....BUNDLE_NAME_LIN
#....BUNDLE_NAME_MAC
#....BUNDLE_NAME_WIN
#....BUNDLE_NAME_ARM   ... only on 32-bit
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

[[ -z "${BUNDLE_NAME_LIN}" ]] && exit 4
[[ -z "${BUNDLE_NAME_MAC}" ]] && exit 5
[[ -z "${BUNDLE_NAME_WIN}" ]] && exit 6

if is_32bit; then
  [[ -z "${BUNDLE_NAME_ARM}" ]] && exit 7
fi

begin_group "...preparing deployment..."

if [[ -z "${DEPLOY_KEY}" ]]; then
  print_error "Cannot deploy because secret missing."
  exit 1
else
  unlock_secret "deploy" "${DEPLOY_KEY}" "${DEPLOY_IV}"
  readonly SSH_KEY_FILEPATH="${HOME_PATH}/secret-deploy/ssh_deploy_key"
  readonly SSH_KEY_PATH="${HOME_PATH}/secret-deploy"
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


ssh-keyscan -t ecdsa-sha2-nistp256 -p "${PROXY_PORT}" "${PROXY_HOST}" 2>&1 | tee -a "${HOME}/.ssh/known_hosts" > /dev/null;
echo "${UPSTREAM_HOST} ecdsa-sha2-nistp256 ${SSH_PUBLIC_KEY}" | tee -a "${HOME}/.ssh/known_hosts" > /dev/null;
rsync -rvz --ignore-existing -e "ssh -o ProxyCommand='ssh -l ${PROXY_USER} -i ${SSH_KEY_FILEPATH} -p ${PROXY_PORT} -W %h:%p ${PROXY_HOST}' -l ${UPSTREAM_USER} -i ${SSH_KEY_FILEPATH}" "${PRODUCT_PATH}/" "${UPSTREAM_HOST}:${UPSTREAM_PATH}/";

end_group

begin_group "...updating 'latest' symlinks on server..."

LATEST_PREFIX="${UPSTREAM_BASE}/nightly/Squeak-latest-${IMAGE_BITS}bit"
SYMS_CMD="ln -f -s ${UPSTREAM_PATH}/${IMAGE_NAME}.zip ${LATEST_PREFIX}.zip"
SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_LIN}.zip ${LATEST_PREFIX}-Linux.zip"
SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_MAC}.dmg ${LATEST_PREFIX}-macOS.dmg"
SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_WIN}.zip ${LATEST_PREFIX}-Windows.zip"
if is_32bit; then
  SYMS_CMD="${SYMS_CMD} && ln -f -s ${UPSTREAM_PATH}/${BUNDLE_NAME_ARM}.zip ${LATEST_PREFIX}-ARMv6.zip"
fi
ssh -o ProxyCommand="ssh -l ${PROXY_USER} -i ${SSH_KEY_FILEPATH} -p ${PROXY_PORT} -W %h:%p ${PROXY_HOST}" \
  -l "${UPSTREAM_USER}" -i "${SSH_KEY_FILEPATH}" "${UPSTREAM_HOST}" -t "${SYMS_CMD}"

end_group

# Remove sensitive information
rm -rf "${SSH_KEY_PATH}"
