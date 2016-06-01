#!/bin/bash
# File:        squeak.sh (All-in-One version)
# Author:      Bert Freudenberg (edited by Paul DeBruicker and Craig Latta)
# Description: Script to run Squeak from the all-in-one app structure
#              (based on Etoys-To-Go)
# Edits:
# 22 Jul 2015	Chris Muller		Invoke VM under Linux-ARM for armv6l and armv7l CPU's

APP=`dirname "$0"`/../..
APP=`cd "$APP";pwd`
OS=`uname -s`
CPU=`uname -m`
IMAGE="$APP/Contents/Resources/Squeak5.0-15113.image"

if [ "$CPU" = x86_64 ] ; then
        CPU=i686
        echo Running 32-bit Squeak on a 64-bit System.  install-libs32 may install them.
fi

if [ "$CPU" = armv6l ] ; then
        CPU=ARM
fi

if [ "$CPU" = armv7l ] ; then
        CPU=ARM
fi

VM="$APP/Contents/LinuxAndWindows/$OS-$CPU/bin/squeak"
echo $VM
showerror() {
    if [ -n "$DISPLAY" -a -x "`which kdialog 2>/dev/null`" ]; then
        kdialog --error "$1"
    elif [ -n "$DISPLAY" -a -x "`which zenity 2>/dev/null`" ]; then
        zenity --error --text "$1"
    else
        dialog --msgbox "$1" 0 0
    fi
}

if [ ! -x "$VM" ] ; then
    if [ ! -r "$VM" ] ; then
        showerror "This Squeak version does not support $OS-$CPU"
    else
        showerror "Squeak does not have permissions to execute"
    fi
fi

exec "$VM" "$IMAGE"
