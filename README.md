# The Squeak/Smalltalk Programming System

[![Build Status](https://secure.travis-ci.org/squeak-smalltalk/squeak-app.png?branch=squeak-trunk)](http://travis-ci.org/squeak-smalltalk/squeak-app)

This is the code repository for Squeak's build system.

A build works basically as follows. The [prepare.sh](prepare.sh) script downloads VMs from http://files.squeak.org/base/ and then invokes the following scripts:

* [prepare_image.sh](prepare_image.sh) downloads a base image/changes/sources from http://files.squeak.org/base/
* [prepare_image.st](prepare_image.st) updates the image and creates a `version.sh` file with the version information
* [prepare_aio.sh](prepare_aio.sh) builds the All-In-One
* [prepare_mac.sh](prepare_mac.sh) builds the Mac release
* [prepare_win.sh](prepare_win.sh) builds the Windows release
* [prepare_lin.sh](prepare_lin.sh) builds the Linux x86 release
* [prepare_armv6.sh](prepare_armv6.sh) builds the Linux ARM release

Finally, [prepare.sh](prepare.sh) uploads everything to http://files.squeak.org/
(e.g. bleeding-edge trunk builds go to http://files.squeak.org/trunk).
