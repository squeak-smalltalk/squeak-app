#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    deploy_bundles.sh
#  CONTENT: Upload all bundles to files.squeak.org
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

[[ -z "${ENCRYPTED_DIR}" ]] && exit 4
[[ -z "${PRODUCT_DIR}" ]] && exit 5

source env_vars

readonly TARGET_BASE="/var/www/files.squeak.org"

begin_group "...uploading all files to files.squeak.org.."

if ! is_dir "${ENCRYPTED_DIR}"; then
  echo "Failed to locate decrypted files."
  exit 1
fi

if is_etoys; then
  TARGET_PATH="${TARGET_BASE}/etoys/${SQUEAK_VERSION/Etoys/}"
else
  TARGET_PATH="${TARGET_BASE}/${SQUEAK_VERSION/Squeak/}"
fi
TARGET_PATH="${TARGET_PATH}/${IMAGE_NAME}"

chmod 600 "${ENCRYPTED_DIR}/ssh_deploy_key"
ssh-keyscan -t ecdsa-sha2-nistp256 -p "${PROXY_PORT}" "${PROXY_HOST}" 2>&1 | tee -a "${HOME}/.ssh/known_hosts" > /dev/null;
echo "${UPSTREAM_HOST} ecdsa-sha2-nistp256 ${PUBLIC_KEY}" | tee -a "${HOME}/.ssh/known_hosts" > /dev/null;
rsync -rvz --ignore-existing -e "ssh -o ProxyCommand='ssh -l ${PROXY_USER} -i ${ENCRYPTED_DIR}/ssh_deploy_key -p ${PROXY_PORT} -W %h:%p ${PROXY_HOST}' -l ${UPSTREAM_USER} -i ${ENCRYPTED_DIR}/ssh_deploy_key" "${PRODUCT_DIR}/" "${UPSTREAM_HOST}:${TARGET_PATH}/";

end_group

begin_group "...updating latest symlinks on server..."

LATEST_PREFIX="${TARGET_BASE}/nightly/Squeak-latest-${IMAGE_BITS}bit"
SYMS_CMD="ln -f -s ${TARGET_PATH}/${IMAGE_NAME}.zip ${LATEST_PREFIX}.zip"
SYMS_CMD="${SYMS_CMD} && ln -f -s ${TARGET_PATH}/${BUNDLE_NAME_LIN}.zip ${LATEST_PREFIX}-Linux.zip"
SYMS_CMD="${SYMS_CMD} && ln -f -s ${TARGET_PATH}/${BUNDLE_NAME_MAC}.dmg ${LATEST_PREFIX}-macOS.dmg"
SYMS_CMD="${SYMS_CMD} && ln -f -s ${TARGET_PATH}/${BUNDLE_NAME_WIN}.zip ${LATEST_PREFIX}-Windows.zip"
if is_32bit; then
  SYMS_CMD="${SYMS_CMD} && ln -f -s ${TARGET_PATH}/${BUNDLE_NAME_ARM}.zip ${LATEST_PREFIX}-ARMv6.zip"
fi
ssh -o ProxyCommand="ssh -l ${PROXY_USER} -i ${ENCRYPTED_DIR}/ssh_deploy_key -p ${PROXY_PORT} -W %h:%p ${PROXY_HOST}" \
  -l "${UPSTREAM_USER}" -i "${ENCRYPTED_DIR}/ssh_deploy_key" "${UPSTREAM_HOST}" -t "${SYMS_CMD}"

end_group

# Remove sensitive information
rm -rf "${ENCRYPTED_DIR}"
security delete-keychain "${KEY_CHAIN}"
