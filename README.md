# Blog In A Box Raspbian

This is a fork of [Raspbian](https://github.com/RPi-Distro/pi-gen), a tool used to create the raspberrypi.org Raspbian images.

The idea behind this modification to Raspbian is that we bundle a fully working WordPress environment with Raspbian that has minimal post-install configuration.

To achieve this we add a step to the Raspbian image build process that includes our additional software.

Part of this software is a script that runs the first time the machine is booted. This script checks for configuration in `/boot` and performs post-install setup.

The configuration in `/boot` can be modified after the image is built, and so is where user-specific settings will be stored.

## Installation

You must have Vagrant and VirtualBox already installed on your machine.

Then:

`npm run`

This will setup a Vagrant box with appropriate packages to build a Raspbian image.

## Development

Blog In A Box adds a step into the Raspbian build process.

This is found at:

`stage2/04-bloginabox`

The step runs in this order:

- First `00-run.sh` runs to configure a few repository settings.
- Packages listed in `01-packages` are installed
- `02-run.sh` runs to configure Blog In A Box

The post-install setup consists of `biab.service` which runs on first boot. This looks for `/boot/biab/setup.sh` and executes this in conjunction with settings in `/boot/biab/setup.conf`.

## Building

To build an image:

`npm run build`

This can be a long process - be patient.

A built image will then reside inside the Vagrant box in `~/work` and a zipped image inside `deploy` on your local machine.

If you want a copy of the unzipped image on your local machine:

`npm run copy`

## Release

Set the `GH_TOKEN` environment variable to an application specific Github password. Then run:

`npm run release`

This will take the latest built image and upload it to Github as a draft release. Edit the details of the release and publish.

## Caveats

When modifying the Blog In A Box script there are some things to bear in mind.

- Adding files to the filesystem is achieved through `install`. It's important the target is `${ROOTFS_DIR}`
- Running commands on the filesystem is achieved via `on_chroot`. Note that the system is not fully running so services like MySQL will not exist.
- You can browse the built filesystem in the `work` directory, stored on the Vagrant box - `vagrant ssh` to get access
- The build directory changes each day, and all the packages will be re-downloaded
