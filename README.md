This is a fork of the official Variscite Debian builder (var-debian). Its purpose is to build a disk image that can be loaded onto SD cards for installing on new units.

# Prepping the environment

This is not a perfectly contained docker image. The host system must be Linux x86 and must have qemu-user-static installed, as well as the BuildKit for docker. There is an existing VM in Azure for building images, [here](https://portal.azure.com/#@servicesperryweather.onmicrosoft.com/resource/subscriptions/89a39f68-22ab-4566-9060-fe78a00c8d19/resourcegroups/pw-dev-rg/providers/Microsoft.Compute/virtualMachines/Firmware-Build/connect).

Then, you will need to have the firmware (closed source) project in a folder somewhere on your system, by default, `../JavaBoardFirmware`

# Building the Docker Image

`BUILDX_EXPERIMENTAL=1 DOCKER_BUILDKIT=1 docker buildx build --progress=plain --allow security.insecure .`

Again, this is not a true containerized build process, and we need the ability to mount host resources inside the container for building.

If the layer cache is populated and nothing has changed in the earlier steps, this should only run `packrootfs` and not earlier steps, which should take about 5 minutes.

# Getting the built images

The images are in the `output` directory in the image. Once some more testing is complete, there will be steps in the bash script updated to actually write to a physical SD card or other iso file.
