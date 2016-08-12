#!/usr/bin/env bash

# paths
DIR=`readlink -f $0` #resolve symlink
ROOT=`dirname "$DIR"` #obtain dir of the resolved path
VM_DIR="$ROOT/bin"
RESOURCES="$ROOT/shared"

# zenity is part of GNOME
image_count=`ls "${RESOURCES}"/*.image 2>/dev/null |wc -l`
if [ "$1" == "" ]; then 
	if which zenity &>/dev/null && [ "$image_count" -ne 1 ]; then
		image=`zenity --title 'Select an image' --file-selection --filename "${RESOURCES}/" --file-filter '*.image' --file-filter '*'`
	else
		image="$(find "${RESOURCES}" -name "*.image" | head -n 1)"		
	fi
else
	image=$*
fi

exec "${VM_DIR}/squeak" \
	--plugins "${VM_DIR}" \
	"$image"
