#!/bin/bash

APP=`dirname "$0"`/../..
APP=`cd "$APP";pwd`
OS=`uname -s`
CPU=`uname -m`
IMAGE="$APP/Contents/Resources/%SqueakImageName%"

showerror() {
    if [ -n "$DISPLAY" -a -x "`which kdialog 2>/dev/null`" ]; then
        kdialog --error "$1"
    elif [ -n "$DISPLAY" -a -x "`which zenity 2>/dev/null`" ]; then
        zenity --error --text "$1"
    else
        dialog --msgbox "$1" 0 0
    fi
}

if [ "$CPU" = x86_64 ] ; then
    CPU=x86_64
fi

VM="$APP/Contents/Linux-$CPU/bin/squeak"
echo $VM

if [ ! -x "$VM" ] ; then
    if [ ! -r "$VM" ] ; then
        showerror "This Squeak version does not support $OS-$CPU"
    else
        showerror "Squeak does not have permissions to execute"
    fi
fi

exec "$VM" "$IMAGE"
