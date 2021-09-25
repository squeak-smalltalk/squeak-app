# The Squeak/Smalltalk Programming System

[![Build Status](https://github.com/squeak-smalltalk/squeak-app/actions/workflows/bundle.yml/badge.svg)](https://github.com/squeak-smalltalk/squeak-app/actions/workflows/bundle.yml)

This is the code repository for Squeak's build system.

A build works basically as follows. First, 32-bit and 64-bit images are prepared and tested:

* [prepare_image.sh](prepare_image.sh) downloads a base image/changes/sources from http://files.squeak.org/base/
* [prepare_image.st](prepare_image.st) updates the image and creates a `version.sh` file with the version information
* [test_image.sh](test_image.sh) uses [smalltalkCI](https://github.com/hpi-swa/smalltalkCI) to run all tests and document the results

Second, the [prepare-bundles.sh](prepare-bundles.sh) script downloads VMs from http://files.squeak.org/base/ and then creates the bundles through the following scripts:

* [prepare_aio.sh](prepare_aio.sh) builds the All-In-One
* [prepare_mac.sh](prepare_mac.sh) builds the Mac release
* [prepare_win.sh](prepare_win.sh) builds the Windows release
* [prepare_lin.sh](prepare_lin.sh) builds the Linux x86 release
* [prepare_armv6.sh](prepare_armv6.sh) builds the Linux ARM release

Finally, [deploy_bundles.sh](deploy_bundles.sh) uploads everything to http://files.squeak.org/
(e.g., bleeding-edge trunk builds go to http://files.squeak.org/trunk).
