# syntax=docker/dockerfile:1-labs
FROM pweathercontainerregister.azurecr.io/jboard/variscite-base:v0.0-test
RUN apt-get install -y binfmt-support qemu qemu-user-static debootstrap kpartx \
lvm2 dosfstools gpart binutils bison git lib32ncurses5-dev libssl-dev gawk wget \
git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev \
autoconf libtool libglib2.0-dev libarchive-dev xterm sed cvs subversion \
kmod coreutils texi2html bc docbook-utils help2man make gcc g++ \
desktop-file-utils libgl1-mesa-dev libglu1-mesa-dev mercurial automake groff curl \
lzop asciidoc u-boot-tools mtd-utils device-tree-compiler flex cmake zstd udisks2  libgnutls28-dev \
python3-git python3-m2crypto python3-pyelftools
WORKDIR /workdir
COPY var_make_debian.sh .
COPY variscite variscite
RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c deploy
# COPY poco .so objects from build image
# ADD os_patches /workdir/os_patches
# WORKDIR /workdir/debian_imx6ul-var-dart
# RUN git apply /workdir/os_patches/debian/*.patch
# WORKDIR /workdir/debian_imx6ul-var-dart/src/kernel
# RUN git apply /workdir/os_patches/kernel/*.patch
RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c bootloader
COPY patches .
WORKDIR /workdir/src/kernel
RUN git apply ../../0002*.patch -v
RUN git apply ../../0006*.patch -v
RUN git apply ../../0007*.patch -v
RUN git apply ../../0011*.patch -v
RUN git apply ../../0013*.patch -v
WORKDIR /workdir
RUN cp imx6ull-var-som-concerto-board-emmc-wifi.dts /workdir/src/kernel/arch/arm/boot/dts/imx6ull-var-som-concerto-board-emmc-wifi.dts
RUN cp imx6ull-var-som-concerto-board-emmc-sd-card.dts /workdir/src/kernel/arch/arm/boot/dts/imx6ull-var-som-concerto-board-emmc-sd-card.dts

RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c kernel
RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c modules
RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c kernelheaders

# This step takes a long time. We should avoid making changes to things above this line 
RUN --security=insecure MACHINE=imx6ul-var-dart ./var_make_debian.sh -c rootfs

## TODO make the above steps into a separate stage or separate docker image

# The below steps copy all the java-board specific files into the final image.
# Steps after this are small and fast, and so they should complete quickly
# Allowing us to (in most cases) iterate and build images in seconds instead of hours.

COPY firmware/scripts/java_init.service /workdir/rootfs/lib/systemd/system/
COPY firmware/scripts/java_init.sh /workdir/rootfs/usr/bin/
RUN ln -s /lib/systemd/system/java_init.service /workdir/rootfs/etc/systemd/system/multi-user.target.wants/java_init.service

COPY firmware/scripts/cellular/java_cellular.sh /workdir/rootfs/usr/bin/
COPY firmware/scripts/cellular/quectel-CM /workdir/rootfs/usr/bin/
COPY firmware/scripts/cellular/cellular_connection.service /workdir/rootfs/lib/systemd/system/
RUN ln -s /lib/systemd/system/cellular_connection.service /workdir/rootfs/etc/systemd/system/multi-user.target.wants/cellular_connection.service

COPY firmware/scripts/udhcpd /workdir/rootfs/etc/default/
COPY firmware/scripts/udhcpd.conf /workdir/rootfs/etc/

COPY firmware/java-server /workdir/rootfs/usr/bin/
RUN	mkdir -p /workdir/rootfs/opt/webserver/resources
COPY firmware/resources/ /workdir/rootfs/opt/webserver/resources/

COPY firmware/scripts/logrotate/rsyslog /workdir/rootfs/etc/logrotate.d/rsyslog
COPY firmware/scripts/logrotate/logrotate.timer /workdir/rootfs/lib/systemd/system/logrotate.timer
COPY firmware/scripts/logrotate/logrotate /workdir/rootfs/etc/cron.hourly/logrotate
RUN rm /workdir/rootfs/etc/cron.daily/logrotate

COPY firmware/scripts/mqtt/ /workdir/rootfs/opt/mqtt

RUN mkdir -p /workdir/rootfs/opt/webserver/logs/

RUN mkdir -p /workdir/rootfs/opt/ota/
RUN mkdir -p /workdir/rootfs/opt/ota/zip/
RUN	mkdir -p /workdir/rootfs/opt/ota/firmwares/

COPY firmware/scripts/get_and_verify_firmware.sh /workdir/rootfs/opt/ota/
COPY firmware/scripts/ota_update.sh /workdir/rootfs/opt/ota/

# We can modify the contents of the rootfs at this point before its actually written to an image
RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c packrootfs
