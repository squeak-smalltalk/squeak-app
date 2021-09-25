#!/usr/bin/env bash
################################################################################
#  PROJECT: Lock and unlock secrets
#  FILE:    secret.sh
#  CONTENT: Encrypt and decrypt files in/to "./secret-*" directories
#           to/from ".secret-*.zip.enc" archive
#
#  AUTHORS: Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

source env_vars
source helpers.sh

readonly OP=$1 # lock or unlock
readonly NAME=$2
readonly KEY=$3
readonly IV=$4

# For example, you can generate KEY and IV in Squeak as follows:
#   ((1 to: 128) collect: [:ea |
#     (16 atRandom - 1) printStringBase: 16]) join

case $OP in
  lock)
    lock_secret $NAME $KEY $IV
    ;;
  unlock)
    unlock_secret $NAME $KEY $IV
    ;;
  *)
    echo "Unknown operation. Use 'lock' or 'unlock'."
    exit 1
    ;;
esac
