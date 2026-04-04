#!/bin/bash

set -e

ARCH=riscv64
SRC_FLAGS="-S -sa -us -uc"
BIN_FLAGS="-a$ARCH -us -uc"

if [ $(basename $PWD) = "scripts" ];then
  cd ..
fi
CURDIR=$(pwd)

# these ones don't depend on the kernel headers
STANDALONE_PACKAGES=(
  aic8800-milkv-firmware
  duo-pinmux
  milkv-usb-duos
  milkv-wireless-duos
)

build () { debuild $SRC_FLAGS && debuild $BIN_FLAGS; }

echo "Building standalone packages"
for pkg in "${STANDALONE_PACKAGES[@]}"; do
  cd $CURDIR/$pkg
  build
done

echo "Building kernel packages"
cd $CURDIR/milkv-linux
build
echo "Installing kernel headers"
apt-get install -y $CURDIR/linux-headers-milkv-duos*.deb
echo "Building wireless driver package"
cd $CURDIR/aic8800-milkv-modules-duos
build
# echo "Building wireless tools package"
# cd $CURDIR/milkv-wireless-duos
# build
