#!/bin/bash

$r = Invoke-RestMethod -Uri "https://api.bintray.com/search/file?name=*win32x86*&subject=opensmalltalk&repo=vm"
$x = $r | select name | where name -Like "*squeak.cog.spur*" | sort name -descending
Start-FileDownload $x[0]

# $r[0]
# $r[$r.length-1]


# Sort-Object -Property @{Expression="name";Descending=$true} -InputObject $r


# name    : cog_win32x86_newspeak.cog.spur_201606171704.zip
# path    : cog_win32x86_newspeak.cog.spur_201606171704.zip
# repo    : vm
# package : cog
# version : 201606171704
# owner   : opensmalltalk
# created : 2016-06-17T17:46:21.197Z
# size    : 7712943
# sha1    : 238c7318c17a1292480aa46501e11ef09da0c544
# sha256  : 5fe4210a74c6dd8a1647fefa782cd8c5c572aea82ca712f87e4f017f804a4139