# How to create new base images for CI

We use [GitHub Actions](https://github.com/squeak-smalltalk/squeak-app) to prepare Squeak images, which are then bundled with the latest stable [OpenSmalltalk VM](https://github.com/OpenSmalltalk/opensmalltalk-vm) and finally uploaded to [files.squeak.org](https://files.squeak.org/trunk) for everybody to download.

Since we maintain Squeak's source code through [source.squeak.org](https://source.squeak.org/trunk), every CI run will update a certain *base image* to get the latest changes into the bundle. Over time, the bundling time can thus grow.

Updating a [base image](https://files.squeak.org/base/) can be useful to improve bundling time again, however, sacrificing the update test of older images, which comes for free.

At least for every new Squeak release, a new base image has to be created. At the same time, it makes sense to also update the trunk's base image to make those bundling times also fast again.

The CI will eventually run `ReleaseBuilder prepareEnvironment` to configure the initial startup experience. Besides fetching the latest code updates, other things are prepared in the base image.


## Note on 32-bit images

For any Squeak version, there are two base images that share the same `*.sources` file, one 32-bit and one 64-bit. While not bit-identical, they should be rather similar from a user perspective, which includes accessing the source code for all methods in the image.


## Step 1 - Download the latest Squeak bundle

While base images can be created from any Squeak in use, it makes sense to start with the clean download versions. It does not matter which platform is used to prepare the base image.

https://files.squeak.org/trunk/

If you want to update the base image for an older Squeak release, use a bundle from that release, such as

https://files.squeak.org/6.0/


## Step 2 - Let the ReleaseBuilder clean-up and save the image

Squeak's object space can get messy over time. There are many `cleanUp:` hooks implemented across all classes, which are used to reset and clean-up the system. Most importantly, this removes all sensitive user data (e.g. passwords) and resets caches (e.g. pre-rendered font glyphs).

To prepare a new base image, run the following code snippet:

```Smalltalk
ReleaseBuilder
   prepareSourceCode;
   prepareEnvironment;
   prepareProcesses.
```

Since the image should then be saved, you can shorted this to

```Smalltalk
ReleaseBuilder saveAsNewTrunk.
```

for the new base image of the current alpha version or

```Smalltalk
ReleaseBuilder saveAsNewRelease.
```

for the new base image of the current release version.

## Step 3 - Prepare base image for CI

As you might have noticed, `saveAsNewTrunk` actually finishes up the entire experience, which includes the welcome window and the preference wizard. We do not need those for the CI and will re-install them later via `ReleaseBuilder prepareEnvironment` anyway.

So, we now open up the freshly saved (base) image, close the preference wizard, the welcome window, and *all other visible windows*. Then run the following code snippet:

```Smalltalk
ReleaseBuilder saveBase.
```

## Step 4 - Upload base image

The expected `base.zip` on [files.squeak.org](https://files.squeak.org/) contains three files:

- Squeak.image
- Squeak.changes
- Squeak.sources

The `*.sources` must be the one expected from the `*.image`. The base filename of both `*.image` and `*.change` does not matter for the CI bundling scripts as those work with the file extension only and rename those files anyway.

A valid `base.zip` for the current trunk bundles should look like this:

- squeak-trunk.image
- squeak-trunk.changes
- SqueakV60.sources

A valid `base.zip` for the Squeak 6.0 release should look like this:

- squeak-6.0.image
- squeak-6.0.changes
- SqueakV60.sources

Now create a ZIP archive and upload it. Don't forget to have a 32-bit version and a 64-bit version.


## Step 5 - Update versions.txt

On [files.squeak.org/base](https://files.squeak.org/base/), every directory contains a `versions.txt`, which reports not only the OSVM versions for the bundles but also the Squeak build number in the base image.

Update that version info as well:

```
readonly VERSION_BASE_ZIP="6.1alpha-22095"     # base.zip
```
