This is a fork of the official Variscite Debian builder (var-debian). Its purpose is to build a disk image that can be loaded onto SD cards for installing on new units.

# Prepping the environment

This is not a perfectly contained docker image. The host system must be Linux x86 and must have qemu-user-static installed, as well as the BuildKit for docker. There is an existing VM in Azure for building images, [here](https://portal.azure.com/#@servicesperryweather.onmicrosoft.com/resource/subscriptions/89a39f68-22ab-4566-9060-fe78a00c8d19/resourcegroups/pw-dev-rg/providers/Microsoft.Compute/virtualMachines/Firmware-Build/connect).

Then, you will need to have the firmware (closed source) project in a folder somewhere on your system, by default, `../JavaBoardFirmware`

# Building the Docker Image

`BUILDX_EXPERIMENTAL=1 DOCKER_BUILDKIT=1 docker buildx build --progress=plain --allow security.insecure .`

Again, this is not a true containerized build process, and we need the ability to mount host resources inside the container for building.

If the layer cache is populated and nothing has changed in the earlier steps, this should only run `packrootfs` and not earlier steps, which should take about 5 minutes.

# Getting the built images

The docker image contains the disk image in several parts, and it needs mounted and copied to a singular, logical image. This can be done, in theory, in the dockerfile, but there are issues with device partition tables in Docker, so for now this is a manual process.

```bash
## Start a session with the builder image, mounting a system directory as a volume.
docker run --privileged -it -e HOST_USER_ID=1000 -e HOST_USER_GID=1000 -v $(pwd):/source pweathercontainerregister.azurecr.io/jboard/variscite-debian:v20.04-test
```

Now, in the shell of the running container, write an empty image file on your host volume:

```bash
cd /source
dd if=/dev/zero of=imx6ul-var-dart-debian-sd.img bs=1M count=3720
sudo -S losetup -Pf imx6ul-var-dart-debian-sd.img
## The sudo password is ubuntu
```

Then, identify the loopback device attached to your volume (probably loop0)

```bash
sudo losetup -a | grep imx6ul-var-dart-debian-sd.img
```

Execute the sdcard action:

```bash
sudo MACHINE=imx6ul-var-dart ./var_make_debian.sh -c sdcard -d loop0
sudo losetup -d /dev/loop0
```

This will probably take 2-3 minutes. It may fail to unmount the partitions -- this is fine. Our image should still be written. You can exit the container shell. You should have a complete image on your host machine that can be dd'd to an sdcard.
