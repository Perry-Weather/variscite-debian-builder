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
RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c kernel
RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c modules
RUN MACHINE=imx6ul-var-dart ./var_make_debian.sh -c kernelheaders
# set G_USER_PACKAGES to install the poco libs and mosquitto
COPY patches . 
RUN --security=insecure MACHINE=imx6ul-var-dart ./var_make_debian.sh -c rootfs
