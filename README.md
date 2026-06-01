# The Squeak/Smalltalk Programming System

[![Build Status](https://github.com/squeak-smalltalk/squeak-app/actions/workflows/bundle.yml/badge.svg)](https://github.com/squeak-smalltalk/squeak-app/actions/workflows/bundle.yml)

This is the code repository for Squeak's build system.

A build works basically as follows. First, 32-bit and 64-bit images are prepared and tested:

* [prepare_image.sh](prepare_image.sh) downloads a base image/changes/sources from http://files.squeak.org/base/
* [prepare_image.st](prepare_image.st) updates the image and creates a `version.sh` file with the version information
* [test_image.sh](test_image.sh) uses [smalltalkCI](https://github.com/hpi-swa/smalltalkCI) to run all tests and document the results
* [test_image.st](test_image.st) configures [smalltalkCI](https://github.com/hpi-swa/smalltalkCI)

Second, the [prepare-bundles.sh](prepare-bundles.sh) script downloads VMs from http://files.squeak.org/base/ and then creates the bundles through the following scripts:

* [prepare_aio.sh](prepare_aio.sh) builds the All-In-One bundle
* [prepare_macos.sh](prepare_macos.sh) builds the macOS bundle (64-bit, unified binary)
* [prepare_macos_arm.sh](prepare_macos_arm.sh) builds the macOS bundle (64-bit, M1 silicon and later)
* [prepare_macos_x86.sh](prepare_macos_x86.sh) builds the macOS release (64-bit, Intel silicon)
* [prepare_windows_arm.sh](prepare_windows_arm.sh) builds the Windows bundle (64-bit, ARM-based)
* [prepare_windows_x86.sh](prepare_windows_x86.sh) builds the Windows bundle (32/64-bit, x86-based) 
* [prepare_linux_arm.sh](prepare_linux_arm.sh) builds the Linux bundle (32/64-bit, ARM-based, Ubuntu-like)
* [prepare_linux_x86.sh](prepare_linux_x86.sh) builds the Linux bundle (32/64-bit, x86-based, Ubuntu-like)

Finally, [deploy_bundles.sh](deploy_bundles.sh) uploads everything to http://files.squeak.org/
(e.g., bleeding-edge trunk builds go to http://files.squeak.org/trunk).
